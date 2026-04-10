# AquaTag

NFC-based plant watering tracker for iOS with Home Assistant integration.

Tap an NFC sticker on your plant pot to instantly log watering. The app syncs with Home Assistant via Nabu Casa, schedules reminders based on each plant's watering interval, and works offline with automatic retry.

## Features

- **NFC tap to log** — scan a sticker on the pot, watering is recorded instantly
- **Home Assistant sync** — updates `input_datetime` helpers and fires `aquatag_plant_watered` events
- **Auto-creates HA helpers** — no need to manually create `input_datetime` entities for each plant
- **Smart reminders** — local notifications based on per-plant watering intervals
- **Offline-first** — saves locally, queues failed syncs, retries on next launch
- **Write NFC tags** — program blank NTAG stickers directly from the app
- **Multi-user** — multiple household members can log waterings independently

## Requirements

- iPhone 7+ with iOS 17.0+
- [Home Assistant](https://home-assistant.io) with [Nabu Casa](https://nabucasa.com) remote access
- NFC stickers (NTAG213 recommended — cheapest option, plenty of storage)

## Setup

### Home Assistant

1. Create a **Long-Lived Access Token** in your HA profile (Profile → Security → Long-Lived Access Tokens)

### App

1. Open AquaTag → **Settings** tab
2. Enter your Nabu Casa URL (e.g. `https://abc123.ui.nabu.casa`)
3. Paste the access token
4. Set a device name (identifies who watered)
5. Tap **Test Connection**

### Adding Plants

1. Tap `+` in the Plants tab → fill in name, emoji, watering interval
2. The app auto-creates the corresponding `input_datetime` helper in HA via WebSocket
3. Stick an NFC tag on the pot → open plant detail → **Write to NFC Tag**

## How It Works

```
NFC scan → parse aquatag:{plant_id} → lookup in SwiftData → update locally
  → sync to HA (REST API) → on failure, queue for retry
```

**NFC tag format:** NDEF Text Record containing `aquatag:{plant_id}` (e.g. `aquatag:monstera`)

**HA integration:**
- `POST /api/services/input_datetime/set_datetime` — update last watered time
- `POST /api/events/aquatag_plant_watered` — fire event (for automations)
- `GET /api/states/input_datetime.plant_{id}_last_watered` — fetch current state
- `wss://.../api/websocket` → `input_datetime/create` — auto-create helpers

### Example HA Automation

```yaml
automation:
  - alias: "AquaTag Watering Logged"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: logbook.log
        data:
          name: "{{ trigger.event.data.plant_name }}"
          message: "watered by {{ trigger.event.data.device_name }}"
```

## Architecture

Swift 6, SwiftUI, SwiftData, CoreNFC. Zero external dependencies.

```
AquaTag/
├── Models/          Plant, AppSettings, PendingWateringEvent (@Model)
├── ViewModels/      PlantListViewModel, SettingsViewModel (@Observable @MainActor)
├── Views/           PlantList, PlantDetail, AddPlant, History, Settings
│   └── Components/  PlantRowView, WateringStatusBadge
├── Services/        NFCService, HAService, KeychainService, NotificationService
└── Utilities/       PlantIDGenerator, DateFormatters
```

**Key patterns:**
- MVVM with service layer
- Async/await throughout (no completion handlers)
- HA token in iOS Keychain, never in SwiftData
- Offline queue (`PendingWateringEvent`) for failed HA calls
- `PBXFileSystemSynchronizedRootGroup` — Xcode auto-discovers files from disk

## Building

```bash
# Simulator
xcodebuild -scheme AquaTag -destination 'generic/platform=iOS Simulator'

# Device
xcodebuild -scheme AquaTag -destination 'generic/platform=iOS'
```

Requires Xcode 16+. No SPM/CocoaPods — all Apple frameworks.

## License

Copyright © 2026 Andrei Kolmogorov. All rights reserved.
