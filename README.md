# SBB Swiss Stationboard for TRMNL

A TRMNL e-ink display plugin showing live departure information for Swiss public transport stations (trains, trams, buses, ships, cable cars).

## Features

- **Live departure information** from any Swiss public transport station
- **Multiple layout variants** - optimized for full screen, half screen (horizontal/vertical), and quadrant displays
- **Smart filtering** - hide specific transport types, lines, or destinations
- **Walking time calculation** - shows when you need to leave to catch your connection
- **Delay tracking** - displays real-time delay information
- **Customizable display** - abbreviate destination names, hide words, filter by transport type
- **Icon-based transport types** - visual indicators for trains, trams, buses, ships, and cable cars

## Installation

### Prerequisites

You need the **TRMNL Developer edition** to use private plugins:
- Upgrade via the device picker dropdown → gear icon → "Developer perks"
- One-time fee of $20 (or included with Developer edition purchase)
- Free for BYOD (Bring Your Own Device) licenses

### Import the Plugin

1. Download the latest release ZIP file from this repository
2. Go to your [TRMNL Private Plugin settings page](https://usetrmnl.com/plugin_settings?keyname=private_plugin)
3. Click **"Import new"** and select the ZIP file
4. The plugin will be automatically added to your playlist
5. Copy the webhook URL from the plugin instance and send stationboard data to it

### Alternative: Manual Setup

If you prefer to set it up manually:

1. Create a new Private Plugin in TRMNL
2. Set the plugin strategy to **Webhook**
3. Copy the contents of `src/settings.yml` to your plugin settings
4. Copy each layout file (`src/full.liquid`, `src/half_horizontal.liquid`, etc.) to the corresponding layout in TRMNL
5. Copy `src/shared.liquid` content (TRMNL will automatically prepend this to each layout)

## Webhook Data

TRMNL does not fetch the Swiss OpenData Transport API for this plugin. Instead, fetch the stationboard yourself and POST it to the webhook URL from your TRMNL plugin instance.

The payload must put the API response under `merge_variables`:

```json
{
  "merge_variables": {
    "stationboard": [
      {
        "category": "IC",
        "number": "1",
        "to": "Basel SBB",
        "stop": {
          "departure": "2026-06-29T10:30:00+0200",
          "prognosis": {
            "departure": "2026-06-29T10:33:00+0200"
          }
        }
      }
    ]
  }
}
```

Use the helper script to fetch the optimized Swiss OpenData response and push it to TRMNL:

```bash
export TRMNL_WEBHOOK_URL="https://usetrmnl.com/api/custom_plugins/..."
export STATION_ID="8503000"
./scripts/push_stationboard.sh
```

`STATION_ID` defaults to Zürich HB (`8503000`) and `LIMIT` defaults to `12`. Keep the limit small because TRMNL webhook payloads are intentionally compact.

You can run the helper from cron, GitHub Actions, a small hosted worker, or any scheduler that can make outbound HTTP requests. Re-run it whenever you want fresh data on the next TRMNL refresh.

When publishing the plugin as a public recipe, push fake/demo stationboard data to the recipe master webhook and keep personal station choices in form fields.

## Configuration

### Find Your Station

Station IDs must be looked up via the Swiss OpenData Transport API:

```
https://transport.opendata.ch/v1/locations?query=Basel
```

**Common station IDs:**
- Zürich HB: `8503000`
- Bern: `8507000`
- Basel SBB: `8500010`
- Genève: `8501008`
- Lausanne: `8501120`

### Configuration Options

| Field | Description | Example |
|-------|-------------|---------|
| **Station Name** | Display name for your station | `Zürich HB` |
| **Station ID** | OpenData Transport station ID | `8503000` |
| **Walking Time** | Minutes to reach the station | `5` |
| **Min Departure Offset** | Hide departures less than N minutes away | `10` |
| **Hide Transport Types** | Filter by category or type | `bus, tram, IC` |
| **Filter Lines** | Hide specific line+destination combos | `11Auz, 14Tri` |
| **Hide Words** | Remove words from destination names | `Zürich, Bahnhof` |
| **Abbreviations** | Shorten destination names | `Bahnhof=Bhf.` |
| **Cableway Icon** | Preferred icon for cable cars | `Gondel` or `Zahnradbahn` |

### Filter Examples

**Hide all buses and trams:**
```
bus, tram
```

**Hide specific lines:**
- `11Auz` - Line 11 to Auzelg
- `14Tri` - Line 14 to Triemli
- Format: `{lineNumber}{first3CharsOfDestination}`

**Abbreviate destinations:**
```
Bahnhof=Bhf., Zürich=ZH, Hauptbahnhof=HB
```

## Data Source

This plugin uses the [Swiss OpenData Transport API](https://transport.opendata.ch):
- Real-time departure data
- Delay information
- Free, public API
- No authentication required

**API Optimization Tip:** To reduce payload size, request only the fields the template uses:

```text
https://transport.opendata.ch/v1/stationboard?id=8503000&limit=12&fields[]=stationboard/category&fields[]=stationboard/number&fields[]=stationboard/to&fields[]=stationboard/stop/departure&fields[]=stationboard/stop/prognosis/departure
```

## Architecture

### Files

- **`src/shared.liquid`** - Common code automatically prepended by TRMNL
  - Helper functions (data parsing, validation)
  - Category mapping
  - Text processing utilities
  - Main rendering function

- **Layout files** - Screen size specific templates
  - `src/full.liquid` - Full screen (9 larger departures)
  - `src/half_horizontal.liquid` - Half screen horizontal (4 compact departures)
  - `src/half_vertical.liquid` - Half screen vertical (8 compact departures)
  - `src/quadrant.liquid` - Quarter screen (4 compact departures)

- **`src/settings.yml`** - Plugin configuration and custom fields
- **`scripts/push_stationboard.sh`** - Optional webhook sender for Swiss OpenData stationboard data

### Benefits of Refactored Architecture

- **Single source of truth** - Business logic in one place
- **No code duplication** - ~200 lines of duplicate code eliminated per layout
- **Easy maintenance** - Fix bugs once, applies to all layouts
- **Clean layouts** - Each layout focuses on structure and styling
- **Extensible** - New layouts can easily include shared functionality

## Development

### Making Changes

**For common functionality:**
- Edit `src/shared.liquid`
- Changes automatically apply to all layouts

**For layout-specific changes:**
- Edit the specific layout file in `src/`
- Adjust column widths, maxRows, or labelSize

### Adding Features

1. Add helper functions to `src/shared.liquid`
2. Update `renderDepartures()` if needed
3. Test with all layout variants
4. Update `src/settings.yml` for new configuration options

### Testing

Deploy to TRMNL and test with different:
- Station types (urban vs. long-distance)
- Filter combinations
- Screen layouts
- Transport type mixes

## Credits

- **Original Author:** David M. ([Instagram](https://www.instagram.com/david_meury/), [GitHub](https://github.com/notaprogrammer-alt))
- **Updated by:** Jens-Christian Fischer - Refactored shared code and data delivery
- **Further modified by:** Jeremy Grlj - TRMNL webhook mode and current framework layout cleanup
- **Data Source:** [Swiss OpenData Transport](https://transport.opendata.ch)

## Resources

- [TRMNL Private Plugins Documentation](https://help.usetrmnl.com/en/articles/9510536-private-plugins)
- [TRMNL Screen Templating](https://docs.usetrmnl.com/go/private-plugins/templates)
- [Swiss OpenData Transport API Docs](https://transport.opendata.ch/docs.html)
- [Importing/Exporting Plugins](https://help.usetrmnl.com/en/articles/10542599-importing-and-exporting-private-plugins)

## License

This plugin is provided as-is for use with TRMNL devices. Feel free to modify and adapt for your needs.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test with multiple layout variants
4. Submit a pull request

---

**Note:** This is a private plugin for TRMNL e-ink displays. You need a TRMNL device and Developer edition to use it.
