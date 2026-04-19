//
//  SettingsView.swift
//  AquaTag — redesigned
//
//  Same bindings as the original; new card-based layout.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plants: [Plant]
    @State private var viewModel: SettingsViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AquaTag.Spacing.lg) {
                    heroHeader
                    haCard
                    deviceCard
                    notificationsCard
                    plantHelpersCard
                    footer
                }
                .padding(.horizontal, AquaTag.Spacing.screenEdge)
                .padding(.vertical, AquaTag.Spacing.md)
            }
            .background(AquaTag.Colors.bg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                }
            }
            .onDisappear { viewModel?.saveSettings() }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SETTINGS")
                .font(AquaTag.Typography.eyebrow)
                .tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Text("Preferences")
                .font(AquaTag.Typography.displayL)
                .foregroundStyle(AquaTag.Colors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AquaTag.Spacing.xs)
    }

    // MARK: - Cards

    private var haCard: some View {
        card(title: "HOME ASSISTANT", subtitle: "Optional. Sync watering across devices.") {
            VStack(spacing: AquaTag.Spacing.sm) {
                field(label: "Nabu Casa URL",
                      value: Binding(get: { viewModel?.nabucasaURL ?? "" },
                                     set: { viewModel?.nabucasaURL = $0 }),
                      keyboard: .URL)
                field(label: "Long-lived token",
                      value: Binding(get: { viewModel?.haToken ?? "" },
                                     set: { viewModel?.haToken = $0 }),
                      secure: true)

                Button {
                    Task { await viewModel?.testConnection() }
                } label: {
                    HStack {
                        if viewModel?.isTesting == true { ProgressView() }
                        else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("Test connection")
                        }
                    }
                    .font(AquaTag.Typography.headline)
                    .foregroundStyle(AquaTag.Colors.moss)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md)
                        .strokeBorder(AquaTag.Colors.moss, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .disabled(viewModel?.isTesting == true)

                if let result = viewModel?.testResult {
                    switch result {
                    case .success:
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(AquaTag.Typography.subhead)
                            .foregroundStyle(AquaTag.Colors.moss)
                    case .failure(let msg):
                        VStack(alignment: .leading) {
                            Label("Connection failed", systemImage: "xmark.circle.fill")
                                .font(AquaTag.Typography.subhead)
                                .foregroundStyle(AquaTag.Colors.terracotta)
                            Text(msg).font(AquaTag.Typography.caption)
                                .foregroundStyle(AquaTag.Colors.inkSoft)
                        }
                    }
                }
            }
        }
    }

    private var deviceCard: some View {
        card(title: "DEVICE", subtitle: "Who's watering, for multi-person homes.") {
            field(label: "Device name",
                  value: Binding(get: { viewModel?.deviceName ?? "" },
                                 set: { viewModel?.deviceName = $0 }))
        }
    }

    private var notificationsCard: some View {
        card(title: "REMINDERS") {
            VStack(spacing: AquaTag.Spacing.sm) {
                Toggle(isOn: Binding(get: { viewModel?.notificationsEnabled ?? true },
                                     set: { v in
                                         viewModel?.notificationsEnabled = v
                                         if v { Task { await viewModel?.requestNotificationPermission() } }
                                     })) {
                    Text("Watering reminders").font(AquaTag.Typography.body)
                }
                .tint(AquaTag.Colors.moss)

                if viewModel?.notificationsEnabled == true {
                    DatePicker("Reminder time",
                        selection: Binding(get: { viewModel?.notificationTime ?? Date() },
                                           set: { viewModel?.notificationTime = $0 }),
                        displayedComponents: .hourAndMinute)
                        .font(AquaTag.Typography.body)
                }

                Stepper(value: Binding(get: { viewModel?.defaultWateringIntervalDays ?? 7 },
                                       set: { viewModel?.defaultWateringIntervalDays = $0 }),
                        in: 1...30) {
                    HStack {
                        Text("Default interval").font(AquaTag.Typography.body)
                        Spacer()
                        Text("\(viewModel?.defaultWateringIntervalDays ?? 7) days")
                            .font(AquaTag.Typography.subhead)
                            .foregroundStyle(AquaTag.Colors.inkSoft)
                    }
                }
            }
        }
    }

    private var plantHelpersCard: some View {
        card(title: "PLANT HELPERS", subtitle: "Auto-created in Home Assistant.") {
            if plants.isEmpty {
                Text("Add your first plant to see its HA entity.")
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            } else {
                VStack(alignment: .leading, spacing: AquaTag.Spacing.sm) {
                    ForEach(plants) { plant in
                        HStack(spacing: 10) {
                            CharacterView(character: plant.character, size: .small)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plant.name).font(AquaTag.Typography.subhead)
                                    .foregroundStyle(AquaTag.Colors.ink)
                                Text(plant.haEntityID).font(AquaTag.Typography.monoSmall)
                                    .foregroundStyle(AquaTag.Colors.moss)
                                    .textSelection(.enabled)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Aquatag · v1.0")
                .font(AquaTag.Typography.caption)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Text("Made for plants.")
                .font(AquaTag.Typography.caption.italic())
                .foregroundStyle(AquaTag.Colors.inkMute)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AquaTag.Spacing.xl)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func card<Content: View>(title: String, subtitle: String? = nil,
                                     @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AquaTag.Typography.eyebrow).tracking(2)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
                if let subtitle {
                    Text(subtitle).font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AquaTag.Spacing.md)
        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .fill(AquaTag.Colors.paper))
        .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
    }

    private func field(label: String, value: Binding<String>,
                       keyboard: UIKeyboardType = .default,
                       secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).font(AquaTag.Typography.micro).tracking(1)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Group {
                if secure && !value.wrappedValue.isEmpty {
                    SecureField("", text: value)
                } else {
                    TextField("", text: value)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(AquaTag.Typography.body)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: AquaTag.Radius.sm)
                .fill(AquaTag.Colors.bg))
            .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.sm)
                .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
        }
    }
}
