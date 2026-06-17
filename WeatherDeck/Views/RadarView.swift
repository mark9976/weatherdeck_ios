import SwiftUI
import WebKit

struct RadarView: View {
    let vm: WeatherViewModel
    @State private var refreshId = UUID()
    @AppStorage("isLightMode") private var isLightMode = false

    var body: some View {
        VStack(spacing: 0) {
            if let station = vm.point?.radarStation {
                Text("Radar: \(station)")
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 6)
            }

            InteractiveRadarWebView(lat: vm.lat, lon: vm.lon, isDark: !isLightMode, refreshId: refreshId)
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
    let isDark: Bool
    let refreshId: UUID

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let bgColor = isDark
            ? UIColor(red: 0.043, green: 0.059, blue: 0.078, alpha: 1)
            : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        webView.backgroundColor = bgColor
        webView.scrollView.backgroundColor = bgColor

        let html = RadarService.interactiveHTML(lat: lat, lon: lon, isDark: isDark)
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("weatherdeck_radar.html")
        try? html.write(to: path, atomically: true, encoding: .utf8)
        webView.loadFileURL(path, allowingReadAccessTo: FileManager.default.temporaryDirectory)
    }
}