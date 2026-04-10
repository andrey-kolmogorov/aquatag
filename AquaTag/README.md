# AquaTag 🌿💧

AquaTag is an iOS app that uses NFC tags on plant pots to log and track watering schedules, integrated with Home Assistant via Nabu Casa.

## Features

✅ **NFC-First Logging** — Tap your iPhone on a plant's NFC sticker to instantly log watering  
✅ **Home Assistant Integration** — Syncs with your self-hosted HA instance via Nabu Casa  
✅ **Smart Reminders** — Local notifications scheduled based on each plant's watering interval  
✅ **Multi-User Support** — Both household members can log waterings independently  
✅ **Offline Capable** — Logs waterings locally and syncs when connection is restored  
✅ **NFC Tag Writing** — Write plant IDs to blank NFC stickers directly from the app  

## Requirements

- iOS 17.0+
- iPhone with NFC capability (iPhone 7 or newer)
- Home Assistant instance with Nabu Casa remote access
- NFC stickers (NTAG213/215/216 recommended)

## Project Status

✅ Complete implementation following PRD v1.0

### What's Implemented

- ✅ SwiftData models (Plant, AppSettings, PendingWateringEvent)
- ✅ NFC scanning and writing (CoreNFC)
- ✅ Home Assistant REST API integration
- ✅ Secure token storage (Keychain)
- ✅ Local notification scheduling
- ✅ Plant list with status badges
- ✅ Plant detail/edit view
- ✅ Add plant flow with emoji picker
- ✅ Watering history timeline
- ✅ Settings with HA connection testing
- ✅ Offline sync queue for pending events
- ✅ Pull-to-refresh from HA
- ✅ MVVM architecture

## Setup Instructions

### 1. Xcode Configuration

The project is already configured with:
- Bundle ID: `com.andreirosu.aquatag`
- NFC capabilities enabled
- Push Notifications capability
- Info.plist with NFC usage description

### 2. Home Assistant Setup

For each plant you add, create an `input_datetime` helper in Home Assistant:

1. Go to **Settings** → **Devices & Services** → **Helpers**
2. Click **Create Helper** → **Date and/or time**
3. Name it following this pattern: `plant_{plant_id}_last_watered`
   - Example: `plant_monstera_last_watered`
4. The app's Settings screen shows the exact entity IDs you need to create

### 3. Long-Lived Access Token

1. In Home Assistant, go to your **Profile** → **Security**
2. Scroll to **Long-Lived Access Tokens**
3. Click **Create Token**
4. Give it a name like "AquaTag"
5. Copy the token and paste it into the app's Settings

### 4. First-Time App Setup

1. Launch AquaTag
2. Go to **Settings** tab
3. Enter your Nabu Casa URL (e.g., `https://abc123xyz.ui.nabu.casa`)
4. Paste your Long-Lived Access Token
5. Enter a device name (e.g., "Andrei's iPhone")
6. Tap **Test Connection** to verify
7. Enable notifications if desired

## Usage Guide

### Adding a Plant

**Option 1: Manual Entry**
1. Tap the `+` button in the Plants tab
2. Fill in plant name, emoji, and watering interval
3. Note the Home Assistant entity ID shown
4. Save and create the corresponding helper in HA

**Option 2: NFC-First**
1. Prepare a blank NFC sticker
2. Tap **Scan Tag** button
3. Hold iPhone near the blank tag
4. App will prompt you to register the new plant
5. Fill in details and save

### Logging a Watering

**Option 1: NFC Scan** (Primary)
1. Tap **Scan Tag** floating button
2. Hold iPhone near plant's NFC sticker
3. Watering is logged instantly with haptic feedback

**Option 2: Quick Water Button**
1. In the plant list, tap the blue water drop button
2. Confirms immediately without NFC scan

### Writing NFC Tags

1. Open any plant's detail view
2. Tap **Write to NFC Tag**
3. Hold iPhone near a blank NFC sticker
4. Tag will be written with `aquatag:{plant_id}` format

### Viewing History

1. Go to **History** tab
2. See all recent watering events
3. Shows plant name, who watered it, and when

## Architecture

