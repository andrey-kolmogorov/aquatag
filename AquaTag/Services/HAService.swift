//
//  HAService.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation

class HAService: NSObject {
    enum HAError: LocalizedError {
        case invalidURL
        case noToken
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case webSocketError(String)
        case timeout

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Home Assistant URL"
            case .noToken:
                return "No authentication token found"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from Home Assistant"
            case .apiError(let message):
                return "Home Assistant API error: \(message)"
            case .webSocketError(let message):
                return "WebSocket error: \(message)"
            case .timeout:
                return "Request timed out"
            }
        }
    }

    private let baseURL: String
    private let token: String

    init(baseURL: String, token: String) {
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.token = token
    }

    // MARK: - WebSocket URL

    private var webSocketURL: URL? {
        // Convert https:// to wss:// (or http:// to ws://)
        var wsURLString = baseURL
        if wsURLString.hasPrefix("https://") {
            wsURLString = "wss://" + wsURLString.dropFirst("https://".count)
        } else if wsURLString.hasPrefix("http://") {
            wsURLString = "ws://" + wsURLString.dropFirst("http://".count)
        }
        return URL(string: "\(wsURLString)/api/websocket")
    }

    // MARK: - Test Connection

    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/api/") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw HAError.apiError(errorMessage)
            }
            throw HAError.apiError("Status code: \(httpResponse.statusCode)")
        }

        return true
    }

    // MARK: - Auto-Create Helper via WebSocket

    func ensureHelperExists(plantID: String, plantName: String) async throws {
        let entityID = "input_datetime.plant_\(plantID)_last_watered"

        // Check if helper already exists via REST (fast check)
        if try await helperExists(entityID: entityID) {
            return
        }

        // Helper doesn't exist — create it via WebSocket
        try await createHelperViaWebSocket(plantID: plantID, plantName: plantName)
    }

    private func helperExists(entityID: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/api/states/\(entityID)") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }

        return httpResponse.statusCode == 200
    }

    private func createHelperViaWebSocket(plantID: String, plantName: String) async throws {
        guard let wsURL = webSocketURL else {
            throw HAError.invalidURL
        }

        let session = URLSession(configuration: .default)
        let webSocket = session.webSocketTask(with: wsURL)
        webSocket.resume()

        defer {
            webSocket.cancel(with: .normalClosure, reason: nil)
        }

        // Step 1: Receive auth_required message
        let authRequired = try await receiveJSON(from: webSocket)
        guard authRequired["type"] as? String == "auth_required" else {
            throw HAError.webSocketError("Expected auth_required, got: \(authRequired)")
        }

        // Step 2: Send auth message
        let authMessage: [String: Any] = [
            "type": "auth",
            "access_token": token
        ]
        try await sendJSON(authMessage, to: webSocket)

        // Step 3: Receive auth_ok or auth_invalid
        let authResult = try await receiveJSON(from: webSocket)
        guard authResult["type"] as? String == "auth_ok" else {
            let message = authResult["message"] as? String ?? "Authentication failed"
            throw HAError.webSocketError(message)
        }

        // Step 4: Send input_datetime/create command
        let createMessage: [String: Any] = [
            "id": 1,
            "type": "input_datetime/create",
            "name": "\(plantName) Last Watered",
            "has_date": true,
            "has_time": true,
            "icon": "mdi:water"
        ]
        try await sendJSON(createMessage, to: webSocket)

        // Step 5: Receive result
        let result = try await receiveJSON(from: webSocket)
        let success = result["success"] as? Bool ?? false

        if !success {
            let error = result["error"] as? [String: Any]
            let message = error?["message"] as? String ?? "Unknown error creating helper"
            throw HAError.webSocketError(message)
        }
    }

    // MARK: - WebSocket Helpers

    private func sendJSON(_ dict: [String: Any], to webSocket: URLSessionWebSocketTask) async throws {
        let data = try JSONSerialization.data(withJSONObject: dict)
        guard let string = String(data: data, encoding: .utf8) else {
            throw HAError.webSocketError("Failed to encode JSON")
        }
        try await webSocket.send(.string(string))
    }

    private func receiveJSON(from webSocket: URLSessionWebSocketTask) async throws -> [String: Any] {
        let message = try await webSocket.receive()
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw HAError.webSocketError("Invalid JSON received")
            }
            return json
        case .data(let data):
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw HAError.webSocketError("Invalid JSON received")
            }
            return json
        @unknown default:
            throw HAError.webSocketError("Unknown message type")
        }
    }

    // MARK: - Log Watering Event

    func logWatering(
        plantID: String,
        plantName: String,
        deviceName: String,
        timestamp: Date = Date()
    ) async throws {
        try await updateLastWateredDateTime(
            plantID: plantID,
            timestamp: timestamp
        )

        try await fireWateringEvent(
            plantID: plantID,
            plantName: plantName,
            deviceName: deviceName,
            timestamp: timestamp
        )
    }

    // MARK: - Update Last Watered DateTime

    private func updateLastWateredDateTime(
        plantID: String,
        timestamp: Date
    ) async throws {
        guard let url = URL(string: "\(baseURL)/api/services/input_datetime/set_datetime") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let entityID = "input_datetime.plant_\(plantID)_last_watered"
        let isoTimestamp = DateFormatters.iso8601NoFractional.string(from: timestamp)

        let body: [String: Any] = [
            "entity_id": entityID,
            "datetime": isoTimestamp
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw HAError.apiError(errorMessage)
            }
            throw HAError.apiError("Status code: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Fire Watering Event

    private func fireWateringEvent(
        plantID: String,
        plantName: String,
        deviceName: String,
        timestamp: Date
    ) async throws {
        guard let url = URL(string: "\(baseURL)/api/events/aquatag_plant_watered") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let isoTimestamp = DateFormatters.iso8601.string(from: timestamp)

        let body: [String: Any] = [
            "plant_id": plantID,
            "plant_name": plantName,
            "device_name": deviceName,
            "timestamp": isoTimestamp
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw HAError.apiError(errorMessage)
            }
            throw HAError.apiError("Status code: \(httpResponse.statusCode)")
        }
    }

    // MARK: - Get Last Watered Date

    func getLastWateredDate(plantID: String) async throws -> Date? {
        let entityID = "input_datetime.plant_\(plantID)_last_watered"
        guard let url = URL(string: "\(baseURL)/api/states/\(entityID)") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            return nil
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let state = json["state"] as? String else {
            return nil
        }

        return DateFormatters.iso8601NoFractional.date(from: state)
    }

    // MARK: - Get Watering History

    struct WateringHistoryEntry: Identifiable {
        let id = UUID()
        let plantName: String
        let deviceName: String
        let timestamp: Date
    }

    func getWateringHistory(limit: Int = 20) async throws -> [WateringHistoryEntry] {
        // TODO: Implement in future version
        return []
    }
}
