import SwiftUI

@main
struct WeatherDeckApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(.dark)

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}