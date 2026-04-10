# AquaTag Setup Checklist

Use this checklist to set up AquaTag for the first time.

## Prerequisites

- [ ] iPhone 7 or newer (with NFC capability)
- [ ] iOS 17.0 or later installed
- [ ] Home Assistant instance running
- [ ] Nabu Casa Cloud subscription active
- [ ] Nabu Casa remote URL configured
- [ ] NFC stickers purchased (NTAG213 recommended)

## Home Assistant Configuration

### 1. Get Nabu Casa Remote URL
- [ ] Log into Home Assistant
- [ ] Go to **Configuration** → **Home Assistant Cloud**
- [ ] Verify Remote Control is enabled
- [ ] Copy the remote URL (e.g., `https://abc123xyz.ui.nabu.casa`)

### 2. Create Long-Lived Access Token
- [ ] Go to your **Profile** (bottom left)
- [ ] Scroll to **Security** section
- [ ] Under **Long-Lived Access Tokens**, click **Create Token**
- [ ] Name it "AquaTag" or similar
- [ ] Copy the token immediately (you can't see it again!)
- [ ] Save the token somewhere secure temporarily

### 3. Test Home Assistant API
- [ ] Use a tool like Postman or curl to test:
  ```bash
  curl -X GET "https://YOUR-URL.ui.nabu.casa/api/" \
    -H "Authorization: Bearer YOUR_TOKEN"
  ```
- [ ] Should return JSON with `{"message": "API running."}`

## App Configuration

### 1. Initial Setup
- [ ] Open AquaTag app
- [ ] Tap **Settings** tab
- [ ] Enter your Nabu Casa URL
- [ ] Paste your Long-Lived Access Token
- [ ] Enter a device name (e.g., "Andrei's iPhone")
- [ ] Tap **Test Connection**
- [ ] Verify connection successful (green checkmark)

### 2. Notification Setup
- [ ] Enable **Watering Reminders** toggle
- [ ] Grant notification permission when prompted
- [ ] Set preferred reminder time (e.g., 8:00 AM)
- [ ] Set default watering interval (e.g., 7 days)

### 3. Add Your First Plant

**Option A: Manual Entry**
- [ ] Go to **Plants** tab
- [ ] Tap the **+** button
- [ ] Enter plant name (e.g., "Monstera Deliciosa")
- [ ] Choose emoji (e.g., 🌿)
- [ ] Set watering interval (e.g., 7 days)
- [ ] Add optional notes
- [ ] Save the plant
- [ ] **Note the HA Entity ID shown** (you'll need this next)

**Option B: NFC-First**
- [ ] Prepare a blank NFC sticker
- [ ] Tap **Scan Tag** button
- [ ] Hold iPhone near tag
- [ ] When prompted "New plant found", tap **Register Plant**
- [ ] Fill in plant details
- [ ] Save

### 4. Create Home Assistant Helper
For each plant added, create an `input_datetime` helper:

- [ ] In Home Assistant, go to **Settings** → **Devices & Services** → **Helpers**
- [ ] Click **Create Helper** → **Date and/or time**
- [ ] Configure:
  - Name: `Plant {Name} Last Watered` (display name, can be anything)
  - Entity ID: **MUST match** what AquaTag shows (e.g., `input_datetime.plant_monstera_deliciosa_last_watered`)
  - Has date: ✅ Enabled
  - Has time: ✅ Enabled
- [ ] Save the helper
- [ ] Repeat for each plant

**Quick Check:** The Settings tab in AquaTag shows all required entity IDs under "Home Assistant Setup Guide"

### 5. Write NFC Tag (If Not Already Done)
- [ ] Open plant detail view
- [ ] Tap **Write to NFC Tag**
- [ ] Hold iPhone near blank NFC sticker
- [ ] Wait for "Tag written successfully!" message
- [ ] Test by scanning the tag
- [ ] Affix sticker to plant pot

### 6. Test First Watering
- [ ] Water your plant physically 💧
- [ ] Tap **Scan Tag** button in app
- [ ] Hold iPhone near plant's NFC sticker
- [ ] Verify success message appears
- [ ] Check Home Assistant:
  - [ ] Go to **Developer Tools** → **States**
  - [ ] Find `input_datetime.plant_{your_plant}_last_watered`
  - [ ] Verify timestamp was updated
- [ ] Check notification scheduled (if enabled)

## Multi-User Setup (Optional)

If you want both household members to use AquaTag:

### Person 2's iPhone
- [ ] Install AquaTag on second iPhone
- [ ] Use **same** Nabu Casa URL
- [ ] Use **same** Long-Lived Access Token (or create a separate one)
- [ ] Use **different** device name (e.g., "Wife's iPhone")
- [ ] Add the same plants manually (or scan their NFC tags)
- [ ] **Do NOT** create duplicate HA helpers (reuse existing ones)

## Verification Checklist

After setup, verify everything works:

- [ ] Can add plants in app
- [ ] Can scan NFC tags successfully
- [ ] Waterings log to Home Assistant correctly
- [ ] Timestamps update in HA input_datetime helpers
- [ ] `aquatag_plant_watered` events fire in HA (check event listener)
- [ ] Notifications schedule correctly (check after first watering)
- [ ] Pull-to-refresh syncs data from HA
- [ ] Connection test passes in Settings
- [ ] Can write new NFC tags
- [ ] Offline mode queues events (test by turning off WiFi)

## Common Setup Issues

### "Connection failed" in Settings
- ✅ Check Nabu Casa URL format (must include `https://`)
- ✅ Verify token was copied correctly (no extra spaces)
- ✅ Ensure Nabu Casa subscription is active
- ✅ Test HA is accessible from outside your network

### NFC not scanning
- ✅ Verify NFC is enabled in iPhone settings
- ✅ Remove thick phone cases
- ✅ Hold iPhone steady for 2-3 seconds
- ✅ Ensure sticker is NTAG213/215/216

### "Plant not found" after scan
- ✅ Plant must be added to app first
- ✅ Or use the "Register Plant" prompt when scanning unknown tag
- ✅ Verify tag was written by AquaTag (or in correct format)

### Timestamp not updating in Home Assistant
- ✅ Check entity ID matches exactly (case-sensitive)
- ✅ Verify helper exists and is type `input_datetime`
- ✅ Test HA token has write permissions
- ✅ Check HA logs for errors

### Notifications not working
- ✅ Grant notification permission in iOS Settings
- ✅ Enable "Watering Reminders" in app Settings
- ✅ Water a plant to trigger first notification
- ✅ Check Notification Center after due date

## Next Steps

Once setup is complete:

1. **Add all your plants** — Either manually or by scanning tags
2. **Create all HA helpers** — One for each plant
3. **Write NFC tags** — Affix to plant pots
4. **Water your plants!** — Use AquaTag to log each watering
5. **Check history** — View timeline in History tab
6. **Set up automations** (optional) — Trigger on `aquatag_plant_watered` events

## Maintenance

- **Weekly**: Review overdue plants in Plants tab
- **Monthly**: Verify HA connection still works
- **As needed**: Refresh from HA to sync timestamps
- **When adding plants**: Create corresponding HA helpers

---

🎉 **You're all set!** Start scanning and tracking your plant watering with AquaTag.
