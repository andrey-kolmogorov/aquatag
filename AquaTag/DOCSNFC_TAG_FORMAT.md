# AquaTag NFC Tag Format

## NDEF Text Record Format

Each AquaTag NFC sticker contains a standard NDEF (NFC Data Exchange Format) Text Record.

### Payload Structure

```
aquatag:{plant_id}
```

### Examples

```
aquatag:monstera
aquatag:cactus_windowsill
aquatag:orchid_bathroom
aquatag:ficus_living_room
```

## Plant ID Generation Rules

Plant IDs are automatically generated from plant names using these rules:

1. Convert to lowercase
2. Replace spaces and special characters with underscores
3. Remove leading/trailing underscores
4. If empty, generate random ID

### Examples

| Plant Name | Generated ID |
|------------|-------------|
| Monstera Deliciosa | `monstera_deliciosa` |
| Cactus (Windowsill) | `cactus_windowsill` |
| Snake Plant #1 | `snake_plant_1` |
| Fern | `fern` |

## Home Assistant Entity IDs

Each plant corresponds to an HA entity following this pattern:

```
input_datetime.plant_{plant_id}_last_watered
```

### Examples

| Plant ID | HA Entity ID |
|----------|--------------|
| `monstera_deliciosa` | `input_datetime.plant_monstera_deliciosa_last_watered` |
| `cactus_windowsill` | `input_datetime.plant_cactus_windowsill_last_watered` |
| `fern` | `input_datetime.plant_fern_last_watered` |

## Manual Tag Writing (Optional)

If you want to write tags using another NFC app before using AquaTag:

1. Create an NDEF Text Record
2. Set language to `en` (English)
3. Set text content to: `aquatag:{your_plant_id}`
4. Write to NTAG213/215/216 sticker

**Note:** AquaTag can write tags for you, so manual writing is optional.

## Tag Recommendations

### Compatible Tag Types
- ✅ NTAG213 (144 bytes) — Recommended
- ✅ NTAG215 (504 bytes)
- ✅ NTAG216 (888 bytes)
- ✅ Any NDEF-compatible NFC Forum Type 2 tag

### Size Recommendations
- **30mm round** — Best for most plant pots
- **25mm round** — Smaller pots
- **40mm round** — Large planters

### Placement Tips
- Clean and dry the pot surface
- Avoid areas that will be frequently touched
- Keep away from water contact if possible
- Test scan after placement

## Reading Tags Manually

You can read AquaTag tags with iOS Shortcuts or any NFC reader app:

1. Open iPhone's built-in NFC reader (Control Center on iPhone XR+)
2. Scan the tag
3. You'll see the plant ID in plain text

This is useful for:
- Verifying tag contents
- Troubleshooting
- Creating custom automations

## Security Considerations

- Tags contain **public, plain-text data** (plant IDs only)
- No sensitive information stored on tags
- Tags can be read by anyone with NFC-capable device
- Authentication happens via HA token, not NFC tags

## Tag Lifecycle

### Writing
1. User adds plant in app
2. App generates unique plant ID
3. User taps "Write to NFC Tag" in plant detail
4. App writes `aquatag:{plant_id}` to tag
5. Tag is associated with the plant

### Reading
1. User taps "Scan Tag" button
2. App reads NDEF payload
3. Extracts plant ID from `aquatag:` prefix
4. Looks up plant in local database
5. Logs watering if found, or prompts registration

### Rewriting
- Tags can be rewritten if a plant is renamed
- Old tags can be reused for different plants
- No lock/protect mechanism (tags remain writable)

## Troubleshooting

### Tag Not Reading
- Ensure tag is NDEF-formatted
- Check tag is not damaged or demagnetized
- Remove thick phone cases
- Hold iPhone steady for 2-3 seconds

### Wrong Plant ID Read
- Tag may have been written by another app
- Rewrite using AquaTag's "Write to NFC Tag" feature
- Verify format is exactly `aquatag:{id}` with no extra characters

### Tag Reads But Plant Not Found
- Plant may not be registered in app yet
- Tap "Register Plant" when prompted
- Check plant ID matches what was written to tag

---

For more information, see README.md
