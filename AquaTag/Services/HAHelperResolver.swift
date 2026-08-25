//
//  HAHelperResolver.swift
//  AquaTag
//
//  Owns the mapping between a local `Plant` and its Home Assistant
//  `input_datetime` helper.
//
//  The rule is: **link, then adopt, then create.** A plant already carrying a
//  `haHelperObjectID` is done. Otherwise we look through the helpers that
//  actually exist in HA and claim a match. Only when nothing matches do we
//  create — and then we record whatever id HA hands back.
//
//  Adoption is not just a migration convenience. It is what stops duplicate
//  creation permanently: the previous code asked "does the id I guessed
//  exist?", got 404 because the guess was unguessable, and created another
//  helper every single time.
//

import Foundation
import SwiftData

@MainActor
struct HAHelperResolver {
    let modelContext: ModelContext
    let service: HAService

    // MARK: - Resolution

    /// The plant's entity id if it is already linked. No network.
    func resolvedEntityID(for plant: Plant) -> String? {
        plant.haEntityID
    }

    /// Guarantees the plant has a helper in Home Assistant, and returns its
    /// entity id.
    ///
    /// Order matters: adopt before create, or we recreate the duplicates we're
    /// trying to eliminate.
    @discardableResult
    func ensureHelper(for plant: Plant) async throws -> String {
        if let existing = plant.haEntityID {
            return existing
        }

        let inventory = try await service.fetchHelperInventory()

        if let adopted = match(plant: plant, in: inventory, claimed: claimedObjectIDs(excluding: plant)) {
            link(objectID: adopted.objectID, to: plant)
            return adopted.entityID
        }

        let objectID = try await service.createHelper(plantName: plant.name)
        link(objectID: objectID, to: plant)
        return "input_datetime.\(objectID)"
    }

    /// Links every unlinked plant that has an unambiguous match in HA.
    /// Never creates anything. Returns how many plants were newly linked.
    ///
    /// This is what repairs an existing install: the user pulls to refresh and
    /// their plants silently reattach to the helpers they already had.
    @discardableResult
    func adoptExistingHelpers(inventory: [HAHelper]? = nil) async throws -> Int {
        let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
        let unlinked = plants.filter { $0.haHelperObjectID == nil }
        guard !unlinked.isEmpty else { return 0 }

        // Not `inventory ?? service.fetch…` — `??` takes an autoclosure, which
        // can't carry an async call.
        let helpers: [HAHelper]
        if let inventory {
            helpers = inventory
        } else {
            helpers = try await service.fetchHelperInventory()
        }
        var claimed = Set(plants.compactMap(\.haHelperObjectID))
        var adopted = 0

        for plant in unlinked {
            guard let helper = match(plant: plant, in: helpers, claimed: claimed) else { continue }
            link(objectID: helper.objectID, to: plant)
            claimed.insert(helper.objectID)
            adopted += 1
        }

        return adopted
    }

    /// Manually attach a helper to a plant — used by the cleanup UI for cases
    /// the automatic rules deliberately refuse to guess at.
    func link(objectID: String, to plant: Plant) {
        plant.haHelperObjectID = objectID
        try? modelContext.save()
    }

    func unlink(_ plant: Plant) {
        plant.haHelperObjectID = nil
        try? modelContext.save()
    }

    // MARK: - Matching

    /// Finds the helper belonging to `plant`, ignoring any already spoken for.
    ///
    /// Rules are ordered most- to least-certain. The first three compare
    /// object_ids exactly and auto-adopt. The fourth compares display names,
    /// and adopts **only when exactly one helper matches** — with four helpers
    /// all called "Cactus Last Watered", picking one arbitrarily would bind the
    /// plant to somebody else's watering history forever. Ambiguity is left for
    /// the user to resolve in the cleanup UI.
    private func match(plant: Plant, in helpers: [HAHelper], claimed: Set<String>) -> HAHelper? {
        let available = helpers.filter { !claimed.contains($0.objectID) }
        guard !available.isEmpty else { return nil }

        let expectedName = Self.helperName(for: plant.name)

        let exactCandidates = [
            "plant_\(plant.id)_last_watered",    // the form this app intended but never produced
            Self.slugify(expectedName),          // the form HA actually produces
            "\(plant.id)_last_watered"           // a plant renamed after its helper was made
        ]

        for candidate in exactCandidates {
            if let hit = available.first(where: { $0.objectID == candidate }) {
                return hit
            }
        }

        // Name-based fallback catches `_2`/`_3` drift, where the object_id
        // diverged but HA kept the display name.
        let nameMatches = available.filter {
            $0.name.compare(expectedName, options: .caseInsensitive) == .orderedSame
        }
        return nameMatches.count == 1 ? nameMatches[0] : nil
    }

    private func claimedObjectIDs(excluding plant: Plant) -> Set<String> {
        let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
        return Set(plants.filter { $0.id != plant.id }.compactMap(\.haHelperObjectID))
    }

    // MARK: - Naming

    /// The helper name this app gives Home Assistant when creating.
    /// Kept in one place so the create path and the match path can't drift.
    static func helperName(for plantName: String) -> String {
        "\(plantName) Last Watered"
    }

    /// Approximates Home Assistant's `slugify`.
    ///
    /// HA transliterates non-ASCII before slugging, so "Grünlilie" becomes
    /// `grunlilie`. A plain `[^a-z0-9]` substitution would yield `gr_nlilie`
    /// and silently fail to match — which matters here, since the app ships in
    /// German. Folding diacritics first closes that gap; the name-based rule
    /// above is the backstop for whatever it still misses.
    static func slugify(_ input: String) -> String {
        let folded = input.folding(
            options: [.diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        let slug = folded
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        return slug
    }

    /// What HA will *probably* name the helper for this plant, for preview UI.
    /// Only a prediction — HA appends a suffix on collision, which is why the
    /// real id is always read back from the create response.
    static func predictedObjectID(for plantName: String) -> String {
        slugify(helperName(for: plantName))
    }
}
