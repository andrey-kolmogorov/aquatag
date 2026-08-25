//
//  HAWebSocketSession.swift
//  AquaTag
//
//  A single authenticated connection to Home Assistant's WebSocket API,
//  able to issue multiple commands with correctly correlated replies.
//
//  Home Assistant's WS API requires every command to carry a unique,
//  monotonically increasing `id`, and replies arrive as
//  `{"type": "result", "id": <n>, "success": Bool, "result": …}`. The server
//  may interleave unsolicited frames (events, pongs) at any point, so a
//  naive "send one, read one" loop breaks as soon as more than one command
//  is issued on a connection.
//
//  Correlation strategy: **sequential drain.** Commands are never pipelined,
//  so after sending id N we simply read frames until we see the result for N,
//  discarding anything else. The alternative — a background reader task
//  feeding a `[Int: CheckedContinuation]` map — needs an actor and has a
//  nasty failure mode: any continuation left unresumed when the socket drops
//  deadlocks its caller forever. Sequential drain has no continuation-leak
//  class of bug, and it gives per-command error attribution for free, which
//  the cleanup UI's partial-failure reporting needs.
//

import Foundation

/// `nonisolated` because the project builds with
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, which would otherwise pin this
/// to the main actor. A socket that blocks on `receive()` has no business
/// there — and its callers are already `async`, so hopping off is free.
nonisolated final class HAWebSocketSession {

    /// Default ceiling for a single receive. Home Assistant replies to
    /// storage-collection commands almost instantly; anything approaching
    /// this is a stalled connection, not a slow one.
    static let defaultTimeout: TimeInterval = 15

    private let webSocket: URLSessionWebSocketTask
    private let session: URLSession
    private let timeout: TimeInterval

    /// Next message id to hand out. Home Assistant requires these to strictly
    /// increase over the life of a connection.
    private var nextID = 1

    private init(webSocket: URLSessionWebSocketTask, session: URLSession, timeout: TimeInterval) {
        self.webSocket = webSocket
        self.session = session
        self.timeout = timeout
    }

    // MARK: - Connect

    /// Opens a connection and completes the `auth_required` → `auth` → `auth_ok`
    /// handshake. The returned session is ready to accept commands.
    static func connect(
        url: URL,
        token: String,
        timeout: TimeInterval = defaultTimeout
    ) async throws -> HAWebSocketSession {
        // Explicit timeouts — URLSession's 60s default would abort a long
        // delete batch mid-flight, and we want our own timeout to win.
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout * 4

        let session = URLSession(configuration: configuration)
        let webSocket = session.webSocketTask(with: url)
        webSocket.resume()

        let connection = HAWebSocketSession(webSocket: webSocket, session: session, timeout: timeout)

        do {
            try await connection.performHandshake(token: token)
        } catch {
            connection.close()
            throw error
        }

        return connection
    }

    private func performHandshake(token: String) async throws {
        let greeting = try await receive()
        guard greeting["type"] as? String == "auth_required" else {
            throw HAService.HAError.webSocketError(
                "Expected auth_required, got: \(greeting["type"] as? String ?? "unknown")"
            )
        }

        try await send(raw: ["type": "auth", "access_token": token])

        let authResult = try await receive()
        guard authResult["type"] as? String == "auth_ok" else {
            let message = authResult["message"] as? String ?? "Authentication failed"
            throw HAService.HAError.webSocketError(message)
        }
    }

    // MARK: - Commands

    /// Sends a command with a freshly allocated message id and returns the
    /// `result` payload from the matching reply.
    ///
    /// - Parameter payload: the command body **without** an `id` key — this
    ///   method owns id allocation. Passing one is a programmer error.
    /// - Returns: the reply's `result` value, which is a dictionary for
    ///   `…/create`, an array for `…/list`, and `null` for `…/delete`.
    @discardableResult
    func send(_ payload: [String: Any]) async throws -> Any? {
        assert(payload["id"] == nil, "HAWebSocketSession owns message id allocation")

        let id = nextID
        nextID += 1

        var command = payload
        command["id"] = id
        try await send(raw: command)

        return try await awaitResult(id: id)
    }

    /// Convenience for commands whose `result` is a dictionary (e.g. `create`).
    func sendExpectingObject(_ payload: [String: Any]) async throws -> [String: Any] {
        guard let object = try await send(payload) as? [String: Any] else {
            throw HAService.HAError.webSocketError("Expected an object result")
        }
        return object
    }

    /// Convenience for commands whose `result` is an array (e.g. `list`).
    func sendExpectingArray(_ payload: [String: Any]) async throws -> [[String: Any]] {
        guard let array = try await send(payload) as? [[String: Any]] else {
            throw HAService.HAError.webSocketError("Expected an array result")
        }
        return array
    }

    /// Reads frames until the `result` for `id` arrives, discarding anything
    /// else (events, pongs, replies to commands we've already handled).
    private func awaitResult(id: Int) async throws -> Any? {
        while true {
            let frame = try await receive()

            guard frame["type"] as? String == "result",
                  frame["id"] as? Int == id else {
                continue    // not ours — keep draining
            }

            guard frame["success"] as? Bool == true else {
                let error = frame["error"] as? [String: Any]
                let message = error?["message"] as? String ?? "Home Assistant rejected the command"
                throw HAService.HAError.webSocketError(message)
            }

            return frame["result"]
        }
    }

    func close() {
        webSocket.cancel(with: .normalClosure, reason: nil)
        session.invalidateAndCancel()
    }

    // MARK: - Framing

    private func send(raw dict: [String: Any]) async throws {
        let data = try JSONSerialization.data(withJSONObject: dict)
        guard let string = String(data: data, encoding: .utf8) else {
            throw HAService.HAError.webSocketError("Failed to encode JSON")
        }
        try await webSocket.send(.string(string))
    }

    /// Receives one frame, giving up after `timeout`.
    ///
    /// `URLSessionWebSocketTask.receive()` does not reliably honour Swift task
    /// cancellation, so cancelling the losing group child is not enough to
    /// unblock it — the timeout branch has to cancel the *socket*, which is
    /// what actually makes the outstanding `receive()` throw. Without that the
    /// receive continuation leaks and the task group never finishes.
    private func receive() async throws -> [String: Any] {
        try await withThrowingTaskGroup(of: [String: Any].self) { group in
            group.addTask { [webSocket] in
                let message = try await webSocket.receive()
                return try Self.decode(message)
            }

            group.addTask { [webSocket, timeout] in
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                webSocket.cancel(with: .goingAway, reason: nil)
                throw HAService.HAError.timeout
            }

            defer { group.cancelAll() }

            guard let result = try await group.next() else {
                throw HAService.HAError.timeout
            }
            return result
        }
    }

    private static func decode(_ message: URLSessionWebSocketTask.Message) throws -> [String: Any] {
        let data: Data
        switch message {
        case .string(let text):
            guard let encoded = text.data(using: .utf8) else {
                throw HAService.HAError.webSocketError("Invalid UTF-8 received")
            }
            data = encoded
        case .data(let raw):
            data = raw
        @unknown default:
            throw HAService.HAError.webSocketError("Unknown message type")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw HAService.HAError.webSocketError("Invalid JSON received")
        }
        return json
    }
}
