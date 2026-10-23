import SwiftUI
import UIKit

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

                        VStack(alignment: .leading, spacing: 13) {
                            SectionTitle(text: "Dynamic Island appearance")
                            Picker("Island layout", selection: $store.islandLayout) {
                                ForEach(IslandLayout.allCases) { layout in
                                    Text(layout.title).tag(layout)
                                }
                            }
                            .pickerStyle(.segmented)

                            switch store.islandLayout {
                            case .classic:
                                Text("Classic puts download on the left and upload on the right, like the earlier working builds.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.64))
                            case .slim:
                                Text("Slim groups both speeds on the right. iOS may still reserve an empty area on the left.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.64))
                            case .custom:
                                Text("Write your own text for each side of the main Island and both lines of the smaller secondary Island.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.64))

                                templateField("Left side", text: $store.leadingTemplate)
                                templateField("Right side", text: $store.trailingTemplate)
                                templateField("Small Island, top", text: $store.minimalTopTemplate)
                                templateField("Small Island, bottom", text: $store.minimalBottomTemplate)

                                Text("Text size")
                                    .font(.subheadline.weight(.semibold))
                                Picker("Text size", selection: $store.customTextSize) {
                                    Text("8 pt").tag(8.0)
                                    Text("10 pt").tag(10.0)
                                    Text("12 pt").tag(12.0)
                                }
                                .pickerStyle(.segmented)

                                Text("Tokens: {down}  {up}  {down.full}  {up.full}  {interface}. Add any words, symbols or emoji. Keep each field short to fit the Island.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.58))
                                    .fixedSize(horizontal: false, vertical: true)

                                Button("Reset custom text to arrows") {
                                    store.leadingTemplate = IslandTemplate.leading
                                    store.trailingTemplate = IslandTemplate.trailing
                                    store.minimalTopTemplate = IslandTemplate.top
                                    store.minimalBottomTemplate = IslandTemplate.bottom
                                    store.customTextSize = 10
                                }
                                .font(.caption.weight(.semibold))
                                .tint(Theme.download)
                            }

                            Text("Apple controls the Island's black background and dimensions. Changing text or leaving one side empty cannot make its background transparent.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.46))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .card()

                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "Experimental background monitoring")
                            Toggle("Keep monitoring outside Current", isOn: $store.backgroundModeEnabled)
                                .tint(Theme.download)
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(store.backgroundLocationActive ? Theme.download : .orange)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 5)
                                Text(store.backgroundLocationStatus)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            if store.backgroundModeEnabled && !store.backgroundLocationActive {
                                Button {
                                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                                    UIApplication.shared.open(url)
                                } label: {
                                    Label("Open iOS Location Settings", systemImage: "gearshape")
                                        .font(.subheadline.weight(.semibold))
                                }
                                .tint(Theme.download)
                            }
                            Text("Requires Location: Always. Uses coarse location services only to request background execution; Current never stores or sends coordinates. The prominent blue background-location indicator is disabled for Always access, but iOS may still show privacy indicators. Battery use may increase and continuous updates are not guaranteed.")
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
                            Label(store.backgroundLocationActive ? "Experimental background location session active" : "Measurements pause when Current is suspended", systemImage: "pause.circle")
                            Text("Apple controls Dynamic Island, background execution and widget refresh timing. Current cannot guarantee uninterrupted measurements while other apps are open.")
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

    private func templateField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
            TextField(label, text: text)
                .font(.system(.subheadline, design: .monospaced))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
                .onChange(of: text.wrappedValue) { _, newValue in
                    if newValue.count > 40 { text.wrappedValue = IslandTemplate.limited(newValue) }
                }
        }
    }
}
