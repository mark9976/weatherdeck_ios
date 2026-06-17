import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image("SponsorLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())

                Text("This app is Sponsored by")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)

                Text("3dFurler.com")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(Theme.warn)
                    Text("RawWeather")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                }
                .padding(.bottom, 40)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
                scale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeIn(duration: 0.4)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onFinished()
                }
            }
        }
    }
}