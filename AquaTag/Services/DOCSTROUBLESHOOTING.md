# AquaTag Troubleshooting Guide

## Common Issues and Solutions

### 1. App Crashes When Scanning NFC Tag

**Symptoms:**
- App closes immediately when NFC scan completes
- No error message shown

**Solutions:**
1. **Check Xcode Console** for crash logs:
   - Look for lines starting with `📡 NFC Raw payload`
   - Check what plant ID was read: `🏷️ Raw scanned NFC data`

2. **Verify Tag Format:**
   - Tag should contain: `aquatag:pahira` (for plant named "Pahira")
   - Not just `pahira`

3. **Re-write the Tag:**
   - Open plant detail view
   - Tap "Write to NFC Tag"
   - Hold near tag
   - Try scanning again

4. **Check Plant ID:**
   - In the app, tap on the plant
   - Check the HA Entity ID section
   - The plant ID is the part after `plant_` and before `_last_watered`
   - Example: `input_datetime.plant_pahira_last_watered` → ID is `pahira`

---

### 2. "Please configure Home Assistant settings first"

**Symptoms:**
- Tapping the water drop button shows this error
- Can't log waterings

**Required Settings:**
All three must be filled in:
1. ✅ **Nabu Casa URL** (e.g., `https://abc123xyz.ui.nabu.casa`)
2. ✅ **Long-Lived Access Token** (from HA)
3. ✅ **Device Name** (e.g., "Andrei's iPhone")

**Solutions:**

1. **Go to Settings Tab**
2. **Enter Nabu Casa URL:**
   - Get from: Home Assistant → Configuration → Home Assistant Cloud
   - Format: `https://YOUR-ID.ui.nabu.casa`
   - Must include `https://`

