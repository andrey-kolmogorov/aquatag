//
//  PlantListView.swift
//  AquaTag — redesigned
//
//  Drop-in replacement for the existing PlantListView. Same bindings
//  and ViewModel, new visual language.
//
//  CHANGES FROM ORIGINAL:
//  • Custom background (AT/BG cream) instead of default grouped List
//  • Fraunces title ("Nursery") instead of "🌿 Plants"
//  • Card-based rows (see redesigned PlantRowView), stacked in a scroll view
//  • Primary scan button is a full-width moss pill pinned to the bottom
//  • Empty state uses the hero CharacterView
//

import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Query(sort: \Plant.name) private var plants: [Plant]
    @State private var viewModel: PlantListViewModel?
    @State private var showingAddPlant = false
    @State private var selectedPlant: Plant?
    @Binding var pendingPlantID: String?

    /// Two-column grid + inline scan CTA whenever there's horizontal room:
    /// any iPhone in landscape (vertical compact) or iPad / Pro Max in
    /// either orientation (horizontal regular).
    private var isWide: Bool {
        hSizeClass == .regular || vSizeClass == .compact
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AquaTag.Colors.bg.ignoresSafeArea()

                if plants.isEmpty {
                    emptyStateView
                } else {
                    plantList
                }

                if !isWide {
                    scanButton
                        .padding(.horizontal, AquaTag.Spacing.screenEdge)
                        .padding(.bottom, AquaTag.Spacing.md)
                }
            }
            .navigationTitle("")  // custom header inside content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { toolbarRefresh }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddPlant = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AquaTag.Colors.ink)
                    }
                }
            }
            .sheet(isPresented: $showingAddPlant) { AddPlantView() }
            .sheet(item: $selectedPlant) { plant in PlantDetailView(plant: plant) }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingNewPlantSheet ?? false },
                set: { if !$0 { viewModel?.showingNewPlantSheet = false } }
            )) {
                if let id = viewModel?.scannedPlantID {
                    AddPlantView(suggestedID: id)
                }
            }
            .alert(L10n.Plants.successTitle, isPresented: Binding(
                get: { viewModel?.showingSuccess ?? false },
                set: { if !$0 { viewModel?.showingSuccess = false } }
            )) { Button(L10n.Plants.ok) { } } message: { Text(viewModel?.successMessage ?? "") }
            .alert(L10n.Plants.errorTitle, isPresented: Binding(
                get: { viewModel?.showingError ?? false },
                set: { if !$0 { viewModel?.showingError = false } }
            )) { Button(L10n.Plants.ok) { } } message: { Text(viewModel?.errorMessage ?? "") }
            .alert(L10n.Plants.alreadyTitle, isPresented: Binding(
                get: { viewModel?.showingWaterConfirmation ?? false },
                set: {
                    if !$0 {
                        viewModel?.showingWaterConfirmation = false
                        viewModel?.plantPendingConfirmation = nil
                    }
                }
            )) {
                Button(L10n.Plants.waterAnyway) { Task { await viewModel?.confirmWatering() } }
                Button(L10n.Plants.cancel, role: .cancel) { }
            } message: {
                if let plant = viewModel?.plantPendingConfirmation {
                    Text(L10n.Plants.alreadyBody(plantName: plant.name))
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = PlantListViewModel(modelContext: modelContext)
                }
                Task { await viewModel?.retryPendingEvents() }
                if let plantID = pendingPlantID {
                    pendingPlantID = nil
                    Task { await viewModel?.handleBackgroundTag(plantID: plantID) }
                }
            }
            .onChange(of: pendingPlantID) { _, newValue in
                guard let id = newValue else { return }
                pendingPlantID = nil
                Task { await viewModel?.handleBackgroundTag(plantID: id) }
            }
        }
    }

    // MARK: - Header

    private var toolbarRefresh: some View {
        Button {
            Task { await viewModel?.refreshFromHA() }
        } label: {
            if viewModel?.isRefreshing == true {
                ProgressView()
            } else {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }
        }
        .disabled(viewModel?.isRefreshing == true)
    }

    // MARK: - Content

    /// Most-urgent first: overdue → due today → tomorrow → due in N days →
    /// never watered (no schedule yet) at the bottom. Ties broken by name.
    private var sortedPlants: [Plant] {
        plants.sorted { a, b in
            let aDays = a.daysUntilNextWatering ?? Int.max
            let bDays = b.daysUntilNextWatering ?? Int.max
            if aDays != bDays { return aDays < bDays }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    private var plantList: some View {
        ScrollView {
            // Hero header — eyebrow + display title.
            // In wide layouts the inline Scan CTA replaces the floating FAB.
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Plants.headerEyebrow)
                        .font(AquaTag.Typography.eyebrow)
                        .tracking(2)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                    Text(L10n.Plants.count(plants.count))
                        .font(AquaTag.Typography.displayL)
                        .foregroundStyle(AquaTag.Colors.ink)
                }
                Spacer()
                if isWide {
                    inlineScanButton
                }
            }
            .padding(.horizontal, AquaTag.Spacing.screenEdge)
            .padding(.top, AquaTag.Spacing.xs)
            .padding(.bottom, AquaTag.Spacing.md)

            plantGrid
                .padding(.horizontal, AquaTag.Spacing.screenEdge)
                .padding(.bottom, isWide ? AquaTag.Spacing.xl : 100)
        }
        .refreshable { await viewModel?.refreshFromHA() }
    }

    @ViewBuilder
    private var plantGrid: some View {
        let columns: [GridItem] = isWide
            ? [GridItem(.flexible(), spacing: AquaTag.Spacing.sm),
               GridItem(.flexible(), spacing: AquaTag.Spacing.sm)]
            : [GridItem(.flexible())]

        LazyVGrid(columns: columns, spacing: AquaTag.Spacing.sm) {
            ForEach(sortedPlants) { plant in
                Button { selectedPlant = plant } label: {
                    PlantRowView(plant: plant) {
                        Task { await viewModel?.waterPlantIfNeeded(plant) }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: AquaTag.Spacing.lg) {
            Spacer()
            CharacterView(character: .monty, size: .hero, showRing: false)
            VStack(spacing: AquaTag.Spacing.xs) {
                Text(L10n.Plants.emptyTitle)
                    .font(AquaTag.Typography.displayM)
                    .foregroundStyle(AquaTag.Colors.ink)
                    .multilineTextAlignment(.center)
                Text(L10n.Plants.emptyBody)
                    .font(AquaTag.Typography.body)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AquaTag.Spacing.xl)
            }
            Spacer()
        }
    }

    // MARK: - Scan FAB

    private var scanButton: some View {
        Button {
            Task { await viewModel?.scanNFCTag() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: 18, weight: .semibold))
                Text(L10n.Plants.scanCTA)
                    .font(AquaTag.Typography.headline)
            }
            .foregroundStyle(AquaTag.Colors.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule().fill(AquaTag.Colors.moss)
            )
            .atShadow(AquaTag.Shadow.raised)
        }
        .buttonStyle(.plain)
    }

    /// Compact, content-width variant of the scan CTA used in wide layouts
    /// where it sits next to the "N plants" header instead of overlaying
    /// the list as a floating button.
    private var inlineScanButton: some View {
        Button {
            Task { await viewModel?.scanNFCTag() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wave.3.right")
                    .font(.system(size: 15, weight: .semibold))
                Text(L10n.Plants.scanCTA)
                    .font(AquaTag.Typography.subhead)
            }
            .foregroundStyle(AquaTag.Colors.cream)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(Capsule().fill(AquaTag.Colors.moss))
        }
        .buttonStyle(.plain)
    }
}
