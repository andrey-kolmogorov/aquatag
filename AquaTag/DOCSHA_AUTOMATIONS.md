# Home Assistant Automation Examples

This document provides example automations you can create in Home Assistant to extend AquaTag functionality.

## Required Helpers (Per Plant)

For each plant, create an `input_datetime` helper:

```yaml
input_datetime:
  plant_monstera_last_watered:
    name: "Monstera Last Watered"
    has_date: true
    has_time: true
    
  plant_cactus_last_watered:
    name: "Cactus Last Watered"
    has_date: true
    has_time: true
```

**Important**: Entity IDs must match the format shown in the AquaTag app:
```
input_datetime.plant_{plant_id}_last_watered
```

## Example 1: Log to Logbook

Log all watering events to Home Assistant's logbook:

```yaml
automation:
  - alias: "AquaTag: Log Watering to Logbook"
    description: "Add watering events to the logbook"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: logbook.log
        data:
          name: "{{ trigger.event.data.plant_name }}"
          message: "Watered by {{ trigger.event.data.device_name }}"
          entity_id: "input_datetime.plant_{{ trigger.event.data.plant_id }}_last_watered"
```

## Example 2: Persistent Notification

Show a persistent notification in HA when a plant is watered:

```yaml
automation:
  - alias: "AquaTag: Notify on Watering"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: persistent_notification.create
        data:
          title: "🌿 Plant Watered"
          message: >
            {{ trigger.event.data.plant_emoji }} {{ trigger.event.data.plant_name }}
            was watered by {{ trigger.event.data.device_name }}
            at {{ trigger.event.data.timestamp | as_timestamp | timestamp_custom('%I:%M %p') }}
          notification_id: "aquatag_{{ trigger.event.data.plant_id }}"
```

## Example 3: Slack/Discord Notification

Send watering events to Slack or Discord:

```yaml
automation:
  - alias: "AquaTag: Send to Slack"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: notify.slack
        data:
          message: >
            :potted_plant: *{{ trigger.event.data.plant_name }}* was watered
            by {{ trigger.event.data.device_name }}
          data:
            blocks:
              - type: section
                text:
                  type: mrkdwn
                  text: >
                    :potted_plant: *{{ trigger.event.data.plant_name }}*
                    watered by *{{ trigger.event.data.device_name }}*
```

## Example 4: Track Watering Streak

Count consecutive days of watering (for daily plants):

```yaml
input_number:
  monstera_watering_streak:
    name: "Monstera Watering Streak"
    min: 0
    max: 365
    step: 1

automation:
  - alias: "AquaTag: Update Watering Streak"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
        event_data:
          plant_id: "monstera"
    action:
      - choose:
          - conditions:
              - condition: template
                value_template: >
                  {{ (as_timestamp(now()) - as_timestamp(states('input_datetime.plant_monstera_last_watered'))) < 86400 * 2 }}
            sequence:
              - service: input_number.increment
                target:
                  entity_id: input_number.monstera_watering_streak
        default:
          - service: input_number.set_value
            target:
              entity_id: input_number.monstera_watering_streak
            data:
              value: 1
```

## Example 5: Overdue Watering Alert

Alert in HA if a plant is overdue for watering:

```yaml
template:
  - binary_sensor:
      - name: "Monstera Needs Watering"
        state: >
          {% set last_watered = states('input_datetime.plant_monstera_last_watered') %}
          {% set watering_interval = 7 %}  # days
          {% if last_watered not in ['unknown', 'unavailable'] %}
            {{ (as_timestamp(now()) - as_timestamp(last_watered)) > (watering_interval * 86400) }}
          {% else %}
            true
          {% endif %}

automation:
  - alias: "AquaTag: Alert Overdue Watering"
    trigger:
      - platform: state
        entity_id: binary_sensor.monstera_needs_watering
        to: "on"
    action:
      - service: notify.mobile_app
        data:
          title: "🚨 Plant Needs Water!"
          message: "Your Monstera is overdue for watering"
```

## Example 6: Daily Watering Summary

Send a daily summary of all plants that need water:

```yaml
automation:
  - alias: "AquaTag: Daily Watering Summary"
    trigger:
      - platform: time
        at: "08:00:00"
    action:
      - service: notify.mobile_app
        data:
          title: "🌿 Daily Plant Check"
          message: >
            {% set ns = namespace(plants=[]) %}
            {% for entity in states.input_datetime %}
              {% if 'plant_' in entity.entity_id and '_last_watered' in entity.entity_id %}
                {% set days_since = ((as_timestamp(now()) - as_timestamp(entity.state)) / 86400) | int %}
                {% if days_since > 7 %}
                  {% set plant_name = entity.name.replace(' Last Watered', '') %}
                  {% set ns.plants = ns.plants + [plant_name + ' (' + days_since|string + ' days)'] %}
                {% endif %}
              {% endif %}
            {% endfor %}
            {% if ns.plants %}
              Plants needing water: {{ ns.plants | join(', ') }}
            {% else %}
              All plants are watered! 🎉
            {% endif %}
```

## Example 7: Smart Home Integration

Flash lights when a plant is watered (fun notification):

```yaml
automation:
  - alias: "AquaTag: Flash Lights on Watering"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: light.turn_on
        target:
          entity_id: light.living_room
        data:
          color_name: green
          brightness: 255
      - delay:
          seconds: 1
      - service: light.turn_off
        target:
          entity_id: light.living_room
      - delay:
          seconds: 1
      - service: light.turn_on
        target:
          entity_id: light.living_room
```

