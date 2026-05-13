//
//  BlankTagAssignmentSheet.swift
//  AquaTag
//
//  Shown when the user scans a brand-new (blank) NFC sticker from the
//  Plants tab. Lets them pick — or create — a plant to link the sticker
//  to, then triggers a second NFC tap to write the URI record.
//

import SwiftUI
import SwiftData

struct BlankTagAssignmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plant.name) private var plants: [Plant]

    @Bindable var viewModel: PlantListViewModel

    @State private var selectedPlantID: String?
    @State private var showingAddPlant = false
    /// Plant IDs that existed before the user opened AddPlantView, so we can
    /// auto-select whichever plant they just created on return.
    @State private var preExistingIDs: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AquaTag.Spacing.lg) {
                    intro

                    if plants.isEmpty {
                        emptyHint
                    } else {
                        plantPickerSection
                    }

                    addNewRow
                }
                .padding(.horizontal, AquaTag.Spacing.screenEdge)
                .padding(.vertical, AquaTag.Spacing.md)
            }
            .background(AquaTag.Colors.bg.ignoresSafeArea())
            .navigationTitle(L10n.Blank.title)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                writeButton
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.vertical, AquaTag.Spacing.sm)
                    .background(AquaTag.Colors.bg)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Blank.ctaCancel) { dismiss() }
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
            }
            .sheet(isPresented: $showingAddPlant, onDismiss: handleAddPlantDismiss) {
                AddPlantView()
            }
        }
    }

    // MARK: - Sections

    private var intro: some View {
        Text(L10n.Blank.body)
            .font(AquaTag.Typography.body)
            .foregroundStyle(AquaTag.Colors.inkSoft)
    }

    private var emptyHint: some View {
        Text(L10n.Blank.emptyHint)
            .font(AquaTag.Typography.body)
            .foregroundStyle(AquaTag.Colors.inkMute)
            .padding(AquaTag.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                    .fill(AquaTag.Colors.moss.opacity(0.06))
            )
    }

    private var plantPickerSection: some View {
        VStack(spacing: AquaTag.Spacing.xs) {
            ForEach(plants) { plant in
                plantRow(plant)
            }
        }
    }

    private func plantRow(_ plant: Plant) -> some View {
        let isSelected = selectedPlantID == plant.id
        return Button {
            selectedPlantID = plant.id
        } label: {
            HStack(spacing: AquaTag.Spacing.md) {
                CharacterView(character: plant.character, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.name)
                        .font(AquaTag.Typography.displayS)
                        .foregroundStyle(AquaTag.Colors.ink)
                        .lineLimit(1)
                    Text(plant.character.displayName)
                        .font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }

                Spacer(minLength: AquaTag.Spacing.xs)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AquaTag.Colors.moss : AquaTag.Colors.inkMute)
            }
            .padding(AquaTag.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AquaTag.Radius.lg, style: .continuous)
                    .fill(AquaTag.Colors.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AquaTag.Radius.lg, style: .continuous)
                    .strokeBorder(
                        isSelected ? AquaTag.Colors.moss : AquaTag.Colors.divider,
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var addNewRow: some View {
        Button {
            preExistingIDs = Set(plants.map { $0.id })
            showingAddPlant = true
        } label: {
            HStack(spacing: AquaTag.Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AquaTag.Colors.moss)
                Text(L10n.Blank.addNew)
                    .font(AquaTag.Typography.headline)
                    .foregroundStyle(AquaTag.Colors.moss)
                Spacer()
            }
            .padding(AquaTag.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AquaTag.Radius.lg, style: .continuous)
                    .fill(AquaTag.Colors.moss.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    private var writeButton: some View {
        Button {
            guard let plant = selectedPlant else { return }
            Task { await viewModel.writeStickerForPlant(plant) }
        } label: {
            HStack(spacing: 10) {
                if viewModel.isWritingTag {
                    ProgressView()
                        .tint(AquaTag.Colors.cream)
                } else {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(L10n.Blank.ctaWrite)
                    .font(AquaTag.Typography.headline)
            }
            .foregroundStyle(AquaTag.Colors.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule().fill(
                    selectedPlant == nil
                        ? AquaTag.Colors.moss.opacity(0.35)
                        : AquaTag.Colors.moss
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(selectedPlant == nil || viewModel.isWritingTag)
    }

    // MARK: - Helpers

    private var selectedPlant: Plant? {
        guard let id = selectedPlantID else { return nil }
        return plants.first { $0.id == id }
    }

    private func handleAddPlantDismiss() {
        // Auto-select whichever plant the user just created.
        if let newPlant = plants.first(where: { !preExistingIDs.contains($0.id) }) {
            selectedPlantID = newPlant.id
        }
        preExistingIDs = []
    }
}
