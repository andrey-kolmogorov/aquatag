//
//  AddPlantView.swift
//  AquaTag — redesigned
//
//  Adds a character picker at the top instead of an emoji grid.
//  Same SwiftData writes as the original.
//

import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]

    var suggestedID: String?

    @State private var name = ""
    @State private var character: Character = .monty
    @State private var wateringIntervalDays = 7
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AquaTag.Spacing.lg) {
                    characterPicker
                    nameField
                    intervalField
                    notesField
                    haHelperNote
                }
                .padding(.horizontal, AquaTag.Spacing.screenEdge)
                .padding(.vertical, AquaTag.Spacing.md)
            }
            .background(AquaTag.Colors.bg.ignoresSafeArea())
            .navigationTitle("Add plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlant() }
                        .foregroundStyle(name.isEmpty ? AquaTag.Colors.inkMute : AquaTag.Colors.moss)
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let def = settings.first?.defaultWateringIntervalDays {
                    wateringIntervalDays = def
                }
                if let s = suggestedID {
                    name = s.replacingOccurrences(of: "_", with: " ").capitalized
                }
            }
            .onChange(of: character) { _, new in
                wateringIntervalDays = new.suggestedIntervalDays
            }
        }
    }

    // MARK: - Sections

    private var characterPicker: some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.sm) {
            Text("CHARACTER")
                .font(AquaTag.Typography.eyebrow).tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AquaTag.Spacing.sm) {
                    ForEach(Character.allCases) { c in
                        Button { withAnimation(AquaTag.Motion.quick) { character = c } } label: {
                            VStack(spacing: 8) {
                                CharacterView(character: c, size: .medium)
                                    .scaleEffect(character == c ? 1.05 : 1.0)
                                Text(c.displayName)
                                    .font(AquaTag.Typography.subhead)
                                    .foregroundStyle(character == c ? AquaTag.Colors.ink : AquaTag.Colors.inkSoft)
                            }
                            .padding(AquaTag.Spacing.sm)
                            .frame(width: 92)
                            .background(
                                RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                                    .fill(character == c ? AquaTag.Colors.paper : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                                    .strokeBorder(
                                        character == c ? c.color : AquaTag.Colors.divider,
                                        lineWidth: character == c ? 2 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, -2)

            Text(character.tagline)
                .font(AquaTag.Typography.caption)
                .foregroundStyle(AquaTag.Colors.inkSoft)
                .padding(.top, 2)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.xs) {
            Text("NAME").font(AquaTag.Typography.eyebrow).tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            TextField("e.g. Monstera by the window", text: $name)
                .font(AquaTag.Typography.body)
                .padding(AquaTag.Spacing.md)
                .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                    .fill(AquaTag.Colors.paper))
                .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                    .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
        }
    }

    private var intervalField: some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.xs) {
            Text("WATER EVERY").font(AquaTag.Typography.eyebrow).tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Stepper(value: $wateringIntervalDays, in: 1...30) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(wateringIntervalDays)")
                        .font(AquaTag.Typography.displayS)
                        .foregroundStyle(AquaTag.Colors.ink)
                    Text("days")
                        .font(AquaTag.Typography.body)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
            }
            .padding(.horizontal, AquaTag.Spacing.md)
            .padding(.vertical, AquaTag.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                .fill(AquaTag.Colors.paper))
            .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.xs) {
            Text("NOTES").font(AquaTag.Typography.eyebrow).tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            TextEditor(text: $notes)
                .font(AquaTag.Typography.body)
                .frame(height: 100)
                .scrollContentBackground(.hidden)
                .padding(AquaTag.Spacing.sm)
                .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                    .fill(AquaTag.Colors.paper))
                .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
                    .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
        }
    }

    private var haHelperNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AquaTag.Colors.moss)
                Text("HOME ASSISTANT ENTITY").font(AquaTag.Typography.eyebrow).tracking(2)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }
            Text(generatedEntityID)
                .font(AquaTag.Typography.mono)
                .foregroundStyle(AquaTag.Colors.moss)
                .textSelection(.enabled)
            Text("Auto-created on save if your HA connection is configured.")
                .font(AquaTag.Typography.caption)
                .foregroundStyle(AquaTag.Colors.inkMute)
        }
        .padding(AquaTag.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .fill(AquaTag.Colors.moss.opacity(0.06)))
    }

    private var generatedEntityID: String {
        let plantID = suggestedID ?? PlantIDGenerator.generateID(from: name)
        return "input_datetime.plant_\(plantID)_last_watered"
    }

    private func savePlant() {
        let plantID = suggestedID ?? PlantIDGenerator.generateID(from: name)
        let plant = Plant(
            id: plantID,
            name: name,
            emoji: "🌿",                  // legacy field, kept for compat
            wateringIntervalDays: wateringIntervalDays,
            notes: notes
        )
        plant.characterID = character.rawValue
        modelContext.insert(plant)
        try? modelContext.save()

        if let settings = settings.first, settings.isConfigured,
           let token = try? KeychainService.getHAToken() {
            let ha = HAService(baseURL: settings.nabucasaURL, token: token)
            Task { try? await ha.ensureHelperExists(plantID: plant.id, plantName: plant.name) }
        }

        dismiss()
    }
}
