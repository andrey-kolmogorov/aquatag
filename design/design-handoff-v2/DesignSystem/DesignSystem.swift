//
//  DesignSystem.swift
//  AquaTag
//
//  Central design tokens: colors, typography, spacing, radii, shadows.
//  Everything visual should be pulled from here — no hard-coded values in views.
//
//  Drop this file under `AquaTag/DesignSystem/` and the color assets
//  under `AquaTag/Assets.xcassets/` — color names must match the
//  string literals in `AquaTag.Colors` below.
//

import SwiftUI

// MARK: - Namespace

enum AquaTag {}

// MARK: - Colors

extension AquaTag {
    /// Colour palette pulled from Assets.xcassets.
    /// Light + dark variants live in the asset catalog; this struct just
    /// references them by name so the compiler catches typos.
    enum Colors {

        // Surfaces
        static let bg          = Color("AT/BG")            // #F6EFDF  (dark: #1B2A1A)
        static let paper       = Color("AT/Paper")         // #FFF9EC  (dark: #243624)
        static let elevated    = Color("AT/Elevated")      // #FFFFFF  (dark: #2E4430)

        // Ink (text)
        static let ink         = Color("AT/Ink")           // #1B2A1A
        static let inkSoft     = Color("AT/InkSoft")       // #5A6B57
        static let inkMute     = Color("AT/InkMute")       // #8A9786

        // Brand
        static let moss        = Color("AT/Moss")          // #2D8C4E  — primary
        static let mossDeep    = Color("AT/MossDeep")      // #1E5D33
        static let terracotta  = Color("AT/Terracotta")    // #C8463A  — overdue / alert
        static let amber       = Color("AT/Amber")         // #E8A020  — dueSoon / warn
        static let cream       = Color("AT/Cream")         // #FFF9EC

        // Dividers + hairlines
        static let divider     = Color("AT/Divider")       // rgba(27,42,26,0.12)
        static let hairline    = Color("AT/Hairline")      // rgba(27,42,26,0.06)

        // Status helpers — map from Plant.wateringStatus
        static func status(_ status: WateringStatus) -> Color {
            switch status {
            case .ok:       return moss
            case .dueSoon:  return amber
            case .overdue:  return terracotta
            case .unknown:  return inkMute
            }
        }
    }
}

// MARK: - Typography

extension AquaTag {
    /// Type system mirrors the marketing site:
    /// • Fraunces — display serif for titles / counters
    /// • IBM Plex Sans — body UI text
    /// • IBM Plex Mono — tag IDs, entity IDs, technical strings
    ///
    /// Fonts must be bundled. See `HANDOFF.md` → "Fonts" for the Info.plist
    /// `UIAppFonts` entries and the file list to add to the Xcode target.
    enum Typography {
        // Display (serif)
        static let displayXL = Font.custom("Fraunces-Regular", size: 56).weight(.regular)
        static let displayL  = Font.custom("Fraunces-Regular", size: 40).weight(.regular)
        static let displayM  = Font.custom("Fraunces-Medium",  size: 28).weight(.medium)
        static let displayS  = Font.custom("Fraunces-Medium",  size: 22).weight(.medium)

        // UI (sans)
        static let title     = Font.custom("IBMPlexSans-SemiBold", size: 20)
        static let headline  = Font.custom("IBMPlexSans-SemiBold", size: 17)
        static let body      = Font.custom("IBMPlexSans-Regular",  size: 16)
        static let subhead   = Font.custom("IBMPlexSans-Medium",   size: 14)
        static let caption   = Font.custom("IBMPlexSans-Regular",  size: 13)
        static let micro     = Font.custom("IBMPlexSans-Medium",   size: 11)

        // Mono (technical)
        static let mono      = Font.custom("IBMPlexMono-Regular",  size: 13)
        static let monoSmall = Font.custom("IBMPlexMono-Regular",  size: 11)

        // Letter-spaced label (uppercase eyebrows, section headers)
        static let eyebrow   = Font.custom("IBMPlexMono-Medium",   size: 11)
    }
}

// MARK: - Spacing

extension AquaTag {
    /// 4-pt based spacing scale. Use these instead of literal paddings.
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64

        /// Screen-edge horizontal padding. Defaults to 20pt to match the prototype.
        static let screenEdge: CGFloat = 20
    }
}

// MARK: - Radius

extension AquaTag {
    enum Radius {
        static let xs:   CGFloat = 6
        static let sm:   CGFloat = 10
        static let md:   CGFloat = 14
        static let lg:   CGFloat = 20
        static let xl:   CGFloat = 28
        static let pill: CGFloat = 999
    }
}

// MARK: - Shadow

extension AquaTag {
    enum Shadow {
        /// Card resting shadow.
        static let card   = ShadowStyle(color: Color.black.opacity(0.06), radius: 12, y: 4)
        /// Elevated sheet / floating action button.
        static let raised = ShadowStyle(color: Color.black.opacity(0.10), radius: 20, y: 8)
        /// Hairline shadow under navbars when content scrolls.
        static let nav    = ShadowStyle(color: Color.black.opacity(0.04), radius: 6,  y: 2)
    }

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }
}

extension View {
    /// Convenience: `.atShadow(AquaTag.Shadow.card)`.
    func atShadow(_ s: AquaTag.ShadowStyle) -> some View {
        shadow(color: s.color, radius: s.radius, x: 0, y: s.y)
    }
}

// MARK: - Motion

extension AquaTag {
    enum Motion {
        static let quick:  Animation = .spring(response: 0.28, dampingFraction: 0.85)
        static let smooth: Animation = .spring(response: 0.42, dampingFraction: 0.80)
        static let soft:   Animation = .easeOut(duration: 0.35)
    }
}
