//
//  CharacterView.swift
//  AquaTag
//
//  Reusable character avatar. Renders the correct sticker illustration
//  at any size, with the species hero color as background.
//
//  Usage:
//    CharacterView(character: plant.character, size: .medium)
//    CharacterView(character: .monty, size: .large)
//

import SwiftUI

struct CharacterView: View {
    let character: Character
    var size: Size = .medium
    var showRing: Bool = true

    enum Size {
        case small      // 32pt — inline in rows
        case medium     // 56pt — default row avatar
        case large      // 96pt — detail header
        case hero       // 160pt — empty states, character picker

        var pt: CGFloat {
            switch self {
            case .small:  return 32
            case .medium: return 56
            case .large:  return 96
            case .hero:   return 160
            }
        }

        var ringWidth: CGFloat {
            switch self {
            case .small:  return 1.5
            case .medium: return 2
            case .large:  return 3
            case .hero:   return 4
            }
        }
    }

    var body: some View {
        ZStack {
            // Background halo — soft character color
            Circle()
                .fill(character.color.opacity(0.12))
                .frame(width: size.pt, height: size.pt)

            // The character sticker itself
            Image(character.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size.pt * 0.92, height: size.pt * 0.92)

            // Cream ring for contrast on colored backgrounds
            if showRing {
                Circle()
                    .strokeBorder(
                        AquaTag.Colors.cream.opacity(0.9),
                        lineWidth: size.ringWidth
                    )
                    .frame(width: size.pt, height: size.pt)
            }
        }
        .frame(width: size.pt, height: size.pt)
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            ForEach(Character.allCases) { c in
                VStack(spacing: 8) {
                    CharacterView(character: c, size: .medium)
                    Text(c.displayName)
                        .font(AquaTag.Typography.micro)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
            }
        }
        CharacterView(character: .monty, size: .hero)
    }
    .padding()
    .background(AquaTag.Colors.bg)
}
