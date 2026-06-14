import SwiftUI

struct CurrentView: View {
    let vm: WeatherViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Big temperature + description
                tempCard

                // Wind compass
                windCard

                // Metrics grid
                metricsGrid

                // Station info
                stationInfo
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(Theme.bg)
    }

    // MARK: - Cards

    private var tempCard: some View {
        VStack(spacing: 4) {
            Text(vm.tempF)
                .font(.system(size: 80, weight: .ultraLight, design: .rounded))
                .foregroundStyle(Theme.text)
            Text(vm.conditionText)
                .font(.title3)
                .foregroundStyle(Theme.accent)
            Text(vm.feelsLike)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.panel)
        .cornerRadius(16)
    }

    private var windCard: some View {
        WindCompassView(
            degrees: vm.windDegrees,
            speed: vm.windDisplay,
            gusts: vm.gustDisplay
        )
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Theme.panel)
        .cornerRadius(16)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCell(label: "HUMIDITY", value: vm.humidity)
            MetricCell(label: "DEWPOINT", value: vm.dewpointF)
            MetricCell(label: "PRESSURE", value: vm.pressure)
            MetricCell(label: "VISIBILITY", value: vm.visibility)
        }
        .padding(16)
        .background(Theme.panel)
        .cornerRadius(16)
    }

    private var stationInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let sid = vm.stationId {
                Text("Station: \(sid)")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
            Text(vm.observedAt)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

struct MetricCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.title2)
                .foregroundStyle(Theme.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
