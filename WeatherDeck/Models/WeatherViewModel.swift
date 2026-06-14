import Foundation

/// Central state for the weather UI. Loads all NWS data for a given location.
@Observable
@MainActor
final class WeatherViewModel {
    // State
    var locationName = "—"
    var gridInfo = ""
    var radarStation = "KPBZ"
    var lat: Double = 40.3015
    var lon: Double = -79.5389

    var observation: ObservationProperties?
    var stationId: String?
    var forecast: [ForecastPeriod] = []
    var hourly: [ForecastPeriod] = []
    var alerts: [AlertProperties] = []
    var point: PointsProperties?

    var isLoading = false
    var statusMessage = "Ready."
    var warnings: [String] = []

    private let nws = NWSService()

    // MARK: - Load all data

    func loadAll() async {
        isLoading = true
        warnings = []
        statusMessage = "Loading NWS grid for \(String(format: "%.4f, %.4f", lat, lon))…"

        do {
            point = try await nws.getPoint(lat: lat, lon: lon)
        } catch {
            statusMessage = "Grid error: \(error.localizedDescription)"
            isLoading = false
            return
        }

        guard let pt = point else {
            statusMessage = "NWS has no grid for \(String(format: "%.4f, %.4f", lat, lon)). US locations only."
            isLoading = false
            return
        }

        if let loc = pt.relativeLocation?.properties {
            locationName = [loc.city, loc.state].compactMap { $0 }.joined(separator: ", ")
        }
        gridInfo = "Grid \(pt.gridId ?? "?") \(pt.gridX ?? 0),\(pt.gridY ?? 0)"
        radarStation = pt.radarStation ?? "KPBZ"

        // Load each section independently — one failure doesn't blank the others.
        async let currentTask: () = safeRun("current") { [self] in await self.loadCurrent(pt) }
        async let forecastTask: () = safeRun("forecast") { [self] in await self.loadForecast(pt) }
        async let hourlyTask: () = safeRun("hourly") { [self] in await self.loadHourly(pt) }
        async let alertsTask: () = safeRun("alerts") { [self] in await self.loadAlerts() }
        let _ = await (currentTask, forecastTask, hourlyTask, alertsTask)

        if warnings.isEmpty {
            statusMessage = "Updated \(Date().formatted(date: .omitted, time: .shortened))."
        } else {
            statusMessage = "Updated with warnings: \(warnings.joined(separator: ", "))."
        }
        isLoading = false
    }

    // MARK: - Individual loaders

    private func loadCurrent(_ pt: PointsProperties) async {
        guard let stationsURL = pt.observationStations else { return }
        let stations = (try? await nws.getStations(url: stationsURL, count: 5)) ?? []
        guard !stations.isEmpty else { warnings.append("no stations"); return }

        if let result = try? await nws.getUsableObservation(stationIds: stations) {
            observation = result.obs
            stationId = result.stationId
        } else {
            warnings.append("no recent observation")
        }
    }

    private func loadForecast(_ pt: PointsProperties) async {
        guard let url = pt.forecast else { return }
        forecast = (try? await nws.getForecast(url: url)) ?? []
    }

    private func loadHourly(_ pt: PointsProperties) async {
        guard let url = pt.forecastHourly else { return }
        let all = (try? await nws.getHourly(url: url)) ?? []
        hourly = Array(all.prefix(48))
    }

    private func loadAlerts() async {
        alerts = (try? await nws.getActiveAlerts(lat: lat, lon: lon)) ?? []
    }

    private func safeRun(_ label: String, _ block: @escaping () async -> Void) async {
        do { try await Task { await block() }.value }
        catch { warnings.append("\(label): \(error.localizedDescription)") }
    }

    // MARK: - Computed display values

    var tempF: String {
        guard let t = Units.tempF(observation?.temperature) else { return "—" }
        return "\(Int(t.rounded()))°"
    }

    var feelsLike: String {
        let feels = Units.tempF(observation?.heatIndex)
                 ?? Units.tempF(observation?.windChill)
                 ?? Units.tempF(observation?.temperature)
        guard let f = feels else { return "Feels like —" }
        return "Feels like \(Int(f.rounded()))°"
    }

    var conditionText: String { observation?.textDescription ?? "—" }

    var windMph: Double? { Units.windMph(observation?.windSpeed) }

    var windDisplay: String {
        guard let mph = windMph else { return "— mph" }
        if mph < 0.5 { return "Calm" }
        let dir = observation?.windDirection?.value.map { Units.compass($0) } ?? ""
        return "\(Int(mph.rounded())) mph \(dir)"
    }

    var gustDisplay: String {
        guard let g = Units.windMph(observation?.windGust) else { return "Gusts —" }
        return "Gusts \(Int(g.rounded())) mph"
    }

    var windDegrees: Double { observation?.windDirection?.value ?? 0 }

    var humidity: String {
        guard let h = observation?.relativeHumidity?.value else { return "—" }
        return "\(Int(h.rounded()))%"
    }

    var dewpointF: String {
        guard let d = Units.tempF(observation?.dewpoint) else { return "—" }
        return "\(Int(d.rounded()))°F"
    }

    var pressure: String {
        guard let pa = observation?.barometricPressure?.value else { return "—" }
        return String(format: "%.2f inHg", Units.paToInHg(pa))
    }

    var visibility: String {
        guard let m = observation?.visibility?.value else { return "—" }
        return String(format: "%.1f mi", Units.mToMiles(m))
    }

    var observedAt: String {
        guard let d = Units.parseISO(observation?.timestamp) else { return "" }
        return "Observed \(d.formatted(date: .abbreviated, time: .shortened))"
    }
}
