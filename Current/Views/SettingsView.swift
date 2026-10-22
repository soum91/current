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
                            SectionTitle(text: "How it works")
                            Label("1-second measurements inside the app", systemImage: "waveform.path.ecg")
                            Label("5-second Live Activity update attempts", systemImage: "capsule")
                            Label("Pauses when iOS suspends Current", systemImage: "pause.circle")
                            Text("Apple controls Dynamic Island refresh timing. A normal iOS app cannot guarantee uninterrupted system-wide speed measurements while another app is open.")
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
