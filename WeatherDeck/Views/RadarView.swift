import SwiftUI
import WebKit

struct RadarView: View {
    let vm: WeatherViewModel
    @State private var radarMode: RadarMode = .interactive

    enum RadarMode: String, CaseIterable {
        case interactive = "Interactive"
        case station = "NWS Station Loop"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode picker
            Picker("Radar Mode", selection: $radarMode) {
                ForEach(RadarMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if let station = vm.point?.radarStation {
                Text("Radar: \(station)")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 4)
            }

            // Radar content
            switch radarMode {
            case .interactive:
                InteractiveRadarWebView(lat: vm.lat, lon: vm.lon)
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
            case .station:
                StationRadarView(station: vm.radarStation)
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)
        }
        .background(Theme.bg)
    }
}

// MARK: - Interactive radar (WKWebView wrapper)

struct InteractiveRadarWebView: UIViewRepresentable {
    let lat: Double
    let lon: Double

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.043, green: 0.059, blue: 0.078, alpha: 1)
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = RadarService.interactiveHTML(lat: lat, lon: lon)
        // Write to a temp file for a real origin, matching the WPF approach.
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("weatherdeck_radar.html")
        try? html.write(to: path, atomically: true, encoding: .utf8)
        webView.loadFileURL(path, allowingReadAccessTo: FileManager.default.temporaryDirectory)
    }
}

// MARK: - NWS station loop (animated GIF)

struct StationRadarView: View {
    let station: String
    @State private var refreshId = UUID()

    var body: some View {
        VStack {
            if let url = RadarService.stationLoopURL(station) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title)
                                .foregroundStyle(Theme.warn)
                            Text("Failed to load radar for \(station)")
                                .foregroundStyle(Theme.muted)
                                .font(.caption)
                        }
                    case .empty:
                        ProgressView()
                            .tint(Theme.accent)
                    @unknown default:
                        EmptyView()
                    }
                }
                .id(refreshId) // force reload on refresh
            }

            Button {
                refreshId = UUID()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 8)
        }
    }
}
