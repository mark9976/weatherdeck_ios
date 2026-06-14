import SwiftUI

struct AlertsView: View {
    let vm: WeatherViewModel

    var body: some View {
        ScrollView {
            if vm.alerts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.accent)
                    Text("No active alerts")
                        .foregroundStyle(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(vm.alerts) { alert in
                        AlertCard(alert: alert)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Theme.bg)
    }
}

struct AlertCard: View {
    let alert: AlertProperties
    @State private var expanded = false

    private var severityColor: Color {
        switch alert.severity {
        case "Extreme", "Severe": Theme.danger
        case "Moderate": Theme.warn
        default: Theme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(severityColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.event ?? "Alert")
                        .font(.headline)
                        .foregroundStyle(severityColor)

                    HStack(spacing: 8) {
                        if let sev = alert.severity {
                            Text(sev).font(.caption2).foregroundStyle(Theme.muted)
                        }
                        if let urg = alert.urgency {
                            Text("• \(urg)").font(.caption2).foregroundStyle(Theme.muted)
                        }
                    }
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
            }

            // Headline
            if let headline = alert.headline, !headline.isEmpty {
                Text(headline)
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
            }

            // Expanded content
            if expanded {
                if let desc = alert.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(Theme.text)
                }
                if let inst = alert.instruction, !inst.isEmpty {
                    Text("→ \(inst)")
                        .font(.caption)
                        .foregroundStyle(Theme.warn)
                }
            }

            // Time range
            HStack {
                if let eff = formatDate(alert.effective) {
                    Text("From \(eff)")
                }
                if let exp = formatDate(alert.expires) {
                    Text("— Expires \(exp)")
                }
            }
            .font(.caption2)
            .foregroundStyle(Theme.muted)

            if let area = alert.areaDesc {
                Text(area)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(expanded ? nil : 1)
            }
        }
        .padding(16)
        .background(Theme.panel)
        .overlay(
            Rectangle()
                .fill(severityColor)
                .frame(height: 3),
            alignment: .bottom
        )
        .cornerRadius(12)
    }

    private func formatDate(_ s: String?) -> String? {
        guard let d = Units.parseISO(s) else { return nil }
        return d.formatted(date: .abbreviated, time: .shortened)
    }
}