3. **Create Long-Lived Access Token:**
   - In Home Assistant: Profile → Security → Long-Lived Access Tokens
   - Click "Create Token"
   - Name it "AquaTag"
   - **Copy it immediately** (you can't see it again!)
   - Paste into app

4. **Enter Device Name:**
   - Any name to identify this iPhone
   - Example: "Andrei's iPhone", "Living Room iPhone"

5. **Test Connection:**
   - Tap "Test Connection" button
   - Should show green checkmark: "Connection successful!"

6. **If Test Fails:**
   - Check URL is correct (no typos, includes https://)
   - Verify token was copied completely (no spaces)
   - Ensure Nabu Casa subscription is active
   - Try accessing HA via browser using the same URL

---

### 3. Plant Shows "Never Watered"

**Symptoms:**
- Added plant
- Tapped water button or scanned NFC
- Still shows "Never watered"

**Possible Causes:**

**A. HA Not Configured**
- See #2 above
- Must have URL, token, and device name

**B. Helper Not Created in HA**
- The app auto-creates helpers, but check if it succeeded
- In Home Assistant: Settings → Devices & Services → Helpers
- Search for your plant name (e.g., "Pahira")
- Should see "Pahira Last Watered"

**C. Helper Creation Failed**
- Check Xcode console for:
  ```
  ⚠️ Failed to create helper for Pahira: [error message]
  ```
- Common errors:
  - Invalid token → Recreate in HA
  - Network error → Check internet
  - API disabled → Check HA config

**Manual Helper Creation (Fallback):**
1. In HA: Settings → Devices & Services → Helpers
2. Click "+ Create Helper"
3. Select "Date and/or time"
4. Configure:
   - Name: "Pahira Last Watered"
   - Entity ID: `input_datetime.plant_pahira_last_watered`
   - ✅ Has date
   - ✅ Has time
5. Save

---

### 4. NFC Tag Not Reading

**Symptoms:**
- Hold phone near tag
- Nothing happens or "Invalid tag" error

**Solutions:**

1. **Check NFC Availability:**
   - Must be iPhone 7 or newer
   - NFC works on all modern iPhones

2. **Proper Scanning Technique:**
   - Tap "Scan Tag" button first
   - Hold iPhone near tag for 2-3 seconds
   - Keep steady (don't move)
   - Remove thick phone cases

3. **Tag Position:**
   - NFC antenna is at top of iPhone (near camera)
   - Hold that area near the sticker
   - Try different angles

4. **Tag Quality:**
   - Use NTAG213/215/216 tags
   - Cheap tags might be defective
   - Try a different sticker

5. **Tag Not Written:**
   - Tag might be blank
   - Write to it first via plant detail view

---

### 5. Watering Logs Locally But Not in HA

**Symptoms:**
- App shows success message
- Message says "saved locally"
- HA helper doesn't update

**Causes:**

**A. No Internet Connection**
- App queues events for later sync
- Connect to WiFi/cellular
- Pull to refresh in Plants tab to retry

**B. HA Helper Doesn't Exist**
- Auto-creation might have failed
- Create manually (see #3 above)

**C. Invalid Token**
- Token might have expired
- Recreate in HA
- Update in Settings

**D. HA Instance Down**
- Check if you can access HA via browser
- Wait for HA to come back online
- Pull to refresh to retry

---

### 6. Multiple Plants, Only Some Update in HA

**Symptoms:**
- Some plants sync to HA fine
- Others always fail

**Solution:**
- Check which helpers exist in HA
- For failing plants, manually create their helpers
- Entity ID format: `input_datetime.plant_{plant_id}_last_watered`

---

### 7. App Won't Install on iPhone

**Symptoms:**
- Build succeeds in Xcode
- App installs but won't launch

**Solutions:**

1. **Trust Developer Certificate:**
   - Settings → General → VPN & Device Management
   - Tap your Apple ID under Developer App
   - Tap Trust
   - Try launching app again

2. **iOS Version Too Old:**
   - App requires iOS 17.0+
   - Update iPhone or lower deployment target in Xcode

3. **Bundle ID Conflict:**
   - Another app might use same ID
   - Change in Xcode: Project → General → Bundle Identifier

---

### 8. Notifications Not Appearing

**Symptoms:**
- Watered plant
- No notification when due

**Solutions:**

1. **Enable in App:**
   - Settings tab → Watering Reminders toggle on

2. **Grant iOS Permission:**
   - When prompted, tap "Allow"
   - Or: iPhone Settings → AquaTag → Notifications → Allow

3. **Check Reminder Time:**
   - Settings → Reminder Time
   - Notifications appear at this time on the due date

4. **Watering Due:**
   - Notification only appears when plant is actually due
   - Example: 7-day interval → notification in 7 days

---

## Debug Checklist

When something goes wrong, check these in order:

### 1. Xcode Console Logs
Look for these emojis:
- 📡 NFC operations
- 🏷️ Tag parsing
- 🔍 Database queries
- ✅ Success messages
- ⚠️ Warnings
- ❌ Errors

### 2. Settings Configured
- [ ] Nabu Casa URL entered
- [ ] Long-Lived Access Token entered
- [ ] Device Name entered
- [ ] Test Connection succeeds (green checkmark)

### 3. Home Assistant Helpers
- [ ] Can access HA via browser
- [ ] Helpers exist for each plant
- [ ] Entity IDs match exactly

### 4. Plant Data
- [ ] Plant added successfully
- [ ] Plant has valid ID (check entity ID in detail view)
- [ ] NFC tag written (if using tags)

### 5. Network
- [ ] iPhone has internet connection
- [ ] Can access Nabu Casa URL from browser on phone
- [ ] HA instance is online

---

## Getting Help

### Information to Provide:

When asking for help, include:

1. **Xcode Console Output:**
   - Copy lines with 📡, 🏷️, ✅, ⚠️, ❌ emojis
   
2. **Exact Error Message:**
   - Screenshot or copy text
   
3. **What You Did:**
   - Step-by-step actions before error
   
4. **Settings:**
   - HA URL format (redact specific domain)
   - Token present? (don't share actual token!)
   - Device name entered?
   
5. **Plant Info:**
   - Plant name
   - Generated plant ID
   - Expected HA entity ID

### Example Good Bug Report:

```
**Issue:** App crashes when scanning NFC tag

**Steps:**
1. Created plant "Monstera"
2. Wrote to NFC tag successfully
3. Tapped "Scan Tag"
4. Held phone near tag
5. App closed immediately

**Console Output:**
📡 NFC Raw payload bytes: 02 65 6e ...
🏷️ Raw scanned NFC data: 'aquatag:monstera'
🏷️ Cleaned plant ID: 'monstera'
❌ No plant found with ID 'monstera'

**Settings:**
✅ HA URL: https://*****.ui.nabu.casa
✅ Token: Present
✅ Device name: "My iPhone"
✅ Test connection: Success

**Plant:**
Name: Monstera
Entity ID shown: input_datetime.plant_monstera_last_watered
```

---

## Known Limitations

### v1.0 Limitations:
- ✅ Helpers auto-created, but **not auto-deleted** when plant removed
- ✅ History tab shows **local data only** (not from HA)
- ✅ Offline sync retries **on app launch**, not continuously
- ✅ No iCloud sync between devices
- ✅ Can't edit plant ID after creation

### Workarounds:
- **Delete helpers manually** if you delete a plant
- **Pull to refresh** to sync from HA
- **Keep app open** briefly after watering to ensure sync
- **Each device tracks independently** (by design for multi-user)
- **Delete and recreate** plant if wrong ID generated

---

## Advanced Debugging

### Enable Detailed Logging:

In Xcode, set environment variable:
1. Product → Scheme → Edit Scheme
2. Run → Arguments → Environment Variables
3. Add: `DEBUG_LOGGING` = `1`

### Check HA API Directly:

Test API with curl:

```bash
# Test connection
curl -X GET "https://YOUR-ID.ui.nabu.casa/api/" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check helper exists
curl -X GET "https://YOUR-ID.ui.nabu.casa/api/states/input_datetime.plant_pahira_last_watered" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Update helper manually
curl -X POST "https://YOUR-ID.ui.nabu.casa/api/services/input_datetime/set_datetime" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "entity_id": "input_datetime.plant_pahira_last_watered",
    "datetime": "2026-04-10T14:30:00"
  }'
```

---

**Still stuck?** Check the console logs and match them to the troubleshooting steps above!
