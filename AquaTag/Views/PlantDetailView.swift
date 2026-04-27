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
                    Button(isEditing ? L10n.Detail.toolbarCancel : L10n.Detail.toolbarDone) {
                        if isEditing { modelContext.rollback(); isEditing = false }
                        else { dismiss() }
                    }
                    .foregroundStyle(AquaTag.Colors.inkSoft)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? L10n.Detail.toolbarSave : L10n.Detail.toolbarEdit) {
                        if isEditing { try? modelContext.save(); isEditing = false }
                        else { isEditing = true }
                    }
                    .foregroundStyle(AquaTag.Colors.moss)
                    .fontWeight(.semibold)
                }
            }
            .alert(L10n.Detail.writeSuccess, isPresented: $showingWriteSuccess) { Button(L10n.Plants.ok) { } }
            .alert(L10n.Detail.writeFailed, isPresented: $showingWriteError) {
                Button(L10n.Plants.ok) { }
            } message: { Text(writeErrorMessage) }
            .alert(L10n.Detail.deleteTitle, isPresented: $showingDeleteConfirmation) {
                Button(L10n.Plants.cancel, role: .cancel) { }
                Button(L10n.Detail.deleteAction, role: .destructive) { deletePlant() }
            } message: { Text(L10n.Detail.deleteBody(plantName: plant.name)) }
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

                Text(plant.character.archetype)
                    .textCase(.uppercase)
                    .font(AquaTag.Typography.eyebrow)
                    .tracking(2)
                    .foregroundStyle(AquaTag.Colors.inkSoft)

                WateringStatusBadge(plant: plant).padding(.top, 4)
            }
        }
    }

    private var statsStrip: some View {
        HStack(spacing: AquaTag.Spacing.sm) {
            stat(label: L10n.Detail.statEvery, value: "\(plant.wateringIntervalDays)", unit: L10n.Detail.statDays)
            stat(
                label: L10n.Detail.statLast,
                value: plant.lastWateredDate.map { DateFormatters.dayMonth.string(from: $0) } ?? "—",
                unit: nil
            )
            stat(
                label: L10n.Detail.statNext,
                value: plant.nextWateringDate.map { DateFormatters.dayMonth.string(from: $0) } ?? "—",
                unit: nil
            )
        }
    }

    private func stat(label: LocalizedStringKey, value: String, unit: LocalizedStringKey?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(AquaTag.Typography.eyebrow).tracking(1.5)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(AquaTag.Typography.displayS).foregroundStyle(AquaTag.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
        card(title: L10n.Detail.sectionSchedule) {
            if isEditing {
                Stepper(value: $plant.wateringIntervalDays, in: 1...30) {
                    Text(L10n.Settings.defaultIntervalDays(plant.wateringIntervalDays))
                }
                .font(AquaTag.Typography.body)
            }
            if let lastWateredBy = plant.lastWateredBy, plant.lastWateredDate != nil {
                labeledRow(L10n.Detail.loggedBy, lastWateredBy)
            }
            if plant.lastWateredDate == nil {
                Text(L10n.Detail.notWatered)
                    .font(AquaTag.Typography.body)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }
        }
    }

    private var notesSection: some View {
        card(title: L10n.Detail.sectionNotes) {
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
        card(title: L10n.Detail.sectionSticker) {
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
                    Text(L10n.Detail.writeSticker)
                    Spacer()
                    if isWritingTag { ProgressView() }
                }
                .font(AquaTag.Typography.headline)
                .foregroundStyle(AquaTag.Colors.moss)
            }
            .disabled(isWritingTag)

            if let tagID = plant.nfcTagID {
                Divider().background(AquaTag.Colors.divider)
                labeledRow(L10n.Detail.tagID, tagID, mono: true)
            }
        }
    }

    private var haSection: some View {
        card(title: L10n.Detail.sectionHA) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Detail.entityLabel)
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
            Label(L10n.Detail.deletePlant, systemImage: "trash")
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
    private func card<Content: View>(title: LocalizedStringKey,
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

    private func labeledRow(_ label: LocalizedStringKey, _ value: String, mono: Bool = false) -> some View {
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
