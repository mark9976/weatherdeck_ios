import SwiftUI

struct TidesView: View {
    let vm: WeatherViewModel
    @State private var stations: [NOAAService.TideStation] = []
    @State private var selectedStation: NOAAService.TideStation?
    @State private var predictions: [NOAAService.TidePrediction] = []
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
                    Text("No tide stations found nearby.")
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 60)
                } else {
                    stationPicker
                    if !predictions.isEmpty {
                        tideList
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
            Text("TIDE STATION")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.muted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stations) { station in
                        Button {
                            selectedStation = station
                            Task { await loadTides(station) }
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

    private var tideList: some View {
        VStack(spacing: 4) {
            ForEach(predictions) { pred in
                HStack {
                    // High/Low indicator
                    ZStack {
                        Circle()
                            .fill(pred.type == "H" ? Theme.accent : Theme.panel2)
                            .frame(width: 36, height: 36)
                        Image(systemName: pred.type == "H" ? "arrow.up" : "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(pred.type == "H" ? .white : Theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pred.type == "H" ? "High Tide" : "Low Tide")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.text)
                        Text(formatTideTime(pred.t))
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer()

                    Text("\(pred.v) ft")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(pred.type == "H" ? Theme.warn : Theme.accent)
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

    private func loadStations() async {
        isLoading = true
        error = nil
        do {
            stations = try await noaa.findTideStations(lat: vm.lat, lon: vm.lon)
            if let first = stations.first {
                selectedStation = first
                await loadTides(first)
            }
        } catch {
            self.error = "Could not find tide stations: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func loadTides(_ station: NOAAService.TideStation) async {
        do {
            predictions = try await noaa.getTideHiLo(stationId: station.stationId)
        } catch {
            self.error = "Could not load tide predictions: \(error.localizedDescription)"
        }
    }

    private func formatTideTime(_ t: String) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        guard let date = df.date(from: t) else { return t }
        let out = DateFormatter()
        out.dateFormat = "EEE h:mm a"
        return out.string(from: date)
    }
}
