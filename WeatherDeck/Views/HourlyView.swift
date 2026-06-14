import SwiftUI

struct HourlyView: View {
    let vm: WeatherViewModel

    var body: some View {
        ScrollView {
            if vm.hourly.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(vm.hourly) { period in
                        HourlyRow(period: period)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Theme.bg)
    }

    private var emptyState: some View {
        Text("No hourly data available.")
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 80)
    }
}

struct HourlyRow: View {
    let period: ForecastPeriod

    var body: some View {
        HStack(spacing: 0) {
            // Time
            Text(formattedTime)
                .font(.caption)
                .foregroundStyle(Theme.text)
                .frame(width: 70, alignment: .leading)

            // Temperature
            Text("\(period.temperature ?? 0)°")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.warn)
                .frame(width: 50, alignment: .leading)

            // Precip
            precipText
                .frame(width: 50, alignment: .leading)

            // Wind
            Text("\(period.windDirection ?? "") \(period.windSpeed ?? "")")
                .font(.caption2)
                .foregroundStyle(Theme.muted)
                .frame(width: 70, alignment: .leading)

            // Short forecast
            Text(period.shortForecast ?? "")
                .font(.caption)
                .foregroundStyle(Theme.text)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Theme.panel)
        .cornerRadius(8)
    }

    private var formattedTime: String {
        guard let d = Units.parseISO(period.startTime) else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "EEE h a"
        return f.string(from: d)
    }

    @ViewBuilder
    private var precipText: some View {
        if let pp = period.probabilityOfPrecipitation?.value, pp > 0 {
            Text("💧\(Int(pp))%")
                .font(.caption)
                .foregroundStyle(Theme.accent)
        } else {
            Text("")
        }
    }
}
