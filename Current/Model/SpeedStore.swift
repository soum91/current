import ActivityKit
import Foundation
import SwiftUI
import WidgetKit

struct SpeedSample: Identifiable {
    let id = UUID()
    let time: Date
    let download: Double
    let upload: Double
}

@MainActor
final class SpeedStore: ObservableObject {
    @Published private(set) var download: Double = 0
    @Published private(set) var upload: Double = 0
    @Published private(set) var totalDownload: UInt64 = 0
    @Published private(set) var totalUpload: UInt64 = 0
    @Published private(set) var samples: [SpeedSample] = []
    @Published private(set) var interfaceLabel = "Checking network"
    @Published private(set) var isMeasuring = false
    @Published private(set) var hasLiveActivity = false
    @Published private(set) var backgroundLocationActive = false
    @Published var errorMessage: String?
    @Published var unit: SpeedUnit {
        didSet {
            UserDefaults.standard.set(unit.rawValue, forKey: "speedUnit")
            publishWidgetSnapshot(force: true)
            Task { await updateActivity(force: true) }
        }
    }
    @Published var backgroundModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundModeEnabled, forKey: "backgroundModeEnabled")
            syncBackgroundLocation()
        }
    }
    @Published var sampleInterval: Double {
        didSet {
            UserDefaults.standard.set(sampleInterval, forKey: "sampleInterval")
            if isMeasuring { restartPollingTask() }
        }
    }
    @Published var activityUpdateInterval: Double {
        didSet {
            UserDefaults.standard.set(activityUpdateInterval, forKey: "activityUpdateInterval")
            Task { await updateActivity(force: true) }
        }
    }

    private let backgroundLocation = BackgroundLocationController()
    private var measuringTask: Task<Void, Never>?
    private var previous: [String: InterfaceSampler.Counters]?
    private var previousDate: Date?
    private var lastActivityUpdate = Date.distantPast
    private var activityUpdatePending = false
    private var lastWidgetSnapshot = Date.distantPast
    private var lastWidgetReload = Date.distantPast
    private var isInBackground = false

    init() {
        self.unit = SpeedUnit(rawValue: UserDefaults.standard.string(forKey: "speedUnit") ?? "bytes") ?? .bytes
        self.backgroundModeEnabled = UserDefaults.standard.bool(forKey: "backgroundModeEnabled")
        let savedSampleInterval = UserDefaults.standard.double(forKey: "sampleInterval")
        self.sampleInterval = [0.25, 0.5, 1.0, 2.0].contains(savedSampleInterval) ? savedSampleInterval : 0.5
        let savedActivityInterval = UserDefaults.standard.double(forKey: "activityUpdateInterval")
        self.activityUpdateInterval = [0.5, 1.0, 2.0, 5.0].contains(savedActivityInterval) ? savedActivityInterval : 1.0
        self.hasLiveActivity = !Activity<SpeedActivityAttributes>.activities.isEmpty
        backgroundLocation.onStatusChange = { [weak self] running, error in
            guard let self else { return }
            self.backgroundLocationActive = running
            if let error { self.errorMessage = error }
            if !running && self.isInBackground { self.pauseMeasuring() }
        }
    }

    func startMeasuring() {
        if backgroundModeEnabled && !isInBackground { backgroundLocation.enable() }
        guard measuringTask == nil else { return }
        hasLiveActivity = !Activity<SpeedActivityAttributes>.activities.isEmpty
        previous = InterfaceSampler.snapshot()
        previousDate = .now
        isMeasuring = true
        interfaceLabel = InterfaceSampler.label(for: Set(previous?.keys.map { $0 } ?? []))
        restartPollingTask()
        publishWidgetSnapshot(force: true)
        Task { await updateActivity(force: true) }
    }

    private func restartPollingTask() {
        measuringTask?.cancel()
        measuringTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let interval = self?.sampleInterval else { break }
                do { try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000)) }
                catch { break }
                guard let self else { break }
                self.poll()
            }
        }
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isInBackground = false
            startMeasuring()
        case .background:
            isInBackground = true
            if !backgroundModeEnabled || !backgroundLocationActive {
                pauseMeasuring()
            }
        default:
            break
        }
    }

    private func syncBackgroundLocation() {
        if backgroundModeEnabled && !isInBackground {
            backgroundLocation.enable()
        } else if !backgroundModeEnabled {
            backgroundLocation.disable()
            if isInBackground { pauseMeasuring() }
        }
    }

    func pauseMeasuring() {
        guard measuringTask != nil else { return }
        measuringTask?.cancel()
        measuringTask = nil
        previous = nil
        previousDate = nil
        isMeasuring = false
        // The activity remains visible, but it must not present stale rates as live.
        publishWidgetSnapshot(force: true)
        Task { await updateActivity(force: true) }
    }

    private func poll() {
        let now = Date()
        let current = InterfaceSampler.snapshot()
        defer {
            previous = current
            previousDate = now
        }
        interfaceLabel = InterfaceSampler.label(for: Set(current.keys))
        guard let previous, let previousDate else { return }
        let elapsed = now.timeIntervalSince(previousDate)
        guard elapsed > 0.05 && elapsed < 10 else { return }

        let delta = InterfaceSampler.difference(from: previous, to: current)
        download = Double(delta.received) / elapsed
        upload = Double(delta.sent) / elapsed
        totalDownload &+= delta.received
        totalUpload &+= delta.sent
        samples.append(SpeedSample(time: now, download: download, upload: upload))
        // Keep an actual one-minute window regardless of sampling frequency.
        samples.removeAll { now.timeIntervalSince($0.time) > 60 }

        publishWidgetSnapshot()

        if hasLiveActivity && now.timeIntervalSince(lastActivityUpdate) >= activityUpdateInterval {
            Task { await updateActivity() }
        }
    }

    private func publishWidgetSnapshot(force: Bool = false) {
        let now = Date()
        guard force || now.timeIntervalSince(lastWidgetSnapshot) >= 5 else { return }
        let saved = WidgetSpeedStorage.save(.init(
            downloadBytesPerSecond: download,
            uploadBytesPerSecond: upload,
            interfaceLabel: interfaceLabel,
            unit: unit,
            updatedAt: now,
            isMeasuring: isMeasuring
        ))
        lastWidgetSnapshot = now
        // WidgetKit ultimately decides refresh times. Frequent requests do not
        // turn a Home Screen widget into a real-time display.
        if saved && (force || now.timeIntervalSince(lastWidgetReload) >= 30) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSpeedStorage.kind)
            lastWidgetReload = now
        }
    }

    private func state() -> SpeedActivityAttributes.ContentState {
        .init(downloadBytesPerSecond: download,
              uploadBytesPerSecond: upload,
              unit: unit,
              interfaceLabel: interfaceLabel,
              updatedAt: .now,
              isMeasuring: isMeasuring)
    }

    func toggleLiveActivity() async {
        if hasLiveActivity {
            for activity in Activity<SpeedActivityAttributes>.activities {
                await activity.end(ActivityContent(state: state(), staleDate: nil), dismissalPolicy: .immediate)
            }
            hasLiveActivity = false
            lastActivityUpdate = .distantPast
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "Live Activities are disabled. Enable them for Current in iOS Settings."
            return
        }
        do {
            _ = try Activity<SpeedActivityAttributes>.request(
                attributes: SpeedActivityAttributes(),
                content: ActivityContent(state: state(), staleDate: .now.addingTimeInterval(12)),
                pushType: nil
            )
            hasLiveActivity = true
            lastActivityUpdate = .now
        } catch {
            errorMessage = "Could not start Live Activity: \(error.localizedDescription)"
        }
    }

    private func updateActivity(force: Bool = false) async {
        guard hasLiveActivity, !activityUpdatePending else { return }
        if !force && Date().timeIntervalSince(lastActivityUpdate) < activityUpdateInterval { return }
        activityUpdatePending = true
        defer { activityUpdatePending = false }
        let content = ActivityContent(
            state: state(),
            staleDate: isMeasuring ? .now.addingTimeInterval(12) : nil
        )
        for activity in Activity<SpeedActivityAttributes>.activities {
            await activity.update(content)
        }
        lastActivityUpdate = .now
    }
}