## Example 8: Statistics Tracking

Track total waterings per plant:

```yaml
sensor:
  - platform: history_stats
    name: "Monstera Waterings This Month"
    entity_id: input_datetime.plant_monstera_last_watered
    state: "on"
    type: count
    start: "{{ now().replace(day=1, hour=0, minute=0, second=0) }}"
    end: "{{ now() }}"
```

## Example 9: Voice Announcement

Announce watering events via Google Home or Alexa:

```yaml
automation:
  - alias: "AquaTag: Voice Announcement"
    trigger:
      - platform: event
        event_type: aquatag_plant_watered
    action:
      - service: tts.google_translate_say
        target:
          entity_id: media_player.living_room_speaker
        data:
          message: >
            {{ trigger.event.data.plant_name }} has been watered
            by {{ trigger.event.data.device_name }}
```

## Example 10: Dashboard Card

Create a Lovelace dashboard card showing all plants:

```yaml
type: entities
title: 🌿 Plant Watering Status
entities:
  - entity: input_datetime.plant_monstera_last_watered
    name: Monstera
    secondary_info: last-changed
  - entity: input_datetime.plant_cactus_last_watered
    name: Cactus
    secondary_info: last-changed
  - entity: input_datetime.plant_fern_last_watered
    name: Fern
    secondary_info: last-changed
state_color: true
```

## Example 11: Watering History Graph

Create a graph showing watering frequency:

```yaml
type: history-graph
title: Watering History
entities:
  - entity: input_datetime.plant_monstera_last_watered
    name: Monstera
  - entity: input_datetime.plant_cactus_last_watered
    name: Cactus
hours_to_show: 168  # 7 days
refresh_interval: 60
```

## Example 12: Automated Irrigation Trigger (Future)

Trigger smart irrigation based on AquaTag data:

```yaml
automation:
  - alias: "AquaTag: Auto-Water Integration"
    description: "Trigger irrigation system when plant needs water"
    trigger:
      - platform: template
        value_template: >
          {% set last_watered = states('input_datetime.plant_outdoor_garden_last_watered') %}
          {% if last_watered not in ['unknown', 'unavailable'] %}
            {{ (as_timestamp(now()) - as_timestamp(last_watered)) > (3 * 86400) }}
          {% else %}
            false
          {% endif %}
    condition:
      - condition: state
        entity_id: switch.irrigation_system
        state: "off"
    action:
      - service: switch.turn_on
        target:
          entity_id: switch.irrigation_system
      - delay:
          minutes: 5
      - service: switch.turn_off
        target:
          entity_id: switch.irrigation_system
      - service: input_datetime.set_datetime
        target:
          entity_id: input_datetime.plant_outdoor_garden_last_watered
        data:
          datetime: "{{ now().isoformat() }}"
```

## Event Data Structure

All `aquatag_plant_watered` events contain this data:

```json
{
  "plant_id": "monstera_deliciosa",
  "plant_name": "Monstera Deliciosa",
  "device_name": "Andrei's iPhone",
  "timestamp": "2026-04-05T14:30:00.000Z"
}
```

You can access this in automations via:
- `{{ trigger.event.data.plant_id }}`
- `{{ trigger.event.data.plant_name }}`
- `{{ trigger.event.data.device_name }}`
- `{{ trigger.event.data.timestamp }}`

## Debugging Event Listeners

To see AquaTag events in real-time:

1. Go to **Developer Tools** → **Events**
2. Enter event type: `aquatag_plant_watered`
3. Click **Start Listening**
4. Water a plant with AquaTag
5. See the event data appear

## Tips for Creating Automations

1. **Test with one plant first** before creating automations for all plants
2. **Use templates** to make automations work for any plant dynamically
3. **Add conditions** to prevent unwanted triggers
4. **Use traces** in HA to debug automation issues
5. **Document your automations** with descriptions

## Advanced: Custom Lovelace Card

Create a custom plant watering card using card-mod or custom cards:

```yaml
type: custom:button-card
entity: input_datetime.plant_monstera_last_watered
name: Monstera
icon: mdi:sprout
show_state: true
state_display: |
  [[[
    const lastWatered = new Date(entity.state);
    const now = new Date();
    const daysSince = Math.floor((now - lastWatered) / (1000 * 60 * 60 * 24));
    return `${daysSince} days ago`;
  ]]]
styles:
  card:
    - background-color: |
        [[[
          const lastWatered = new Date(entity.state);
          const now = new Date();
          const daysSince = Math.floor((now - lastWatered) / (1000 * 60 * 60 * 24));
          if (daysSince > 7) return 'rgba(255, 0, 0, 0.1)';
          if (daysSince > 5) return 'rgba(255, 165, 0, 0.1)';
          return 'rgba(0, 255, 0, 0.1)';
        ]]]
```

## Resources

- [Home Assistant Automation Docs](https://www.home-assistant.io/docs/automation/)
- [Template Syntax](https://www.home-assistant.io/docs/configuration/templating/)
- [Event Automation](https://www.home-assistant.io/docs/automation/trigger/#event-trigger)
- [Logbook](https://www.home-assistant.io/integrations/logbook/)

---

These are just examples — customize them to fit your Home Assistant setup and preferences!
