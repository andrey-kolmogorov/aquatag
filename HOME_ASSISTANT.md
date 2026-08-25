# AquaTag + Home Assistant

A standalone iOS plant tracker would be… fine. But the moment every NFC tap goes into Home Assistant, the same primitive — *"a person watered a specific plant at a specific time"* — composes with everything else in your home: soil moisture sensors, weather forecasts, presence detection, voice assistants, dashboards. That's where AquaTag stops being a plant log and starts being **plant-aware home automation**.

This guide covers:

- [Setup](#setup) — connecting AquaTag to your HA instance
- [What AquaTag creates and emits](#what-aquatag-creates-and-emits) — entities, events, and the wire format
- [What you can build](#what-you-can-build) — copy-pasteable automation cookbook
- [Troubleshooting](#troubleshooting) — when things don't work
- [Contributing automations](#contributing-automations) — share what you've built

---

## Setup

### 1. Generate a Long-Lived Access Token

In Home Assistant: **Profile → Security → Long-Lived Access Tokens → Create Token**. Copy it immediately — you can't view it again later.

### 2. Confirm Nabu Casa remote access

AquaTag connects via your Nabu Casa cloud URL (e.g. `https://abc123xyz.ui.nabu.casa`). Local-network-only connections aren't currently supported — the goal is "tap NFC tag → log immediately, regardless of where you are."

### 3. Configure AquaTag

1. Open AquaTag → **Settings**.
2. Paste the Nabu Casa URL.
3. Paste the access token.
4. Set a device name — this identifies *who* watered (e.g. "Andrei's iPhone", "Anya's iPhone"). Useful in multi-device households.
5. Tap **Test Connection**. If green, you're done.

### 4. Add your first plant

In AquaTag, tap `+` in the Plants tab and fill in name, emoji, and watering interval. AquaTag opens a WebSocket to HA and creates an `input_datetime` helper for that plant — no manual entity setup needed in HA's UI.

If a matching helper already exists (you re-added a plant, or you're upgrading from an older install), AquaTag **adopts** it instead of creating a second one, so the existing watering history is preserved. **Settings → HA Helper Cleanup** lists every `input_datetime` helper in your instance alongside which plant claims it, and lets you delete the ones nothing is using.

---

## What AquaTag creates and emits

### Entities created automatically

For each plant you add, AquaTag creates one helper:

| Entity ID | Type | Purpose |
|---|---|---|
| `input_datetime.{slug}_last_watered` | `input_datetime` | Timestamp of the most recent watering |

The helper is created with the name **`{Plant name} Last Watered`**, and Home Assistant derives the entity ID by slugifying that name — so *"Fiddle Leaf Fig"* becomes `input_datetime.fiddle_leaf_fig_last_watered`.

Two consequences worth knowing before you write automations against these:

- **The exact ID is HA's to choose, not AquaTag's.** If the name collides with an existing helper, HA appends a suffix (`..._last_watered_2`). AquaTag reads the assigned ID back and stores it, so it always addresses the right entity — but you shouldn't assume the ID from the plant name alone.
- **Match on the `_last_watered` suffix, not on a prefix.** Every example below enumerates helpers that way, which is stable regardless of what HA named them.

> **Upgrading from before v1.1.0?** Earlier docs described these entities as `input_datetime.plant_{id}_last_watered`. That prefixed form was never actually produced — it was a bug, and any automation filtering on `input_datetime.plant_` silently matched nothing. The examples below are corrected. AquaTag links to your existing helpers automatically on first refresh; nothing to migrate by hand.

### Events fired on every tap

Every NFC tap fires:

```
event_type: aquatag_plant_watered
event_data:
  plant_id: "monstera"
  plant_name: "Monstera Deliciosa"
  device_name: "Andrei's iPhone"
  timestamp: "2026-08-25T13:16:53.421+02:00"
```

Those four fields are the whole payload. `timestamp` is ISO 8601 with an offset — unlike the `input_datetime` state, which is local wall-clock.

This is your hook for any automation. You don't need to read the `input_datetime` to *know* a watering happened — listen for the event. The `input_datetime` exists so you can answer *"when was the last time?"* on demand.

### REST/WebSocket API used

For reference, AquaTag talks to HA via:

- `POST /api/services/input_datetime/set_datetime` — update last-watered timestamp on tap
- `POST /api/events/aquatag_plant_watered` — fire the event
- `GET /api/states` — read every helper's current value on refresh, and match unlinked plants to existing helpers
- `wss://.../api/websocket` → `input_datetime/create` — create a helper when a plant is added
- `wss://.../api/websocket` → `input_datetime/list` — find helpers to adopt, and populate the cleanup screen
- `wss://.../api/websocket` → `input_datetime/delete` — remove helpers from the cleanup screen

Note that `set_datetime` takes a **timezone-naive local** timestamp (`2026-08-25 12:12:32`), not ISO 8601. Sending an ISO string with a `Z` suffix makes HA keep the UTC digits and drop the offset, recording the watering hours early.

---

## What you can build

A cookbook of automations that actually work, ordered roughly by complexity. Copy, paste, adapt entity IDs to your actual plant names, restart automations.

> Throughout these examples, replace `notify.mobile_app_andrei_iphone`, `weather.home`, `media_player.kitchen_sonos`, etc. with whatever your entities are actually called.

### 1. Logbook everything

The simplest possible automation — every watering shows up in your HA logbook with who did it.

```yaml
automation:
  - alias: "AquaTag — log to logbook"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: logbook.log
        data:
          name: "{{ trigger.event.data.plant_name }}"
          message: "watered by {{ trigger.event.data.device_name }}"
```

### 2. Morning briefing — what needs water today

A daily notification listing only the plants that are overdue, parsed from the helper entity IDs.

```yaml
automation:
  - alias: "AquaTag — morning briefing"
    trigger:
      - platform: time
        at: "08:00:00"
    action:
      - variables:
          due_plants: >-
            {% set ns = namespace(plants=[]) %}
            {% for entity in states.input_datetime
                if entity.entity_id.endswith('_last_watered') %}
              {% set last = as_datetime(entity.state) | as_local %}
              {% set days = (now() - last).days %}
              {% if days >= 7 %}
                {% set name = entity.entity_id
                  | regex_replace('^input_datetime\\.', '')
                  | regex_replace('_last_watered$', '')
                  | replace('_', ' ') | title %}
                {% set ns.plants = ns.plants + [name] %}
              {% endif %}
            {% endfor %}
            {{ ns.plants }}
      - condition: template
        value_template: "{{ due_plants | length > 0 }}"
      - service: notify.mobile_app_andrei_iphone
        data:
          title: "🌱 Plants needing water"
          message: "{{ due_plants | length }} overdue: {{ due_plants | join(', ') }}"
```

> **Why the `| as_local`?** `input_datetime` state strings are timezone-naive, but `now()` is timezone-aware. Subtracting them raises `TypeError` silently — the template renders empty and no notification fires. Piping through `as_local` attaches the local timezone so the subtraction works. Applies to every template in this cookbook that does `now() - as_datetime(...)` arithmetic.

The `7` is a fallback threshold — adjust to whatever your shortest watering interval is, or build a more sophisticated per-plant version using their individual interval values.

### 3. Skip outdoor reminders when rain is forecast

For balcony / outdoor plants. Uses the [met.no](https://www.home-assistant.io/integrations/met/) integration's forecast.

Since HA 2024, weather entities **no longer expose a `forecast` attribute** — you have to call the `weather.get_forecasts` service and capture the response. Both conditions therefore live inside `action:` (a condition step inside actions bails out of the sequence the same way a top-level failing condition does):

```yaml
automation:
  - alias: "AquaTag — outdoor reminder unless rain"
    trigger:
      - platform: time
        at: "09:00:00"
    action:
      # Plant is overdue (uses the timestamp attribute, avoiding the naive/aware datetime gotcha)
      - condition: template
        value_template: >-
          {% set ts = state_attr('input_datetime.balcony_basil_last_watered', 'timestamp') %}
          {{ ts is not none and ((now().timestamp() - ts) / 86400) >= 2 }}
      # Fetch daily forecast into a variable
      - service: weather.get_forecasts
        target:
          entity_id: weather.home
        data:
          type: daily
        response_variable: forecast_response
      # No meaningful rain in the next 24h
      - condition: template
        value_template: >-
          {{ forecast_response['weather.home'].forecast[0].precipitation | float(0) < 2 }}
      - service: notify.mobile_app_andrei_iphone
        data:
          title: "Balcony basil 🌿"
          message: "No rain expected today — time to water."
```

### 4. Sensor fusion — anomaly detection with soil moisture

This is where AquaTag stops being a plant tracker and starts being plant-*aware*. Combine the watering log (what *you* did) with a soil moisture sensor (what the *plant* feels) to detect when something's wrong.

Requires a moisture sensor entity — Xiaomi Mi Flora, an ESPHome custom probe, anything reporting on `sensor.{plant}_soil_moisture`.

The dryness rate is a **template sensor**. HA now recommends creating these as **Template Helpers** via the UI (*Settings → Devices & Services → Helpers → Create Helper → Template → Sensor*) rather than as YAML — the UI variant is reloadable without restarting HA and shows up in the helper registry. Both variants have identical semantics; the YAML below is preserved for readability. Whichever you use, paste this `state:` template:

```jinja
{% set ts = state_attr('input_datetime.monstera_last_watered', 'timestamp') %}
{% if ts is none %}
  0
{% else %}
  {% set hours = (now().timestamp() - ts) / 3600 %}
  {% set moisture = states('sensor.monstera_soil_moisture') | float(0) %}
  {% if hours > 6 %}
    {{ ((100 - moisture) / hours * 24) | round(1) }}
  {% else %}
    0
  {% endif %}
{% endif %}
```

Unit of measurement: `%/day`.

YAML equivalent:

```yaml
template:
  - sensor:
      - name: "Monstera dryness rate"
        unique_id: monstera_dryness_rate
        unit_of_measurement: "%/day"
        state: >-
          {% set ts = state_attr('input_datetime.monstera_last_watered', 'timestamp') %}
          {% if ts is none %}
            0
          {% else %}
            {% set hours = (now().timestamp() - ts) / 3600 %}
            {% set moisture = states('sensor.monstera_soil_moisture') | float(0) %}
            {% if hours > 6 %}
              {{ ((100 - moisture) / hours * 24) | round(1) }}
            {% else %}
              0
            {% endif %}
          {% endif %}

automation:
  - alias: "Monstera drying faster than usual"
    trigger:
      - platform: numeric_state
        entity_id: sensor.monstera_dryness_rate
        above: 15  # tune to your plant — typical Monstera ~5–10
        for:
          hours: 12
    action:
      - service: notify.mobile_app_andrei_iphone
        data:
          title: "Monstera 🪴"
          message: >-
            Drying faster than usual ({{ states('sensor.monstera_dryness_rate') }}%/day).
            Drainage? Heat? Worth a look.
```

### 5. Multi-device household coordination

When two people share a household and both have AquaTag, you don't want both to get reminders if either has watered. Clear the matching pending notification on both devices when the event fires.

```yaml
automation:
  - alias: "AquaTag — clear partner's reminder when watered"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: notify.mobile_app_anya_iphone
        data:
          message: clear_notification
          data:
            tag: "watering_{{ trigger.event.data.plant_id }}"
      - service: notify.mobile_app_andrei_iphone
        data:
          message: clear_notification
          data:
            tag: "watering_{{ trigger.event.data.plant_id }}"
```

This pairs with using the same `tag` field when you originally send the reminder — that's how iOS knows which notification to clear.

> **Important — use the legacy `notify.mobile_app_<device>` service here, not the modern `notify.send_message`.** The nested `data: { tag: ... }` clear-notification payload is Companion-app–specific and only accepted by the per-device notify service. `notify.send_message` will reject it with `extra keys not allowed @ data['data']`.

### 6. Vacation dashboard for the plant sitter

A markdown card you can drop into a dashboard, showing each plant's last-watered date. When you're away for two weeks, share the dashboard URL with whoever's watering. No app needed on their side.

```yaml
type: markdown
title: 🌱 Plant care while we're away
content: |
  {% for entity in states.input_datetime
       if entity.entity_id.endswith('_last_watered') %}
    {%- set last = as_datetime(entity.state) | as_local -%}
    {%- set days_ago = (now() - last).days -%}
    {%- set name = entity.entity_id
        | regex_replace('^input_datetime\.', '')
        | regex_replace('_last_watered$', '')
        | replace('_', ' ') | title -%}
    - **{{ name }}**: last watered {{ days_ago }} day{{ 's' if days_ago != 1 else '' }} ago
  {% endfor %}
```

### 7. Voice announcement via Sonos / Alexa / Google

Morning summary spoken on a chosen speaker — only when you're actually home.

```yaml
automation:
  - alias: "AquaTag — morning voice briefing"
    trigger:
      - platform: time
        at: "08:00:00"
    condition:
      - condition: state
        entity_id: person.andrei
        state: home
    action:
      # Modern TTS pattern (2024+): target the TTS engine entity, pass the media_player in data.
      - service: tts.speak
        target:
          entity_id: tts.home_assistant_cloud
        data:
          media_player_entity_id: media_player.kitchen_sonos
          message: >-
            {% set ns = namespace(due=[]) %}
            {% for entity in states.input_datetime
                 if entity.entity_id.endswith('_last_watered') %}
              {% set last = as_datetime(entity.state) | as_local %}
              {% if (now() - last).days >= 7 %}
                {% set name = entity.entity_id
                    | regex_replace('^input_datetime\\.', '')
                    | regex_replace('_last_watered$', '')
                    | replace('_', ' ') %}
                {% set ns.due = ns.due + [name] %}
              {% endif %}
            {% endfor %}
            {% if ns.due | length > 0 %}
              {{ ns.due | length }} plant{{ 's' if ns.due | length > 1 else '' }} need{{ 's' if ns.due | length == 1 else '' }} water today: {{ ns.due | join(', ') }}.
            {% else %}
              All plants are happy today.
            {% endif %}
```

If you use Google Translate TTS instead of HA Cloud, swap `tts.home_assistant_cloud` for `tts.google_translate_en_com` (or whatever your engine entity is called).

### 8. Trigger physical irrigation from the tap

If you have a Shelly relay driving a balcony watering pump, the NFC tap can do double duty — log the watering *and* run the pump. Now the same primitive becomes the interface for actual watering hardware.

```yaml
automation:
  - alias: "AquaTag — balcony tap also runs pump"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
        event_data:
          plant_id: "balcony_pot"
    action:
      - service: switch.turn_on
        target:
          entity_id: switch.balcony_pump
      - delay: "00:01:30"  # 90 seconds
      - service: switch.turn_off
        target:
          entity_id: switch.balcony_pump
```

---

## Troubleshooting

**Watering doesn't appear in HA after a tap.**

- Settings → Test Connection in AquaTag — does it return green?
- Has the Long-Lived Access Token been revoked in HA? They don't expire, but you can revoke them.
- Does a helper named `{Plant name} Last Watered` exist? Check **Settings → HA Helper Cleanup** in AquaTag — it lists every `input_datetime` helper in your instance and shows which plant, if any, is linked to it. A plant with no linked helper appears as "Not linked yet" in the Plant Helpers section above it.
- If the plant shows as unlinked, pull to refresh on the Plants tab. AquaTag will adopt a matching helper or create one.

**The `aquatag_plant_watered` event doesn't fire.**

- Open **Developer Tools → Events** in HA, listen for `aquatag_plant_watered`, and tap a tag. Does anything show up?
- If `input_datetime` updates but the event doesn't fire, that's a partial-success scenario worth filing as an issue with logs.

**Adding a plant doesn't auto-create the helper.**

- Some HA configurations restrict WebSocket creation of helpers via API. Check `configuration.yaml` for any `homeassistant: allowlist_external_dirs` or auth_provider restrictions, and check the HA log for permission errors when you tap "Add plant" in AquaTag.

**I have duplicate helpers for the same plant.**

- Versions before v1.1.0 created a new helper on every sync attempt instead of reusing the existing one, so a single plant could accumulate several (`cactus_last_watered`, `..._2`, `..._3`).
- Open **Settings → HA Helper Cleanup** and scan. Each helper shows its last-watered date, which is usually what tells the duplicates apart. Tick the ones you don't want and delete. The helper your plant is currently linked to is locked and can't be selected, so you can't remove the live one by accident.
- Deleting a helper also removes its history from HA's recorder, so pick the one holding the dates you want to keep.

**My automations stopped matching anything after upgrading.**

- If they filter on `input_datetime.plant_`, they never matched — see the note in [Entities created automatically](#entities-created-automatically). Switch to the `_last_watered` suffix form used throughout this cookbook.

---

## Contributing automations

If you build something useful on top of AquaTag, PRs adding to this cookbook are very welcome. The format above (title, brief explanation of *why*, working YAML, called-out entity assumptions) is what to mirror. Untested examples will be merged with a "verified by author" caveat — so if you've run it on your own HA for at least a week, mention that in the PR.

Some directions worth exploring that aren't here yet:

- Per-plant dynamic intervals (read each plant's stored interval rather than the hardcoded 7-day fallback)
- Long-term Grafana / InfluxDB dashboards for watering frequency vs. season
- Integrations with smart pots / capillary watering systems
- Children-as-plant-helpers gamification dashboards
- Image-recognition triggers (camera sees a wilting plant → cross-reference last-watered → push reminder)
