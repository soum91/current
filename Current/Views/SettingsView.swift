import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: SpeedStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "Display units")
                            Picker("Display units", selection: $store.unit) {
                                ForEach(SpeedUnit.allCases) { unit in
                                    Text(unit.title).tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Refresh speed")
                            Text("Network sampling")
                                .font(.subheadline.weight(.semibold))
                            Picker("Network sampling", selection: $store.sampleInterval) {
                                Text("0.25s").tag(0.25)
                                Text("0.5s").tag(0.5)
                                Text("1s").tag(1.0)
                                Text("2s").tag(2.0)
                            }
                            .pickerStyle(.segmented)

                            Text("Dynamic Island updates")
                                .font(.subheadline.weight(.semibold))
                                .padding(.top, 5)
                            Picker("Dynamic Island updates", selection: $store.activityUpdateInterval) {
                                Text("0.5s").tag(0.5)
                                Text("1s").tag(1.0)
                                Text("2s").tag(2.0)
                                Text("5s").tag(5.0)
                            }
                            .pickerStyle(.segmented)

                            Text("Faster sampling reacts more quickly but may use more battery. Dynamic Island updates are requests: iOS may delay or combine them, especially in the background.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(text: "Experimental background monitoring")
                            Toggle("Keep monitoring when leaving Current", isOn: $store.backgroundModeEnabled)
                                .tint(Theme.download)
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(store.backgroundLocationActive ? Theme.download : .orange)
                                    .frame(width: 7, height: 7)
                                Text(store.backgroundLocationActive ? "Location session active" : "Location session inactive")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            Text("Uses low-accuracy location updates to request background execution. Current does not store or transmit your location. iOS may show a location indicator, battery use can increase, and updates may still stop when iOS suspends the app.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Home Screen widgets")
                            Label("Small and medium speed widgets", systemImage: "square.grid.2x2")
                            Text("Add Current from the Home Screen widget gallery. Widgets show the most recent sample, not a continuous speed meter. iOS controls refresh timing. Shared readings require an App Group-capable signing profile for both the app and its widget extension.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.subheadline)
                        .card()

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "How it works")
                            Label("Samples every \(store.sampleInterval.formatted()) seconds", systemImage: "waveform.path.ecg")
                            Label("Island update requests every \(store.activityUpdateInterval.formatted()) seconds", systemImage: "capsule")
                            Label("Experimental background monitoring is optional", systemImage: "location")
                            Text("Apple controls Dynamic Island and widget refresh timing. Even with background location enabled, Current cannot guarantee uninterrupted measurements.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .font(.subheadline)
                        .card()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Theme.download)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
