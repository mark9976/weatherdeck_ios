import Foundation

/// NOAA CO-OPS Tides and Currents API (https://api.tidesandcurrents.noaa.gov)
/// Free, no API key required.
actor NOAAService {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    private let base = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"

    // MARK: - Tide Predictions

    struct TidePrediction: Codable, Identifiable {
        var id: String { t }
        let t: String  // timestamp "2026-06-15 04:30"
        let v: String  // water level
        let type: String? // "H" high, "L" low (only in hilo)
    }

    struct TideResponse: Codable {
        let predictions: [TidePrediction]?
    }

    struct TideStation: Codable, Identifiable {
        var id: String { stationId }
        let stationId: String
        let name: String
        let lat: Double
        let lng: Double
        let distance: Double?

        enum CodingKeys: String, CodingKey {
            case stationId = "id"
            case name, lat, lng, distance
        }
    }

    /// Find nearest tide prediction stations to a lat/lon.
    func findTideStations(lat: Double, lon: Double) async throws -> [TideStation] {
        let url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions&units=english"
        guard let u = URL(string: url) else { return [] }
        let (data, _) = try await session.data(from: u)

        struct StationsWrapper: Codable {
            let stations: [RawStation]?
        }
        struct RawStation: Codable {
            let id: String
            let name: String
            let lat: Double
            let lng: Double
        }

        let wrapper = try JSONDecoder().decode(StationsWrapper.self, from: data)
        guard let stations = wrapper.stations else { return [] }

        // Calculate distances and return nearest 5
        return stations.map { s in
            let d = haversine(lat1: lat, lon1: lon, lat2: s.lat, lon2: s.lng)
            return TideStation(stationId: s.id, name: s.name, lat: s.lat, lng: s.lng, distance: d)
        }
        .sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        .prefix(5)
        .map { $0 }
    }

    /// Get tide predictions (high/low) for a station.
    func getTideHiLo(stationId: String, hours: Int = 48) async throws -> [TidePrediction] {
        let now = Date()
        let end = now.addingTimeInterval(Double(hours) * 3600)
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let begin = df.string(from: now)
        let endStr = df.string(from: end)

        let url = "\(base)?begin_date=\(begin)&end_date=\(endStr)&station=\(stationId)&product=predictions&datum=MLLW&units=english&time_zone=lst_ldt&interval=hilo&format=json"
        guard let u = URL(string: url) else { return [] }
        let (data, _) = try await session.data(from: u)
        let resp = try JSONDecoder().decode(TideResponse.self, from: data)
        return resp.predictions ?? []
    }

    /// Get detailed tide curve (6-minute intervals).
    func getTideCurve(stationId: String, hours: Int = 24) async throws -> [TidePrediction] {
        let now = Date()
        let end = now.addingTimeInterval(Double(hours) * 3600)
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd HH:mm"
        let begin = df.string(from: now)
        let endStr = df.string(from: end)

        let url = "\(base)?begin_date=\(begin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? begin)&end_date=\(endStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? endStr)&station=\(stationId)&product=predictions&datum=MLLW&units=english&time_zone=lst_ldt&interval=6&format=json"
        guard let u = URL(string: url) else { return [] }
        let (data, _) = try await session.data(from: u)
        let resp = try JSONDecoder().decode(TideResponse.self, from: data)
        return resp.predictions ?? []
    }

    // MARK: - Currents

    struct CurrentStation: Codable, Identifiable {
        var id: String { stationId }
        let stationId: String
        let name: String
        let lat: Double
        let lng: Double
        let distance: Double?

        enum CodingKeys: String, CodingKey {
            case stationId = "id"
            case name, lat, lng, distance
        }
    }

    struct CurrentPrediction: Codable, Identifiable {
        var id: String { "\(Time)_\(Velocity_Major)" }
        let Time: String
        let Velocity_Major: Double
        let meanFloodDir: Double?
        let meanEbbDir: Double?
        let Bin: String?
        let Depth: Double?
        let Speed: Double?
        let Direction: Double?
        let Type: String? // "flood", "ebb", "slack"
    }

    struct CurrentResponse: Codable {
        let current_predictions: CurrentWrapper?
    }

    struct CurrentWrapper: Codable {
        let cp: [CurrentPrediction]?
    }

    func findCurrentStations(lat: Double, lon: Double) async throws -> [CurrentStation] {
        let url = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=currentpredictions&units=english"
        guard let u = URL(string: url) else { return [] }
        let (data, _) = try await session.data(from: u)

        struct StationsWrapper: Codable {
            let stations: [RawStation]?
        }
        struct RawStation: Codable {
            let id: String
            let name: String
            let lat: Double
            let lng: Double
        }

        let wrapper = try JSONDecoder().decode(StationsWrapper.self, from: data)
        guard let stations = wrapper.stations else { return [] }

        return stations.map { s in
            let d = haversine(lat1: lat, lon1: lon, lat2: s.lat, lon2: s.lng)
            return CurrentStation(stationId: s.id, name: s.name, lat: s.lat, lng: s.lng, distance: d)
        }
        .sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        .prefix(5)
        .map { $0 }
    }

    func getCurrentPredictions(stationId: String, hours: Int = 48) async throws -> [CurrentPrediction] {
        let now = Date()
        let end = now.addingTimeInterval(Double(hours) * 3600)
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let begin = df.string(from: now)
        let endStr = df.string(from: end)

        let url = "\(base)?begin_date=\(begin)&end_date=\(endStr)&station=\(stationId)&product=currents_predictions&units=english&time_zone=lst_ldt&interval=MAX_SLACK&format=json"
        guard let u = URL(string: url) else { return [] }
        let (data, _) = try await session.data(from: u)
        let resp = try JSONDecoder().decode(CurrentResponse.self, from: data)
        return resp.current_predictions?.cp ?? []
    }

    // MARK: - Haversine

    private func haversine(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3958.8 // miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1-a))
    }
}
