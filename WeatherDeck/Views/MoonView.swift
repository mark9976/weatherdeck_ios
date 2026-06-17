import SwiftUI

struct MoonView: View {
    let vm: WeatherViewModel
    private let moon = MoonPhase.calculate()
    private let forecast = MoonPhase.forecast(days: 30)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Current moon phase hero
                currentPhaseCard

                // Key dates
                upcomingPhasesCard

                // 30-day calendar
                calendarCard
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Theme.bg)
    }

    private var currentPhaseCard: some View {
        VStack(spacing: 12) {
            Text(moon.emoji)
                .font(.system(size: 80))

            Text(moon.phaseName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.text)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("ILLUMINATION")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.muted)
                    Text(String(format: "%.0f%%", moon.illumination * 100))
                        .font(.title2)
                        .foregroundStyle(Theme.warn)
                }
                VStack(spacing: 4) {
                    Text("MOON AGE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.muted)
                    Text(String(format: "%.1f days", moon.age))
                        .font(.title2)
                        .foregroundStyle(Theme.text)
                }
            }

            // Illumination bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.panel2)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.warn)
                        .frame(width: geo.size.width * moon.illumination, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)
        }
        .padding(20)
        .background(Theme.panel)
        .cornerRadius(16)
    }

    private var upcomingPhasesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UPCOMING PHASES")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.muted)

            HStack(spacing: 0) {
                phaseDate("🌑", "New Moon", moon.nextNew)
                phaseDate("🌓", "First Qtr", moon.nextFirstQuarter)
                phaseDate("🌕", "Full Moon", moon.nextFull)
                phaseDate("🌗", "Last Qtr", moon.nextLastQuarter)
            }
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(12)
    }

    private func phaseDate(_ emoji: String, _ name: String, _ date: Date) -> some View {
        VStack(spacing: 4) {
            Text(emoji).font(.title2)
            Text(name)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.text)
        }
        .frame(maxWidth: .infinity)
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("30-DAY MOON CALENDAR")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.muted)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(forecast) { day in
                    VStack(spacing: 2) {
                        Text(day.data.emoji)
                            .font(.title3)
                        Text(day.date.formatted(.dateTime.day()))
                            .font(.caption2)
                            .foregroundStyle(Theme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Calendar.current.isDateInToday(day.date) ? Theme.accent.opacity(0.3) : Color.clear)
                    .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(12)
    }
}
