//
//  HAService.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData

/// One `input_datetime` helper as it exists in Home Assistant.
///
/// `objectID` is the bare storage id (`hortensia_last_watered`) — not the
/// entity id. Deletion takes the object_id, and the entity id is one prefix
/// away, so the bare form is the more useful thing to carry around.
struct HAHelper: Identifiable, Hashable, Sendable {
    let objectID: String
    let name: String
    let lastWatered: Date?
    /// `false` for YAML-defined helpers, which can't be removed through the
    /// storage-collection API.
    let isDeletable: Bool

    var entityID: String { "input_datetime.\(objectID)" }
    var id: String { objectID }
}

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

    // MARK: - WebSocket Scope

    /// Runs `body` against a freshly connected, authenticated session and
    /// tears it down afterwards.
    ///
    /// Sessions are deliberately never held open across UI interaction —
    /// Nabu Casa's relay drops idle connections, and a stale socket surfaces
    /// as a confusing mid-action failure rather than a clean retry.
    private func withWebSocket<T>(
        _ body: (HAWebSocketSession) async throws -> T
    ) async throws -> T {
        guard let wsURL = webSocketURL else {
            throw HAError.invalidURL
        }

        let session = try await HAWebSocketSession.connect(url: wsURL, token: token)
        defer { session.close() }

        return try await body(session)
    }

    // MARK: - Helper Lifecycle

    /// Creates an `input_datetime` helper and returns the object_id Home
    /// Assistant assigned to it.
    ///
    /// The object_id is **read from the create result, never derived.** HA
    /// generates it by slugifying the name and appends `_2`, `_3`, … on
    /// collision, so any client-side guess is wrong the moment two plants
    /// share a name — which is exactly the bug this replaces.
    func createHelper(plantName: String) async throws -> String {
        let name = "\(plantName) Last Watered"

        return try await withWebSocket { session in
            let result = try await session.sendExpectingObject([
                "type": "input_datetime/create",
                "name": name,
                "has_date": true,
                "has_time": true,
                "icon": "mdi:water"
            ])

            if let objectID = result["id"] as? String, !objectID.isEmpty {
                return objectID
            }

            // Self-heal: HA changed its response shape. Rather than guessing
            // an id (how the original bug was born), ask which helper we just
            // made. Deliberately no fallback beyond this.
            let helpers = try await Self.parseHelperList(
                session.sendExpectingArray(["type": "input_datetime/list"])
            )
            guard let created = helpers.last(where: { $0.name == name }) else {
                throw HAError.webSocketError(
                    "Helper created but Home Assistant did not return its id (result: \(result))"
                )
            }
            return created.objectID
        }
    }

    /// The authoritative set of helpers that can be deleted through the
    /// storage-collection API. Carries no state, so no last-watered dates.
    func listHelpers() async throws -> [HAHelper] {
        try await withWebSocket { session in
            try Self.parseHelperList(
                await session.sendExpectingArray(["type": "input_datetime/list"])
            )
        }
    }

    func deleteHelper(objectID: String) async throws {
        try await withWebSocket { session in
            try await session.send([
                "type": "input_datetime/delete",
                "input_datetime_id": objectID
            ])
        }
    }

    struct DeleteOutcome: Sendable {
        let objectID: String
        let error: Error?
        var succeeded: Bool { error == nil }
    }

    /// Deletes each helper over a single connection, sequentially.
    ///
    /// Throws only when the connection itself can't be established; per-item
    /// failures are reported in the returned array so a partial batch stays
    /// legible to the caller.
    func deleteHelpers(objectIDs: [String]) async throws -> [DeleteOutcome] {
        try await withWebSocket { session in
            var outcomes: [DeleteOutcome] = []
            for objectID in objectIDs {
                do {
                    try await session.send([
                        "type": "input_datetime/delete",
                        "input_datetime_id": objectID
                    ])
                    outcomes.append(DeleteOutcome(objectID: objectID, error: nil))
                } catch {
                    outcomes.append(DeleteOutcome(objectID: objectID, error: error))
                }
            }
            return outcomes
        }
    }

    private static func parseHelperList(_ raw: [[String: Any]]) -> [HAHelper] {
        raw.compactMap { entry in
            guard let objectID = entry["id"] as? String else { return nil }
            return HAHelper(
                objectID: objectID,
                name: entry["name"] as? String ?? objectID,
                lastWatered: nil,       // filled in by fetchHelperInventory
                isDeletable: true       // present in /list ⇒ storage-backed
            )
        }
    }

    // MARK: - Helper Inventory

    /// Every `input_datetime` entity with its current value.
    ///
    /// Includes YAML-defined helpers, which `input_datetime/list` omits —
    /// that difference is what lets `fetchHelperInventory` mark them as
    /// non-deletable instead of failing confusingly at delete time.
    func fetchInputDateTimeStates() async throws -> [String: (name: String?, date: Date?)] {
        guard let url = URL(string: "\(baseURL)/api/states") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HAError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw HAError.apiError("Status code: \(httpResponse.statusCode)")
        }
        guard let entities = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw HAError.invalidResponse
        }

        let prefix = "input_datetime."
        var result: [String: (name: String?, date: Date?)] = [:]

        for entity in entities {
            guard let entityID = entity["entity_id"] as? String,
                  entityID.hasPrefix(prefix) else { continue }

            let objectID = String(entityID.dropFirst(prefix.count))
            let attributes = entity["attributes"] as? [String: Any]
            let friendlyName = attributes?["friendly_name"] as? String

            result[objectID] = (name: friendlyName, date: Self.parseHelperDate(entity["state"]))
        }

        return result
    }

    /// A freshly created `input_datetime` reports the Unix epoch rather than a
    /// null state. Treating that as a real date would show every untouched
    /// helper as "last watered 1 Jan 1970" and destroy the only signal that
    /// distinguishes same-named helpers from each other.
    private static func parseHelperDate(_ rawState: Any?) -> Date? {
        guard let state = rawState as? String,
              state != "unknown",
              state != "unavailable",
              let date = DateFormatters.iso8601NoFractional.date(from: state),
              date.timeIntervalSince1970 > 0 else {
            return nil
        }
        return date
    }

    /// The deletable set (WebSocket) merged with current values (REST).
    ///
    /// Two round-trips rather than one, because neither source alone is
    /// sufficient: `/list` knows what can be deleted but not what's in it, and
    /// `/api/states` knows the values but also lists YAML helpers that the
    /// storage-collection delete would reject. The REST call returns every
    /// entity in the instance, which is acceptable for a manual,
    /// spinner-backed action — revisit only if it proves slow in practice.
    func fetchHelperInventory() async throws -> [HAHelper] {
        async let deletableTask = listHelpers()
        async let statesTask = fetchInputDateTimeStates()

        let (deletable, states) = try await (deletableTask, statesTask)
        let deletableIDs = Set(deletable.map(\.objectID))

        var inventory = deletable.map { helper in
            HAHelper(
                objectID: helper.objectID,
                name: states[helper.objectID]?.name ?? helper.name,
                lastWatered: states[helper.objectID]?.date,
                isDeletable: true
            )
        }

        // YAML-defined helpers exist as entities but aren't in the storage
        // collection. Surface them as locked rather than hiding them.
        for (objectID, info) in states where !deletableIDs.contains(objectID) {
            inventory.append(HAHelper(
                objectID: objectID,
                name: info.name ?? objectID,
                lastWatered: info.date,
                isDeletable: false
            ))
        }

        return inventory.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Log Watering Event

    /// Writes the timestamp to `entityID` and fires the `aquatag_plant_watered`
    /// event.
    ///
    /// `entityID` is resolved by the caller (see `HAHelperResolver`) rather
    /// than derived here — deriving it in two places with two different rules
    /// is what broke sync in the first place.
    func logWatering(
        entityID: String,
        plantID: String,
        plantName: String,
        deviceName: String,
        timestamp: Date = Date()
    ) async throws {
        try await setLastWatered(entityID: entityID, timestamp: timestamp)

        try await fireWateringEvent(
            plantID: plantID,
            plantName: plantName,
            deviceName: deviceName,
            timestamp: timestamp
        )
    }

    // MARK: - Update Last Watered DateTime

    func setLastWatered(entityID: String, timestamp: Date) async throws {
        guard let url = URL(string: "\(baseURL)/api/services/input_datetime/set_datetime") else {
            throw HAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

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

    func lastWateredDate(entityID: String) async throws -> Date? {
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

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return Self.parseHelperDate(json["state"])
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

    // MARK: - Credentials

    /// Builds a service from stored settings, or `nil` when Home Assistant
    /// isn't configured. Replaces the credential-fetch preamble that was
    /// copy-pasted across six call sites.
    @MainActor
    static func configured(from modelContext: ModelContext) -> HAService? {
        guard let settings = try? modelContext.fetch(FetchDescriptor<AppSettings>()).first,
              settings.isHAConfigured,
              let token = try? KeychainService.getHAToken(),
              !token.isEmpty else {
            return nil
        }
        return HAService(baseURL: settings.nabucasaURL, token: token)
    }
}
