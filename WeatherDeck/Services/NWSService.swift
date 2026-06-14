import Foundation

/// Talks to the NWS API (https://api.weather.gov). No API key required.
/// Mirrors the WPF version's resilient patterns: 404→nil, station walking, etc.
actor NWSService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "WeatherDeck-iOS/1.0 (weatherdeck@example.com)",
            "Accept": "application/geo+json"
        ]
        session = URLSession(configuration: config)
    }

    // MARK: - Resilient GET

    /// GET + decode. Returns nil on 404/204/410 instead of throwing.
    /// Other failures throw with the status code for diagnostics.
    private func getOrNil<T: Decodable>(_ url: String) async throws -> T? {
        guard let u = URL(string: url) else { return nil }
        let (data, response) = try await session.data(from: u)
        guard let http = response as? HTTPURLResponse else { return nil }
        switch http.statusCode {
        case 200..<300:
            return try JSONDecoder().decode(T.self, from: data)
        case 404, 204, 410:
            return nil
        default:
            let body = String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw NWSError.httpError(http.statusCode, body)
        }
    }

    // MARK: - Points

    func getPoint(lat: Double, lon: Double) async throws -> PointsProperties? {
        let url = String(format: "https://api.weather.gov/points/%.4f,%.4f", lat, lon)
        let resp: PointsResponse? = try await getOrNil(url)
        return resp?.properties
    }

    // MARK: - Forecast

    func getForecast(url: String) async throws -> [ForecastPeriod] {
        let resp: ForecastResponse? = try await getOrNil(url)
        return resp?.properties?.periods ?? []
    }

    func getHourly(url: String) async throws -> [ForecastPeriod] {
        let resp: ForecastResponse? = try await getOrNil(url)
        return resp?.properties?.periods ?? []
    }

    // MARK: - Stations + Observations

    func getStations(url: String, count: Int = 5) async throws -> [String] {
        let resp: StationsResponse? = try await getOrNil(url)
        return (resp?.features ?? [])
            .compactMap { $0.properties?.stationIdentifier }
            .prefix(count)
            .map { $0 }
    }

    func getLatestObservation(stationId: String) async throws -> ObservationProperties? {
        // Try the /latest endpoint first.
        let latest: ObservationResponse? = try await getOrNil(
            "https://api.weather.gov/stations/\(stationId)/observations/latest?require_qc=false")
        if let p = latest?.properties, p.temperature?.value != nil { return p }

        // Fallback: list recent observations and pick the first with a temperature.
        let list: ObservationListResponse? = try await getOrNil(
            "https://api.weather.gov/stations/\(stationId)/observations?limit=5")
        return list?.features?
            .compactMap { $0.properties }
            .first { $0.temperature?.value != nil }
    }

    /// Walk stations until one yields a usable observation.
    func getUsableObservation(stationIds: [String]) async throws -> (obs: ObservationProperties, stationId: String)? {
        for id in stationIds {
            if let obs = try? await getLatestObservation(stationId: id) {
                return (obs, id)
            }
        }
        return nil
    }

    // MARK: - Alerts

    func getActiveAlerts(lat: Double, lon: Double) async throws -> [AlertProperties] {
        let url = String(format: "https://api.weather.gov/alerts/active?point=%.4f,%.4f", lat, lon)
        let resp: AlertsResponse? = try await getOrNil(url)
        return (resp?.features ?? []).compactMap { $0.properties }
    }
}

enum NWSError: LocalizedError {
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let body):
            return "NWS returned \(code). \(body)"
        }
    }
}
