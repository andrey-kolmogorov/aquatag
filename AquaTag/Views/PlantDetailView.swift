//
//  PlantDetailView.swift
//  AquaTag — redesigned
//
//  Sheet shown when tapping a plant. Hero character header, stat strip,
//  clean "Form"-style sections but with brand styling.
//

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    @Query private var settings: [AppSettings]

    @State private var isEditing = false
    @State private var isWritingTag = false
    @State private var showingWriteSuccess = false
    @State private var showingWriteError = false
    @State private var writeErrorMessage = ""
    @State private var showingDeleteConfirmation = false

    private let nfcService = NFCService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AquaTag.Spacing.lg) {
                    header
                    statsStrip
                    wateringSection
                    if !plant.notes.isEmpty || isEditing { notesSection }
                    nfcSection
                    haSection
                    deleteSection
                }
                .padding(.horizontal, AquaTag.Spacing.screenEdge)
                .padding(.bottom, AquaTag.Spacing.xl)
            }
            .background(AquaTag.Colors.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing { modelContext.rollback(); isEditing = false }
                        else { dismiss() }
                    }
                    .foregroundStyle(AquaTag.Colors.inkSoft)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing { try? modelContext.save(); isEditing = false }
                        else { isEditing = true }
                    }
                    .foregroundStyle(AquaTag.Colors.moss)
                    .fontWeight(.semibold)
                }
            }
            .alert("Tag Written", isPresented: $showingWriteSuccess) { Button("OK") { } }
            .alert("Write Failed", isPresented: $showingWriteError) {
                Button("OK") { }
            } message: { Text(writeErrorMessage) }
            .alert("Delete Plant?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deletePlant() }
            } message: { Text("This will permanently delete \(plant.name) and cannot be undone.") }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: AquaTag.Spacing.md) {
            CharacterView(character: plant.character, size: .hero)
                .padding(.top, AquaTag.Spacing.md)

            VStack(spacing: 8) {
                Text(plant.name)
                    .font(AquaTag.Typography.displayL)
                    .foregroundStyle(AquaTag.Colors.ink)
                    .multilineTextAlignment(.center)

                Text(plant.character.archetype.uppercased())
                    .font(AquaTag.Typography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AquaTag.Colors.inkSoft)

                WateringStatusBadge(plant: plant).padding(.top, 4)
            }
        }
    }

    private var statsStrip: some View {
        HStack(spacing: AquaTag.Spacing.sm) {
            stat(label: "EVERY", value: "\(plant.wateringIntervalDays)", unit: "days")
            stat(
                label: "LAST",
                value: plant.lastWateredDate.map { DateFormatters.short.string(from: $0) } ?? "—",
                unit: nil
            )
            stat(
                label: "NEXT",
                value: plant.nextWateringDate.map { DateFormatters.short.string(from: $0) } ?? "—",
                unit: nil
            )
        }
    }

    private func stat(label: String, value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(AquaTag.Typography.eyebrow).tracking(1.5)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(AquaTag.Typography.displayS).foregroundStyle(AquaTag.Colors.ink)
                if let unit { Text(unit).font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkSoft) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AquaTag.Spacing.md)
        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .fill(AquaTag.Colors.paper))
        .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
    }

    private var wateringSection: some View {
        card(title: "WATERING") {
            if isEditing {
                Stepper("Water every \(plant.wateringIntervalDays) days",
                        value: $plant.wateringIntervalDays, in: 1...30)
                    .font(AquaTag.Typography.body)
            }
            if let lastWateredBy = plant.lastWateredBy, plant.lastWateredDate != nil {
                labeledRow("Logged by", lastWateredBy)
            }
            if plant.lastWateredDate == nil {
                Text("Not watered yet")
                    .font(AquaTag.Typography.body)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }
        }
    }

    private var notesSection: some View {
        card(title: "NOTES") {
            if isEditing {
                TextEditor(text: $plant.notes)
                    .font(AquaTag.Typography.body)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
            } else {
                Text(plant.notes)
                    .font(AquaTag.Typography.body)
                    .foregroundStyle(AquaTag.Colors.ink)
            }
        }
    }

    private var nfcSection: some View {
        card(title: "NFC STICKER") {
            Button {
                Task {
                    isWritingTag = true
                    do { try await nfcService.writeTag(plantID: plant.id)
                        showingWriteSuccess = true
                    } catch {
                        writeErrorMessage = error.localizedDescription
                        showingWriteError = true
                    }
                    isWritingTag = false
                }
            } label: {
                HStack {
                    Image(systemName: "wave.3.right.circle.fill")
                    Text("Write to sticker")
                    Spacer()
                    if isWritingTag { ProgressView() }
                }
                .font(AquaTag.Typography.headline)
                .foregroundStyle(AquaTag.Colors.moss)
            }
            .disabled(isWritingTag)

            if let tagID = plant.nfcTagID {
                Divider().background(AquaTag.Colors.divider)
                labeledRow("Tag ID", tagID, mono: true)
            }
        }
    }

    private var haSection: some View {
        card(title: "HOME ASSISTANT") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Entity")
                    .font(AquaTag.Typography.micro).tracking(1)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
                Text(plant.haEntityID)
                    .font(AquaTag.Typography.mono)
                    .foregroundStyle(AquaTag.Colors.ink)
                    .textSelection(.enabled)
            }
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label("Delete plant", systemImage: "trash")
                .font(AquaTag.Typography.headline)
                .foregroundStyle(AquaTag.Colors.terracotta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md)
                    .fill(AquaTag.Colors.terracotta.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func card<Content: View>(title: String,
                                     @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.sm) {
            Text(title).font(AquaTag.Typography.eyebrow).tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AquaTag.Spacing.md)
        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .fill(AquaTag.Colors.paper))
        .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
    }

    private func labeledRow(_ label: String, _ value: String, mono: Bool = false) -> some View {
        HStack {
            Text(label).font(AquaTag.Typography.caption)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Spacer()
            Text(value)
                .font(mono ? AquaTag.Typography.mono : AquaTag.Typography.body)
                .foregroundStyle(AquaTag.Colors.ink)
        }
    }

    private func deletePlant() {
        Task { await NotificationService.shared.cancelWateringReminder(for: plant) }
        modelContext.delete(plant)
        try? modelContext.save()
        dismiss()
    }
}
