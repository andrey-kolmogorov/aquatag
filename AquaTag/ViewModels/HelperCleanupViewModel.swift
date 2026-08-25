//
//  HelperCleanupViewModel.swift
//  AquaTag
//
//  Backs the Settings section that reconciles Home Assistant's
//  `input_datetime` helpers against the local plant list.
//
//  Scanning also runs helper adoption, so a scan can *reduce* the number of
//  orphans by linking plants to helpers they should have been attached to all
//  along — rather than only offering to delete things.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class HelperCleanupViewModel {

    enum Phase {
        case idle
        case scanning
        case ready
        case deleting
    }

    enum DeleteResult {
        case success(deleted: Int)
        case partial(deleted: Int, failed: Int)
    }

    struct Row: Identifiable {
        enum Classification {
            /// A plant already points at this helper.
            case linked(plantName: String)
            /// Matches a plant that isn't linked — offer to attach it.
            case adoptable(plantName: String)
            /// No local plant claims this helper.
            case orphaned
        }

        let helper: HAHelper
        var classification: Classification
        var isSelected: Bool = false
        var deleteError: String?

        var id: String { helper.objectID }

        /// Linked helpers are deliberately not selectable: deleting one would
        /// silently break sync for a working plant. Removing the plant is the
        /// supported way to get rid of its helper. YAML-defined helpers aren't
        /// selectable either, since the storage API can't delete them.
        var isSelectable: Bool {
            guard helper.isDeletable else { return false }
            if case .linked = classification { return false }
            return true
        }
    }

    private let modelContext: ModelContext

    private(set) var phase: Phase = .idle
    private(set) var rows: [Row] = []
    private(set) var scanError: String?
    private(set) var deleteResult: DeleteResult?
    private(set) var adoptedCount: Int = 0
    var showingDeleteConfirmation = false

    var selectedCount: Int { rows.filter(\.isSelected).count }
    var hasSelectableRows: Bool { rows.contains(where: \.isSelectable) }
    var hasScanned: Bool { phase == .ready || phase == .deleting }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Scan

    func scan() async {
        guard let service = HAService.configured(from: modelContext) else {
            scanError = String(localized: "settings.cleanup.not.configured")
            phase = .idle
            return
        }

        phase = .scanning
        scanError = nil
        deleteResult = nil
        adoptedCount = 0

        do {
            let inventory = try await service.fetchHelperInventory()

            // Link before classifying, so anything adoptable becomes linked and
            // drops out of the delete candidates.
            let resolver = HAHelperResolver(modelContext: modelContext, service: service)
            adoptedCount = try await resolver.adoptExistingHelpers(inventory: inventory)

            rows = classify(inventory)
            phase = .ready
        } catch {
            scanError = error.localizedDescription
            phase = .idle
        }
    }

    private func classify(_ inventory: [HAHelper]) -> [Row] {
        let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
        let plantsByObjectID = Dictionary(
            plants.compactMap { plant in plant.haHelperObjectID.map { ($0, plant) } },
            uniquingKeysWith: { first, _ in first }
        )
        let unlinked = plants.filter { $0.haHelperObjectID == nil }

        return inventory.map { helper in
            if let owner = plantsByObjectID[helper.objectID] {
                return Row(helper: helper, classification: .linked(plantName: owner.name))
            }

            // Surface a suggestion for anything that looks like it belongs to an
            // unlinked plant. Adoption already claimed the unambiguous cases, so
            // what reaches here needs a human to choose.
            let expectedNames = unlinked.map {
                (plant: $0, name: HAHelperResolver.helperName(for: $0.name))
            }
            if let candidate = expectedNames.first(where: {
                $0.name.compare(helper.name, options: .caseInsensitive) == .orderedSame
                    || HAHelperResolver.slugify($0.name) == helper.objectID
            }) {
                return Row(helper: helper, classification: .adoptable(plantName: candidate.plant.name))
            }

            return Row(helper: helper, classification: .orphaned)
        }
    }

    // MARK: - Selection

    func toggle(_ id: String) {
        guard let index = rows.firstIndex(where: { $0.id == id }), rows[index].isSelectable else { return }
        rows[index].isSelected.toggle()
        rows[index].deleteError = nil
    }

    func selectAllOrphaned() {
        for index in rows.indices where rows[index].isSelectable {
            if case .orphaned = rows[index].classification {
                rows[index].isSelected = true
            }
        }
    }

    func clearSelection() {
        for index in rows.indices {
            rows[index].isSelected = false
        }
    }

    // MARK: - Manual linking

    func link(row: Row, to plant: Plant) {
        guard let service = HAService.configured(from: modelContext) else { return }
        let resolver = HAHelperResolver(modelContext: modelContext, service: service)
        resolver.link(objectID: row.helper.objectID, to: plant)

        if let index = rows.firstIndex(where: { $0.id == row.id }) {
            rows[index].classification = .linked(plantName: plant.name)
            rows[index].isSelected = false
        }
    }

    /// Unlinked plants a given row could be attached to, for the manual picker.
    func linkCandidates() -> [Plant] {
        let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
        return plants.filter { $0.haHelperObjectID == nil }.sorted { $0.name < $1.name }
    }

    // MARK: - Delete

    func deleteSelected() async {
        let targets = rows.filter(\.isSelected).map(\.helper.objectID)
        guard !targets.isEmpty,
              let service = HAService.configured(from: modelContext) else { return }

        phase = .deleting
        deleteResult = nil

        do {
            let outcomes = try await service.deleteHelpers(objectIDs: targets)
            let failuresByID = Dictionary(
                outcomes.compactMap { outcome in outcome.error.map { (outcome.objectID, $0) } },
                uniquingKeysWith: { first, _ in first }
            )
            let deletedIDs = Set(outcomes.filter(\.succeeded).map(\.objectID))

            clearLinks(to: deletedIDs)

            // Successful rows disappear; failed rows stay put, still selected,
            // with their reason attached — so the delete button remains live and
            // retrying is just tapping it again.
            rows.removeAll { deletedIDs.contains($0.id) }
            for index in rows.indices {
                rows[index].deleteError = failuresByID[rows[index].id]?.localizedDescription
            }

            deleteResult = failuresByID.isEmpty
                ? .success(deleted: deletedIDs.count)
                : .partial(deleted: deletedIDs.count, failed: failuresByID.count)
        } catch {
            // Connection-level failure — nothing was deleted.
            for index in rows.indices where rows[index].isSelected {
                rows[index].deleteError = error.localizedDescription
            }
            deleteResult = .partial(deleted: 0, failed: targets.count)
        }

        phase = .ready
    }

    /// Defensive: if a helper a plant pointed at is gone, drop the dangling
    /// reference so the next sync re-adopts or recreates cleanly.
    private func clearLinks(to deletedObjectIDs: Set<String>) {
        guard !deletedObjectIDs.isEmpty else { return }
        let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
        var changed = false
        for plant in plants {
            if let objectID = plant.haHelperObjectID, deletedObjectIDs.contains(objectID) {
                plant.haHelperObjectID = nil
                changed = true
            }
        }
        if changed { try? modelContext.save() }
    }
}
