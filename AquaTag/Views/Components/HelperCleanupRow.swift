//
//  HelperCleanupRow.swift
//  AquaTag
//
//  One Home Assistant helper in the Settings cleanup list.
//

import SwiftUI

struct HelperCleanupRow: View {
    let row: HelperCleanupViewModel.Row
    let linkCandidates: [Plant]
    let onToggle: () -> Void
    let onLink: (Plant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                selectionControl

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.helper.name)
                        .font(AquaTag.Typography.subhead)
                        .foregroundStyle(AquaTag.Colors.ink)
                        .lineLimit(1)

                    Text(row.helper.entityID)
                        .font(AquaTag.Typography.monoSmall)
                        .foregroundStyle(AquaTag.Colors.moss)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    // The only thing distinguishing several helpers that share a
                    // name — keep it legible, not truncated.
                    Text(lastWateredText)
                        .font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.inkSoft)

                    badge
                }

                Spacer(minLength: 0)
            }

            if let deleteError = row.deleteError {
                Text(deleteError)
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.terracotta)
                    .padding(.leading, 30)
            }

            if case .adoptable = row.classification, !linkCandidates.isEmpty {
                linkMenu
                    .padding(.leading, 30)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Pieces

    @ViewBuilder
    private var selectionControl: some View {
        if row.isSelectable {
            Button(action: onToggle) {
                Image(systemName: row.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(row.isSelected ? AquaTag.Colors.terracotta : AquaTag.Colors.inkMute)
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: lockedSymbol)
                .font(.system(size: 20))
                .foregroundStyle(AquaTag.Colors.moss)
        }
    }

    private var lockedSymbol: String {
        row.helper.isDeletable ? "checkmark.circle.fill" : "lock.fill"
    }

    @ViewBuilder
    private var badge: some View {
        switch row.classification {
        case .linked(let plantName):
            badgeLabel(
                text: Text(plantName),
                systemImage: "link",
                color: AquaTag.Colors.moss
            )
        case .adoptable(let plantName):
            badgeLabel(
                text: Text(L10n.Settings.cleanupBadgeAdoptable(plantName: plantName)),
                systemImage: "arrow.triangle.merge",
                color: AquaTag.Colors.amber
            )
        case .orphaned:
            if row.helper.isDeletable {
                badgeLabel(
                    text: Text(L10n.Settings.cleanupBadgeOrphaned),
                    systemImage: "questionmark.circle",
                    color: AquaTag.Colors.terracotta
                )
            } else {
                badgeLabel(
                    text: Text(L10n.Settings.cleanupBadgeLocked),
                    systemImage: "lock",
                    color: AquaTag.Colors.inkMute
                )
            }
        }
    }

    private func badgeLabel(text: Text, systemImage: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 10, weight: .semibold))
            text.font(AquaTag.Typography.micro)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.10)))
    }

    private var linkMenu: some View {
        Menu {
            ForEach(linkCandidates) { plant in
                Button(plant.name) { onLink(plant) }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "link.badge.plus").font(.system(size: 11, weight: .semibold))
                Text(L10n.Settings.cleanupLinkAction(plantName: linkCandidates.first?.name ?? ""))
                    .font(AquaTag.Typography.caption)
            }
            .foregroundStyle(AquaTag.Colors.moss)
        }
    }

    private var lastWateredText: String {
        guard let date = row.helper.lastWatered else {
            return String(localized: "settings.cleanup.never.set")
        }
        return L10n.Settings.cleanupLastWatered(DateFormatters.dateTime.string(from: date))
    }
}