```
AquaTag/
├── Models/                  # SwiftData models
│   ├── Plant.swift
│   ├── AppSettings.swift
│   └── PendingWateringEvent.swift
├── ViewModels/              # Observable view models
│   ├── PlantListViewModel.swift
│   └── SettingsViewModel.swift
├── Views/                   # SwiftUI views
│   ├── PlantListView.swift
│   ├── PlantDetailView.swift
│   ├── AddPlantView.swift
│   ├── WateringHistoryView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── PlantRowView.swift
│       └── WateringStatusBadge.swift
├── Services/                # Business logic & APIs
│   ├── NFCService.swift     (CoreNFC integration)
│   ├── HAService.swift      (Home Assistant API)
│   ├── NotificationService.swift
│   └── KeychainService.swift
└── Utilities/
    ├── PlantIDGenerator.swift
    └── DateFormatters.swift
```

## Home Assistant Integration Details

### API Endpoints Used

**Update last watered datetime:**
```
POST /api/services/input_datetime/set_datetime
{
  "entity_id": "input_datetime.plant_monstera_last_watered",
  "datetime": "2026-04-05T14:30:00"
}
```

**Fire custom event:**
```
POST /api/events/aquatag_plant_watered
{
  "plant_id": "monstera",
  "plant_name": "Monstera Deliciosa",
  "device_name": "Andrei's iPhone",
  "timestamp": "2026-04-05T14:30:00Z"
}
```

**Read last watered date:**
```
GET /api/states/input_datetime.plant_monstera_last_watered
```

### Creating Automations (Optional)

You can create HA automations triggered by the `aquatag_plant_watered` event:

```yaml
automation:
  - alias: "Log AquaTag Watering to Logbook"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: logbook.log
        data:
          name: "{{ trigger.event.data.plant_name }}"
          message: "Watered by {{ trigger.event.data.device_name }}"
```

## NFC Tag Recommendations

- **NTAG213** (144 bytes) — Cheapest, sufficient for AquaTag
- **NTAG215** (504 bytes) — More storage, not needed
- **NTAG216** (888 bytes) — Maximum storage, overkill

**Where to buy:**
- Amazon: Search "NTAG213 NFC stickers"
- AliExpress: Bulk stickers (30mm round recommended)

**Format:** The app writes standard NDEF Text records readable by any NFC-capable device.

## Troubleshooting

### "Cannot reach Home Assistant"
- Verify Nabu Casa URL is correct (must start with `https://`)
- Ensure Long-Lived Access Token is valid
- Check your internet connection
- Test connection in Settings tab

### NFC Tag Not Reading
- Hold iPhone steady near tag for 2-3 seconds
- Remove any thick phone cases
- Ensure tag is NDEF-formatted (blank tags work)
- Try cleaning the tag surface

### Notifications Not Appearing
- Enable notifications in Settings tab
- Grant notification permission when prompted by iOS
- Check iOS Settings → Notifications → AquaTag

### Plant Not Found After Scan
- Tag might not be registered yet
- App will prompt you to register the plant
- Ensure tag was written by AquaTag (or manually with correct format)

## Privacy & Security

- ✅ HA token stored securely in iOS Keychain
- ✅ All communication over HTTPS (Nabu Casa)
- ✅ No third-party analytics or tracking
- ✅ All data stored locally on device
- ✅ No iCloud sync (v1.0)

## Future Enhancements (Out of Scope for v1.0)

- 📱 Apple Watch companion app
- 📊 Watering statistics and charts
- 🌍 Weather-based watering adjustments
- 🔔 Widget for home screen
- ☁️ iCloud sync between devices
- 🧪 Fertilizing and pH tracking
- 🤖 Automated irrigation control via HA

## License

Copyright © 2026 Andrei Kolmogorov. All rights reserved.

## Support

For issues with:
- **The App**: Check this README and code comments
- **Home Assistant**: Visit [home-assistant.io](https://home-assistant.io)
- **Nabu Casa**: Visit [nabucasa.com](https://nabucasa.com)

---

**Built with ❤️ using SwiftUI, SwiftData, and CoreNFC**
