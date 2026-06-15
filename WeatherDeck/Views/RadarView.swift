import SwiftUI
import WebKit

struct RadarView: View {
    let vm: WeatherViewModel
    @State private var refreshId = UUID()

    var body: some View {
        VStack(spacing: 0) {
            if let station = vm.point?.radarStation {
                Text("Radar: \(station)")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 6)
            }

            InteractiveRadarWebView(lat: vm.lat, lon: vm.lon, refreshId: refreshId)
                .cornerRadius(12)
                .padding(.horizontal, 8)

            Button {
                refreshId = UUID()
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reload radar")
                }
                .font(.caption)
                .foregroundStyle(Theme.accent)
            }
            .padding(.top, 8)

            Spacer(minLength: 0)
        }
        .background(Theme.bg)
    }
}

struct InteractiveRadarWebView: UIViewRepresentable {
    let lat: Double
    let lon: Double
    let refreshId: UUID

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
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("weatherdeck_radar.html")
        try? html.write(to: path, atomically: true, encoding: .utf8)
        webView.loadFileURL(path, allowingReadAccessTo: FileManager.default.temporaryDirectory)
    }
}