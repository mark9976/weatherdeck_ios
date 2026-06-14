import SwiftUI

/// Animated wind direction compass matching the WPF version's dial.
struct WindCompassView: View {
    let degrees: Double
    let speed: String
    let gusts: String

    var body: some View {
        HStack(spacing: 20) {
            // Compass dial
            ZStack {
                Circle()
                    .stroke(Theme.panel2, lineWidth: 2)
                    .fill(Color(red: 0.055, green: 0.078, blue: 0.11))

                // Cardinal labels
                ForEach(["N", "E", "S", "W"], id: \.self) { dir in
                    Text(dir)
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                        .offset(offset(for: dir))
                }

                // Center dot
                Circle()
                    .fill(Theme.muted)
                    .frame(width: 4, height: 4)

                // Arrow pointing direction wind is blowing toward (from + 180°)
                WindArrow()
                    .fill(Theme.accent)
                    .frame(width: 20, height: 80)
                    .rotationEffect(.degrees(degrees + 180))
                    .animation(.easeInOut(duration: 0.8), value: degrees)
            }
            .frame(width: 110, height: 110)

            // Wind info
            VStack(alignment: .leading, spacing: 4) {
                Text("WIND")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.muted)
                Text(speed)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(gusts)
                    .font(.subheadline)
                    .foregroundStyle(Theme.warn)
            }
        }
    }

    private func offset(for dir: String) -> CGSize {
        let r: CGFloat = 46
        switch dir {
        case "N": return CGSize(width: 0, height: -r)
        case "S": return CGSize(width: 0, height: r)
        case "E": return CGSize(width: r, height: 0)
        case "W": return CGSize(width: -r, height: 0)
        default: return .zero
        }
    }
}

/// Triangle arrow shape for the wind compass.
struct WindArrow: Shape {
    func path(in rect: CGRect) -> Path {
        let midX = rect.midX
        Path { p in
            p.move(to: CGPoint(x: midX, y: rect.minY))       // tip
            p.addLine(to: CGPoint(x: midX + 8, y: rect.midY)) // right wing
            p.addLine(to: CGPoint(x: midX, y: rect.midY - 8)) // notch
            p.addLine(to: CGPoint(x: midX - 8, y: rect.midY)) // left wing
            p.closeSubpath()
        }
    }
}
