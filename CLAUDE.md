# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AquaTag is an iOS app that uses NFC tags on plant pots to log and track watering schedules, with Home Assistant integration via Nabu Casa. Built with Swift 6, SwiftUI, SwiftData, and CoreNFC. Zero external dependencies — Apple frameworks only.

- **Bundle ID:** com.andreiapps.AquaTag
- **Minimum iOS:** 17.0+
- **Swift:** 6 (strict concurrency)

## Build Commands

```bash
# Build for simulator
xcodebuild -scheme AquaTag -destination 'generic/platform=iOS Simulator'

# Build for device
xcodebuild -scheme AquaTag -destination 'generic/platform=iOS'
```

No package manager (SPM/CocoaPods) — all dependencies are Apple frameworks.

## Architecture

**MVVM with Service Layer.** SwiftData for persistence, Keychain for secrets.

- **Models** (`@Model` SwiftData): `Plant`, `AppSettings`, `PendingWateringEvent`
- **ViewModels** (`@MainActor @Observable`): `PlantListViewModel`, `SettingsViewModel`
- **Views** (SwiftUI): TabView root with Plants, History, Settings tabs
- **Services**: `NFCService` (CoreNFC), `HAService` (Home Assistant REST API), `KeychainService` (Security framework), `NotificationService` (UNUserNotificationCenter)
- **Utilities**: `PlantIDGenerator` (slug generation), `DateFormatters`

### Key Data Flow

NFC scan → parse `aquatag:{plant_id}` from NDEF text record → lookup Plant in SwiftData → update locally → sync to Home Assistant via REST API → on failure, queue to `PendingWateringEvent` for offline retry.

### File Layout

All source files live under `AquaTag/` in a standard folder hierarchy (`Models/`, `ViewModels/`, `Views/`, `Views/Components/`, `Services/`, `Utilities/`). The project uses `PBXFileSystemSynchronizedRootGroup` so Xcode auto-discovers files from disk — no manual pbxproj edits needed when adding/moving files.

## Key Patterns

- All ViewModels use `@MainActor @Observable` — maintain this for thread safety
- HA token stored in iOS Keychain via `KeychainService`, never in SwiftData
- Custom error enums (`NFCError`, `HAError`, `KeychainError`) with `LocalizedError` conformance
- Async/await throughout — no completion handlers
- NFC tag format: NDEF Text Record containing `aquatag:{plant_id}`
- HA integration uses `input_datetime` helpers and custom `aquatag_plant_watered` events
- Offline-first: watering saved locally first, HA sync is best-effort with retry queue

## Home Assistant API

The app communicates with HA via Nabu Casa URL:
- `POST /api/services/input_datetime/set_datetime` — update plant helper
- `POST /api/events/aquatag_plant_watered` — fire custom event
- `GET /api/states/input_datetime.plant_{id}_last_watered` — fetch state
- Auth: Bearer token in Authorization header
