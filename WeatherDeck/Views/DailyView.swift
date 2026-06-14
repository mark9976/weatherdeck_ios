import SwiftUI

struct DailyView: View {
    let vm: WeatherViewModel

    var body: some View {
        ScrollView {
            if vm.forecast.isEmpty {
                Text("No forecast data available.")
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 80)
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(vm.forecast) { period in
                        DailyCard(period: period)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Theme.bg)
    }
}

struct DailyCard: View {
    let period: ForecastPeriod
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary row
            Button { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } } label: {
                HStack(spacing: 0) {
                    Text(period.name ?? "—")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                        .frame(width: 100, alignment: .leading)

                    Text("\(period.temperature ?? 0)°\(period.temperatureUnit ?? "F")")
                        .font(.title3)
                        .foregroundStyle(period.isDaytime == true ? Theme.warn : Theme.accent)
                        .frame(width: 55, alignment: .leading)

                    if let pp = period.probabilityOfPrecipitation?.value, pp > 0 {
                        Text("💧\(Int(pp))%")
                            .font(.caption)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 50, alignment: .leading)
                    } else {
                        Spacer().frame(width: 50)
                    }

                    VStack(alignment: .leading) {
                        Text(period.shortForecast ?? "")
                            .font(.caption)
                            .foregroundStyle(Theme.text)
                            .lineLimit(2)
                        Text("\(period.windDirection ?? "") \(period.windSpeed ?? "")")
                            .font(.caption2)
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(12)

            // Detailed forecast (expandable)
            if expanded, let detail = period.detailedForecast, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.panel)
        .cornerRadius(10)
    }
}
