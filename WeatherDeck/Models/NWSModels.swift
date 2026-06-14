import Foundation

// MARK: - /points/{lat},{lon}

struct PointsResponse: Codable {
    let properties: PointsProperties?
}

struct PointsProperties: Codable {
    let gridId: String?
    let gridX: Int?
    let gridY: Int?
    let forecast: String?
    let forecastHourly: String?
    let forecastGridData: String?
    let observationStations: String?
    let relativeLocation: RelativeLocation?
    let radarStation: String?
    let county: String?
    let timeZone: String?
}

struct RelativeLocation: Codable {
    let properties: RelativeLocationProps?
}

struct RelativeLocationProps: Codable {
    let city: String?
    let state: String?
}

// MARK: - Forecast

struct ForecastResponse: Codable {
    let properties: ForecastProperties?
}

struct ForecastProperties: Codable {
    let updated: String?
    let periods: [ForecastPeriod]?
}

struct ForecastPeriod: Codable, Identifiable {
    var id: Int { number }
    let number: Int
    let name: String?
    let startTime: String?
    let endTime: String?
    let isDaytime: Bool?
    let temperature: Int?
    let temperatureUnit: String?
    let probabilityOfPrecipitation: UnitValue?
    let windSpeed: String?
    let windDirection: String?
    let icon: String?
    let shortForecast: String?
    let detailedForecast: String?
    let dewpoint: UnitValue?
    let relativeHumidity: UnitValue?
}

// MARK: - Observations

struct ObservationResponse: Codable {
    let properties: ObservationProperties?
}

struct ObservationListResponse: Codable {
    let features: [ObservationFeature]?
}

struct ObservationFeature: Codable {
    let properties: ObservationProperties?
}

struct ObservationProperties: Codable {
    let timestamp: String?
    let textDescription: String?
    let temperature: UnitValue?
    let dewpoint: UnitValue?
    let windDirection: UnitValue?
    let windSpeed: UnitValue?
    let windGust: UnitValue?
    let barometricPressure: UnitValue?
    let seaLevelPressure: UnitValue?
    let visibility: UnitValue?
    let relativeHumidity: UnitValue?
    let heatIndex: UnitValue?
    let windChill: UnitValue?
}

struct UnitValue: Codable {
    let value: Double?
    let unitCode: String?
}

// MARK: - Stations

struct StationsResponse: Codable {
    let features: [StationFeature]?
}

struct StationFeature: Codable {
    let properties: StationProperties?
}

struct StationProperties: Codable {
    let stationIdentifier: String?
    let name: String?
}

// MARK: - Alerts

struct AlertsResponse: Codable {
    let features: [AlertFeature]?
}

struct AlertFeature: Codable {
    let properties: AlertProperties?
}

struct AlertProperties: Codable, Identifiable {
    var id: String { (event ?? "") + (effective ?? "") + (areaDesc ?? "") }
    let event: String?
    let severity: String?
    let urgency: String?
    let certainty: String?
    let headline: String?
    let description: String?
    let instruction: String?
    let effective: String?
    let expires: String?
    let areaDesc: String?
    let senderName: String?
}

// MARK: - Unit conversion helpers

enum Units {
    static func cToF(_ c: Double) -> Double { c * 9.0 / 5.0 + 32.0 }
    static func msToMph(_ ms: Double) -> Double { ms * 2.2369362920544 }
    static func kmhToMph(_ kmh: Double) -> Double { kmh * 0.621371 }
    static func mToMiles(_ m: Double) -> Double { m / 1609.344 }
    static func paToInHg(_ pa: Double) -> Double { pa / 3386.389 }

    static func tempF(_ v: UnitValue?) -> Double? {
        guard let c = v?.value else { return nil }
        return cToF(c)
    }

    static func windMph(_ v: UnitValue?) -> Double? {
        guard let val = v?.value else { return nil }
        if v?.unitCode?.contains("km_h-1") == true { return kmhToMph(val) }
        return msToMph(val)
    }

    static func compass(_ degrees: Double) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE",
                    "S","SSW","SW","WSW","W","WNW","NW","NNW"]
        var idx = Int((degrees / 22.5).rounded()) % 16
        if idx < 0 { idx += 16 }
        return dirs[idx]
    }

    /// Parse an ISO8601 date string to a Date.
    static func parseISO(_ s: String?) -> Date? {
        guard let s else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: s) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: s)
    }
}
