# WeatherDeck iOS

A native SwiftUI weather app for iPhone — the iOS companion to the WPF WeatherDeck desktop app. Same NWS API data, same dark "storm chaser" theme, built for iOS 17+.

## Features

- **Current Conditions** — Big temperature display, animated wind compass, feels-like, humidity, dewpoint, barometric pressure, visibility.
- **Hourly** — Next 48 hours with temp, precip %, wind, short forecast.
- **7-Day** — Full NWS forecast periods with expandable detailed narratives.
- **Alerts** — Active watches/warnings/advisories, severity-colored, with full instructions.
- **Radar** — Interactive animated radar (Leaflet + RainViewer) and NWS station loop GIF.
- **GPS Location** — Auto-detects your location via CoreLocation, or search by city/ZIP/lat,lon.

## Architecture

- **SwiftUI** with `@Observable` (iOS 17+)
- **NWS API** (api.weather.gov) — no API key required
- **CoreLocation** for GPS + `CLGeocoder` for search
- **WKWebView** for interactive radar (Leaflet + RainViewer tiles)
- Same resilient patterns as the WPF version: 404→nil, multi-station observation walking, independent fault isolation per data section

## Building Without a Mac

This project uses **XcodeGen** to generate the `.xcodeproj` from `project.yml`, so no Xcode project file is checked in. The GitHub Actions workflow handles everything:

1. Push the code to your GitHub repo (e.g. `mark9976/weatherdeck-ios`)
2. GitHub Actions runs on a macOS runner, installs XcodeGen, generates the project, and builds it
3. The build artifact (a simulator `.app` zip) is uploaded as a GitHub Actions artifact

### To get it on your actual iPhone

Building for a real device requires code signing, which means:

1. **Apple Developer Account** ($99/year at developer.apple.com)
2. **Provisioning profile + signing certificate** — configured in the GitHub Actions workflow
3. **TestFlight** — upload the signed build and install on your phone via the TestFlight app

Alternatively, if you ever get access to a Mac (even a cloud Mac via MacStadium or AWS EC2 Mac):
- Install Xcode, open the generated project, plug in your iPhone, and hit Run

## Project Structure

```
WeatherDeck/
  WeatherDeckApp.swift       # App entry point
  Theme.swift                # Storm chaser color palette
  Info.plist                 # Permissions (location)
  Assets.xcassets/           # App icon + accent color
  Models/
    NWSModels.swift          # NWS API Codable structs + unit conversion
    WeatherViewModel.swift   # @Observable view model, data orchestration
  Services/
    NWSService.swift         # NWS API client (actor, resilient)
    LocationService.swift    # CoreLocation + geocoding
    RadarService.swift       # Radar HTML generator
  Views/
    ContentView.swift        # Main tab layout + search sheet
    CurrentView.swift        # Current conditions tab
    HourlyView.swift         # Hourly forecast tab
    DailyView.swift          # 7-day forecast tab
    AlertsView.swift         # Weather alerts tab
    RadarView.swift          # Radar tab (interactive + station loop)
    WindCompassView.swift    # Animated wind compass

project.yml                  # XcodeGen spec (generates .xcodeproj)
.github/workflows/
  ios-build.yml              # GitHub Actions CI build
```

## Local Development (requires Mac)

```bash
brew install xcodegen
xcodegen generate
open WeatherDeck.xcodeproj
# Select an iPhone simulator and press ⌘R
```
