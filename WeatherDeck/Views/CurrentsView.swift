import SwiftUI

struct CurrentsView: View {
    let vm: WeatherViewModel
    @State private var stations: [NOAAService.CurrentStation] = []
    @State private var selectedStation: NOAAService.CurrentStation?
    @State private var predictions: [NOAAService.CurrentPrediction] = []
    @State private var isLoading = false
    @State private var error: String?

    private let noaa = NOAAService()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if isLoading {
                    ProgressView().tint(Theme.accent).padding(.top, 60)
                } else if let error {
                    errorView(error)
                } else if stations.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "water.waves")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.accent)
                        Text("No current stations found nearby.")
                            .foregroundStyle(Theme.muted)
                        Text("Current stations are typically near coastal areas and waterways.")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    stationPicker
                    if !predictions.isEmpty {
                        currentsList
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Theme.bg)
        .task { await loadStations() }
    }

    private var stationPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CURRENT STATION")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stations) { station in
                        Button {
                            selectedStation = station
                            Task { await loadCurrents(station) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                if let d = station.distance {
                                    Text(String(format: "%.0f mi", d))
                                        .font(.caption2)
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedStation?.id == station.id ? Theme.accent : Theme.panel2)
                            .foregroundStyle(selectedStation?.id == station.id ? .white : Theme.text)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.panel)
        .cornerRadius(12)
    }

    private var currentsList: some View {
        VStack(spacing: 4) {
            ForEach(predictions) { pred in
                HStack {
                    // Type indicator
                    ZStack {
                        Circle()
                            .fill(typeColor(pred.Type))
                            .frame(width: 36, height: 36)
                        Image(systemName: typeIcon(pred.Type))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(typeLabel(pred.Type))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.text)
                        Text(formatTime(pred.Time))
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f kts", abs(pred.Velocity_Major)))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(typeColor(pred.Type))
                        if let dir = pred.Direction {
                            Text("\(Units.compass(dir)) \(Int(dir))°")
                                .font(.caption)
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }
                .padding(12)
                .background(Theme.panel)
                .cornerRadius(10)
            }
        }
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundStyle(Theme.warn)
            Text(msg)
                .font(.caption)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private func typeColor(_ type: String?) -> Color {
        switch type?.lowercased() {
        case "flood": return Theme.accent
        case "ebb": return Theme.warn
        case "slack": return Theme.muted
        default: return Theme.panel2
        }
    }

    private func typeIcon(_ type: String?) -> String {
        switch type?.lowercased() {
        case "flood": return "arrow.up"
        case "ebb": return "arrow.down"
        case "slack": return "minus"
        default: return "water.waves"
        }
    }

    private func typeLabel(_ type: String?) -> String {
        switch type?.lowercased() {
        case "flood": return "Flood"
        case "ebb": return "Ebb"
        case "slack": return "Slack"
        default: return "Current"
        }
    }

    private func loadStations() async {
        isLoading = true
        error = nil
        do {
            stations = try await noaa.findCurrentStations(lat: vm.lat, lon: vm.lon)
            if let first = stations.first {
                selectedStation = first
                await loadCurrents(first)
            }
        } catch {
            self.error = "Could not find current stations: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func loadCurrents(_ station: NOAAService.CurrentStation) async {
        do {
            predictions = try await noaa.getCurrentPredictions(stationId: station.stationId)
        } catch {
            self.error = "Could not load current predictions: \(error.localizedDescription)"
        }
    }

    private func formatTime(_ t: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        guard let date = df.date(from: t) else { return t }
        let out = DateFormatter()
        out.dateFormat = "EEE h:mm a"
        return out.string(from: date)
    }
}
