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
            Text(L10n.Settings.eyebrow)
                .font(AquaTag.Typography.eyebrow)
                .tracking(2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Text(L10n.Settings.title)
                .font(AquaTag.Typography.displayL)
                .foregroundStyle(AquaTag.Colors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, AquaTag.Spacing.xs)
    }

    // MARK: - Cards

    private var haCard: some View {
        card(title: L10n.Settings.sectionHA, subtitle: L10n.Settings.sectionHASub) {
            VStack(spacing: AquaTag.Spacing.sm) {
                field(label: L10n.Settings.fieldURL,
                      value: Binding(get: { viewModel?.nabucasaURL ?? "" },
                                     set: { viewModel?.nabucasaURL = $0 }),
                      keyboard: .URL)
                field(label: L10n.Settings.fieldToken,
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
                            Text(L10n.Settings.testConnection)
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
                        Label(L10n.Settings.connected, systemImage: "checkmark.circle.fill")
                            .font(AquaTag.Typography.subhead)
                            .foregroundStyle(AquaTag.Colors.moss)
                    case .failure(let msg):
                        VStack(alignment: .leading) {
                            Label(L10n.Settings.connectionFail, systemImage: "xmark.circle.fill")
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
        card(title: L10n.Settings.sectionDevice, subtitle: L10n.Settings.sectionDeviceSub) {
            field(label: L10n.Settings.fieldDeviceName,
                  value: Binding(get: { viewModel?.deviceName ?? "" },
                                 set: { viewModel?.deviceName = $0 }))
        }
    }

    private var notificationsCard: some View {
        card(title: L10n.Settings.sectionRemind) {
            VStack(spacing: AquaTag.Spacing.sm) {
                Toggle(isOn: Binding(get: { viewModel?.notificationsEnabled ?? true },
                                     set: { v in
                                         viewModel?.notificationsEnabled = v
                                         if v { Task { await viewModel?.requestNotificationPermission() } }
                                     })) {
                    Text(L10n.Settings.remindersToggle).font(AquaTag.Typography.body)
                }
                .tint(AquaTag.Colors.moss)

                if viewModel?.notificationsEnabled == true {
                    DatePicker(selection: Binding(get: { viewModel?.notificationTime ?? Date() },
                                                  set: { viewModel?.notificationTime = $0 }),
                        displayedComponents: .hourAndMinute) {
                        Text(L10n.Settings.remindersTime)
                    }
                    .font(AquaTag.Typography.body)
                }

                Stepper(value: Binding(get: { viewModel?.defaultWateringIntervalDays ?? 7 },
                                       set: { viewModel?.defaultWateringIntervalDays = $0 }),
                        in: 1...30) {
                    HStack {
                        Text(L10n.Settings.defaultInterval).font(AquaTag.Typography.body)
                        Spacer()
                        Text(L10n.Settings.defaultIntervalDays(viewModel?.defaultWateringIntervalDays ?? 7))
                            .font(AquaTag.Typography.subhead)
                            .foregroundStyle(AquaTag.Colors.inkSoft)
                    }
                }
            }
        }
    }

    private var plantHelpersCard: some View {
        card(title: L10n.Settings.sectionHelpers, subtitle: L10n.Settings.helpersSub) {
            if plants.isEmpty {
                Text(L10n.Settings.helpersEmpty)
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
            Text(L10n.Settings.footerVersion)
                .font(AquaTag.Typography.caption)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Text(L10n.Settings.footerTagline)
                .font(AquaTag.Typography.caption.italic())
                .foregroundStyle(AquaTag.Colors.inkMute)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AquaTag.Spacing.xl)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func card<Content: View>(title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil,
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

    private func field(label: LocalizedStringKey, value: Binding<String>,
                       keyboard: UIKeyboardType = .default,
                       secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(AquaTag.Typography.micro).tracking(1)
                .foregroundStyle(AquaTag.Colors.inkSoft)
                .textCase(.uppercase)
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
