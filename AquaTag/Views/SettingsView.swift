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
    @State private var cleanupViewModel: HelperCleanupViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AquaTag.Spacing.lg) {
                    heroHeader
                    haCard
                    deviceCard
                    notificationsCard
                    plantHelpersCard
                    helperCleanupCard
                    #if DEBUG
                    debugSeedCard
                    #endif
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
                if cleanupViewModel == nil {
                    cleanupViewModel = HelperCleanupViewModel(modelContext: modelContext)
                }
            }
            .onDisappear { viewModel?.saveSettings() }
            .alert(
                L10n.Settings.cleanupConfirmTitle,
                isPresented: Binding(
                    get: { cleanupViewModel?.showingDeleteConfirmation ?? false },
                    set: { cleanupViewModel?.showingDeleteConfirmation = $0 }
                )
            ) {
                Button(L10n.Plants.cancel, role: .cancel) { }
                Button(L10n.Settings.cleanupConfirmAction, role: .destructive) {
                    Task { await cleanupViewModel?.deleteSelected() }
                }
            } message: {
                Text(L10n.Settings.cleanupConfirmBody(cleanupViewModel?.selectedCount ?? 0))
            }
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
                                         Task {
                                             if v {
                                                 await viewModel?.requestNotificationPermission()
                                             } else {
                                                 // Switching off has to clear what's
                                                 // already queued — pending reminders
                                                 // fire regardless of this flag.
                                                 await viewModel?.disableReminders()
                                             }
                                         }
                                     })) {
                    Text(L10n.Settings.remindersToggle).font(AquaTag.Typography.body)
                }
                .tint(AquaTag.Colors.moss)

                if viewModel?.notificationsEnabled == true {
                    DatePicker(selection: Binding(get: { viewModel?.notificationTime ?? Date() },
                                                  set: { newTime in
                                                      viewModel?.notificationTime = newTime
                                                      // Already-scheduled reminders keep
                                                      // their original time unless they're
                                                      // rebuilt.
                                                      Task { await viewModel?.rescheduleAllReminders() }
                                                  }),
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
                                if let entityID = plant.haEntityID {
                                    Text(entityID).font(AquaTag.Typography.monoSmall)
                                        .foregroundStyle(AquaTag.Colors.moss)
                                        .textSelection(.enabled)
                                        .lineLimit(1).minimumScaleFactor(0.6)
                                } else {
                                    Text(L10n.Settings.helpersUnlinked)
                                        .font(AquaTag.Typography.caption)
                                        .foregroundStyle(AquaTag.Colors.inkMute)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var helperCleanupCard: some View {
        card(title: L10n.Settings.sectionCleanup, subtitle: L10n.Settings.cleanupSub) {
            VStack(alignment: .leading, spacing: AquaTag.Spacing.sm) {
                scanButton

                if let error = cleanupViewModel?.scanError {
                    VStack(alignment: .leading, spacing: 2) {
                        Label(L10n.Settings.cleanupScanFailed, systemImage: "xmark.circle.fill")
                            .font(AquaTag.Typography.subhead)
                            .foregroundStyle(AquaTag.Colors.terracotta)
                        Text(error)
                            .font(AquaTag.Typography.caption)
                            .foregroundStyle(AquaTag.Colors.inkSoft)
                    }
                }

                if let vm = cleanupViewModel, vm.hasScanned {
                    if vm.adoptedCount > 0 {
                        Label(
                            L10n.Settings.cleanupAdopted(vm.adoptedCount),
                            systemImage: "link"
                        )
                        .font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.moss)
                    }

                    if vm.rows.isEmpty {
                        Text(L10n.Settings.cleanupEmpty)
                            .font(AquaTag.Typography.caption)
                            .foregroundStyle(AquaTag.Colors.inkSoft)
                    } else {
                        helperRows(vm)
                        selectionControls(vm)
                        deleteButton(vm)
                        deleteResultLabel(vm)
                    }
                }
            }
        }
    }

    private var scanButton: some View {
        let isScanning = cleanupViewModel?.phase == .scanning
        let hasScanned = cleanupViewModel?.hasScanned ?? false

        return Button {
            Task { await cleanupViewModel?.scan() }
        } label: {
            HStack {
                if isScanning {
                    ProgressView()
                } else {
                    Image(systemName: "magnifyingglass")
                    Text(hasScanned ? L10n.Settings.cleanupRescan : L10n.Settings.cleanupScan)
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
        .disabled(isScanning || cleanupViewModel?.phase == .deleting)
    }

    private func helperRows(_ vm: HelperCleanupViewModel) -> some View {
        VStack(alignment: .leading, spacing: AquaTag.Spacing.xs) {
            ForEach(vm.rows) { row in
                HelperCleanupRow(
                    row: row,
                    linkCandidates: vm.linkCandidates(),
                    onToggle: { vm.toggle(row.id) },
                    onLink: { plant in vm.link(row: row, to: plant) }
                )
            }
        }
    }

    @ViewBuilder
    private func selectionControls(_ vm: HelperCleanupViewModel) -> some View {
        if vm.hasSelectableRows {
            HStack(spacing: AquaTag.Spacing.md) {
                Button(L10n.Settings.cleanupSelectOrphaned) { vm.selectAllOrphaned() }
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.moss)
                if vm.selectedCount > 0 {
                    Button(L10n.Settings.cleanupClearSelection) { vm.clearSelection() }
                        .font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
                Spacer()
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func deleteButton(_ vm: HelperCleanupViewModel) -> some View {
        if vm.hasSelectableRows {
            Button(role: .destructive) {
                vm.showingDeleteConfirmation = true
            } label: {
                HStack {
                    if vm.phase == .deleting {
                        ProgressView()
                    } else {
                        Image(systemName: "trash")
                        Text(L10n.Settings.cleanupDelete(vm.selectedCount))
                    }
                }
                .font(AquaTag.Typography.headline)
                .foregroundStyle(vm.selectedCount == 0 ? AquaTag.Colors.inkMute : AquaTag.Colors.terracotta)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md)
                    .strokeBorder(
                        vm.selectedCount == 0 ? AquaTag.Colors.divider : AquaTag.Colors.terracotta,
                        lineWidth: 1.5
                    ))
            }
            .buttonStyle(.plain)
            .disabled(vm.selectedCount == 0 || vm.phase == .deleting)
        }
    }

    @ViewBuilder
    private func deleteResultLabel(_ vm: HelperCleanupViewModel) -> some View {
        switch vm.deleteResult {
        case .success(let deleted):
            Label(L10n.Settings.cleanupResultSuccess(deleted), systemImage: "checkmark.circle.fill")
                .font(AquaTag.Typography.subhead)
                .foregroundStyle(AquaTag.Colors.moss)
        case .partial(let deleted, let failed):
            Label(
                L10n.Settings.cleanupResultPartial(deleted: deleted, failed: failed),
                systemImage: "exclamationmark.triangle.fill"
            )
            .font(AquaTag.Typography.subhead)
            .foregroundStyle(AquaTag.Colors.terracotta)
        case nil:
            EmptyView()
        }
    }

    #if DEBUG
    private var debugSeedCard: some View {
        card(title: "DEBUG · SAMPLE DATA",
             subtitle: "Only available in debug builds. Used for screenshots and visual QA.") {
            VStack(spacing: AquaTag.Spacing.sm) {
                Button {
                    DebugSeed.seed(into: modelContext)
                } label: {
                    Label("Seed sample data", systemImage: "wand.and.stars")
                        .font(AquaTag.Typography.headline)
                        .foregroundStyle(AquaTag.Colors.moss)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md)
                            .strokeBorder(AquaTag.Colors.moss, lineWidth: 1.5))
                }
                .buttonStyle(.plain)

                Button {
                    DebugSeed.wipe(in: modelContext)
                } label: {
                    Label("Wipe all plants and history", systemImage: "trash")
                        .font(AquaTag.Typography.headline)
                        .foregroundStyle(AquaTag.Colors.terracotta)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md)
                            .strokeBorder(AquaTag.Colors.terracotta, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
    }
    #endif

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
