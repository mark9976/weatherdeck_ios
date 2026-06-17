import Foundation

/// Pure astronomical moon phase calculation — no API needed.
enum MoonPhase {
    struct MoonData {
        let phase: Double          // 0.0–1.0 (0=new, 0.25=first quarter, 0.5=full, 0.75=last quarter)
        let illumination: Double   // 0.0–1.0 percentage
        let phaseName: String
        let emoji: String
        let age: Double            // days into the cycle
        let nextNew: Date
        let nextFull: Date
        let nextFirstQuarter: Date
        let nextLastQuarter: Date
    }

    /// Calculate moon phase for a given date.
    static func calculate(for date: Date = Date()) -> MoonData {
        // Synodic month = 29.53058770576 days
        let synodicMonth = 29.53058770576

        // Known new moon reference: Jan 6, 2000 18:14 UTC
        let ref = DateComponents(calendar: .init(identifier: .gregorian),
                                 timeZone: TimeZone(identifier: "UTC"),
                                 year: 2000, month: 1, day: 6,
                                 hour: 18, minute: 14).date!

        let daysSinceRef = date.timeIntervalSince(ref) / 86400.0
        let cycles = daysSinceRef / synodicMonth
        let phase = cycles - floor(cycles) // 0.0 to 1.0
        let age = phase * synodicMonth

        // Illumination: simple cosine approximation
        let illumination = (1.0 - cos(phase * 2.0 * .pi)) / 2.0

        // Phase name and emoji
        let (name, emoji) = phaseName(phase)

        // Calculate next major phases
        let nextNew = nextPhaseDate(from: date, targetPhase: 0.0, synodicMonth: synodicMonth, currentPhase: phase)
        let nextFirstQ = nextPhaseDate(from: date, targetPhase: 0.25, synodicMonth: synodicMonth, currentPhase: phase)
        let nextFull = nextPhaseDate(from: date, targetPhase: 0.5, synodicMonth: synodicMonth, currentPhase: phase)
        let nextLastQ = nextPhaseDate(from: date, targetPhase: 0.75, synodicMonth: synodicMonth, currentPhase: phase)

        return MoonData(
            phase: phase,
            illumination: illumination,
            phaseName: name,
            emoji: emoji,
            age: age,
            nextNew: nextNew,
            nextFull: nextFull,
            nextFirstQuarter: nextFirstQ,
            nextLastQuarter: nextLastQ
        )
    }

    /// Get moon data for the next N days.
    static func forecast(days: Int = 30) -> [DailyMoon] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<days).map { offset in
            let date = cal.date(byAdding: .day, value: offset, to: today)!
            let data = calculate(for: date)
            return DailyMoon(date: date, data: data)
        }
    }

    struct DailyMoon: Identifiable {
        var id: Date { date }
        let date: Date
        let data: MoonData
    }

    private static func phaseName(_ phase: Double) -> (String, String) {
        switch phase {
        case 0.0..<0.025:    return ("New Moon", "🌑")
        case 0.025..<0.225:  return ("Waxing Crescent", "🌒")
        case 0.225..<0.275:  return ("First Quarter", "🌓")
        case 0.275..<0.475:  return ("Waxing Gibbous", "🌔")
        case 0.475..<0.525:  return ("Full Moon", "🌕")
        case 0.525..<0.725:  return ("Waning Gibbous", "🌖")
        case 0.725..<0.775:  return ("Last Quarter", "🌗")
        case 0.775..<0.975:  return ("Waning Crescent", "🌘")
        default:             return ("New Moon", "🌑")
        }
    }

    private static func nextPhaseDate(from date: Date, targetPhase: Double, synodicMonth: Double, currentPhase: Double) -> Date {
        var diff = targetPhase - currentPhase
        if diff <= 0 { diff += 1.0 }
        let daysUntil = diff * synodicMonth
        return date.addingTimeInterval(daysUntil * 86400)
    }
}
