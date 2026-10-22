import Charts
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: SpeedStore
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        speedCard
                        islandCard
                        chartCard
                        sessionCard
                        note
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 42)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showsSettings) { SettingsView() }
            .alert("Current", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Current")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 7) {
                    Circle()
                        .fill(store.isMeasuring ? Theme.download : .gray)
                        .frame(width: 7, height: 7)
                    Text(store.isMeasuring ? "Monitoring · \(store.interfaceLabel)" : "Paused")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            Spacer()
            Button { showsSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 43, height: 43)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().stroke(Theme.stroke))
            }
            .accessibilityLabel("Settings")
        }
    }

    private var speedCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                SectionTitle(text: "Live throughput")
                Spacer()
                Text("\(store.sampleInterval.formatted()) s samples")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.38))
            }
            HStack(alignment: .top, spacing: 12) {
                metric(title: "Download", systemImage: "arrow.down.right", color: Theme.download, bytes: store.download)
                Rectangle().fill(Theme.stroke).frame(width: 1, height: 98)
                metric(title: "Upload", systemImage: "arrow.up.right", color: Theme.upload, bytes: store.upload)
            }
        }
        .card()
    }

    private func metric(title: String, systemImage: String, color: Color, bytes: Double) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(SpeedFormat.rate(bytes, unit: store.unit))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
            Text(store.isMeasuring ? "Right now" : "Last reading")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var islandCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionTitle(text: "Dynamic Island")
                Spacer()
                Text(store.hasLiveActivity ? "ACTIVE" : "OFF")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(store.hasLiveActivity ? Theme.download : .white.opacity(0.45))
            }

            HStack(spacing: 13) {
                Image(systemName: "arrow.down")
                    .foregroundStyle(Theme.download)
                Text(SpeedFormat.rate(store.download, unit: store.unit, compact: true))
                    .foregroundStyle(Theme.download)
                Rectangle().fill(.white.opacity(0.14)).frame(width: 1, height: 15)
                Image(systemName: "arrow.up")
                    .foregroundStyle(Theme.upload)
                Text(SpeedFormat.rate(store.upload, unit: store.unit, compact: true))
                    .foregroundStyle(Theme.upload)
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(Color.black, in: Capsule())
            .accessibilityLabel("Dynamic Island preview")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SECONDARY ISLAND")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.48))
                    Text("When iOS shows another Live Activity")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.42))
                }
                Spacer(minLength: 4)
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                    Text(SpeedFormat.rate(store.download, unit: store.unit, compact: true))
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.download)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(Color.black, in: Capsule())
            }

            Button {
                Task { await store.toggleLiveActivity() }
            } label: {
                HStack {
                    Image(systemName: store.hasLiveActivity ? "stop.fill" : "waveform.path")
                    Text(store.hasLiveActivity ? "End Live Activity" : "Show in Dynamic Island")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(store.hasLiveActivity ? .white : .black)
                .background(store.hasLiveActivity ? Color.white.opacity(0.10) : Theme.download,
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            }

            Text("iOS limits background updates. Try experimental background monitoring in Settings, or leave it off to pause when Current is backgrounded. Stale readings are marked paused.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionTitle(text: "Last 60 seconds")
                Spacer()
                Circle().fill(Theme.download).frame(width: 7, height: 7)
                Text("Down")
                Circle().fill(Theme.upload).frame(width: 7, height: 7)
                Text("Up")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.52))

            Chart(store.samples) { sample in
                LineMark(
                    x: .value("Time", sample.time),
                    y: .value("Download", sample.download),
                    series: .value("Direction", "Download")
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.download)

                LineMark(
                    x: .value("Time", sample.time),
                    y: .value("Upload", sample.upload),
                    series: .value("Direction", "Upload")
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.upload)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 130)
            .overlay(alignment: .center) {
                if store.samples.count < 2 {
                    Text("Collecting samples…")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.36))
                }
            }
        }
        .card()
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "This session")
            HStack {
                Label("Downloaded", systemImage: "arrow.down.circle")
                    .foregroundStyle(Theme.download)
                Spacer()
                Text(SpeedFormat.amount(store.totalDownload)).monospacedDigit()
            }
            HStack {
                Label("Uploaded", systemImage: "arrow.up.circle")
                    .foregroundStyle(Theme.upload)
                Spacer()
                Text(SpeedFormat.amount(store.totalUpload)).monospacedDigit()
            }
            .font(.subheadline)
        }
        .font(.subheadline)
        .card()
    }

    private var note: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "lock.shield")
            Text("On-device measurements. No VPN, account, remote server, or speed-test traffic. Wi-Fi and cellular interface counters can include traffic from other apps.")
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.4))
        .padding(.horizontal, 8)
    }
}
