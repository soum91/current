import SwiftUI
import ActivityKit
import UIKit

@main
struct CurrentAnchorApp: App {
    @StateObject private var model = AnchorController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AnchorView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .onAppear { model.refresh() }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active { model.refresh() }
                }
        }
    }
}

@MainActor
final class AnchorController: ObservableObject {
    @Published private(set) var active = false
    @Published private(set) var busy = false
    @Published private(set) var status = "Off"
    @Published var error: String?

    func refresh() {
        guard !busy else { return }
        let ongoing = Activity<AnchorAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
        active = ongoing != nil
        status = ongoing.map { "\($0.activityState)" } ?? "Off"
    }

    func start() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        if Activity<AnchorAttributes>.activities.contains(where: {
            $0.activityState == .active || $0.activityState == .stale
        }) {
            active = true
            status = "Already running"
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            status = "Live Activities disabled"
            error = "Enable Live Activities for Current Anchor in iOS Settings."
            return
        }
        do {
            let activity = try Activity<AnchorAttributes>.request(
                attributes: AnchorAttributes(),
                content: ActivityContent(
                    state: .init(startedAt: .now),
                    staleDate: nil,
                    relevanceScore: 100
                ),
                pushType: nil
            )
            active = true
            status = "Started (\(activity.activityState))"
        } catch {
            active = false
            status = "Start failed"
            self.error = error.localizedDescription
        }
    }

    func stop() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        for activity in Activity<AnchorAttributes>.activities {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        active = false
        status = "Off"
    }
}

private struct AnchorView: View {
    @EnvironmentObject private var model: AnchorController

    private var installedVersion: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "?"
        let build = info["CFBundleVersion"] as? String ?? "?"
        return "\(version) (Build \(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                HStack(spacing: 12) {
                    Image(systemName: "circle.dotted.circle")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color(red: 0.38, green: 0.91, blue: 0.78))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Current Anchor").font(.system(size: 29, weight: .bold, design: .rounded))
                        Text("EXPERIMENTAL ISLAND COMPANION")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.6).foregroundStyle(.gray)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Anchor Live Activity").font(.headline)
                        Spacer()
                        Text(model.active ? "ACTIVE" : "OFF")
                            .font(.caption.bold())
                            .foregroundStyle(model.active ? .mint : .gray)
                    }
                    Text(model.status).font(.caption).foregroundStyle(.gray)
                    Text("Starts a tiny, neutral placeholder activity. If iOS chooses to show two apps, the regular Current speed meter may appear in the detached Island bubble.")
                        .foregroundStyle(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Task {
                            if model.active { await model.stop() }
                            else { await model.start() }
                        }
                    } label: {
                        Label(model.active ? "Stop Anchor" : "Start Anchor",
                              systemImage: model.active ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(model.active ? .gray : .mint)
                    .disabled(model.busy)

                    Button {
                        if let url = URL(string: "current://open") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Current", systemImage: "arrow.up.right.square")
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(20)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 23))

                VStack(alignment: .leading, spacing: 11) {
                    Text("Test order").font(.headline)
                    Text("1. Start Anchor here.\n2. Tap Open Current and start or restart Current's speed Live Activity.\n3. Switch to another app and check which activity iOS places in the smaller bubble.\n4. Return here to stop Anchor.")
                        .foregroundStyle(.white.opacity(0.72))
                    Text("Anchor does not monitor location, run in the background, or transmit anything. The placeholder is intentionally minimal, not invisible. iOS may prioritize another activity, and activities can expire after eight hours.")
                        .font(.caption).foregroundStyle(.gray)
                }
                .padding(20)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 23))

                Text("Installed version: \(installedVersion)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.gray)
                Text("soum91 • Current project")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(20)
        }
        .background(Color(red: 0.035, green: 0.065, blue: 0.085).ignoresSafeArea())
        .alert("Current Anchor", isPresented: Binding(
            get: { model.error != nil },
            set: { if !$0 { model.error = nil } }
        )) {
            Button("OK", role: .cancel) { model.error = nil }
        } message: {
            Text(model.error ?? "")
        }
    }
}
