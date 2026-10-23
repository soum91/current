import ActivityKit
import Foundation
import Network
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
    @Published private(set) var activityStatus = "Off"
    @Published private(set) var activityTransitioning = false
    @Published private(set) var backgroundLocationActive = false
    @Published private(set) var backgroundLocationStatus = "Off"
    @Published var errorMessage: String?
    @Published var unit: SpeedUnit {
        didSet {
            UserDefaults.standard.set(unit.rawValue, forKey: "speedUnit")
            publishWidgetSnapshot(force: true)
            Task { await updateActivity(force: true) }
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
    @Published var backgroundModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundModeEnabled, forKey: "backgroundAlwaysModeEnabled")
            syncBackgroundLocation()
        }
    }

    private let backgroundLocation = BackgroundLocationController()
    private var pathMonitor: NWPathMonitor?
    private var measuringTask: Task<Void, Never>?
    private var previous: [String: InterfaceSampler.Counters]?
    private var previousDate: Date?
    private var lastActivityUpdate = Date.distantPast
    private var activityUpdatePending = false
    private var lastWidgetSnapshot = Date.distantPast
    private var lastWidgetReload = Date.distantPast
    private var lastActivityStateCheck = Date.distantPast
    private var isInBackground = false
    private var trackedActivity: Activity<SpeedActivityAttributes>?
    private var activityStateObserver: Task<Void, Never>?

    init() {
        self.unit = SpeedUnit(rawValue: UserDefaults.standard.string(forKey: "speedUnit") ?? "bytes") ?? .bytes
        let savedSampleInterval = UserDefaults.standard.double(forKey: "sampleInterval")
        self.sampleInterval = [0.25, 0.5, 1.0, 2.0].contains(savedSampleInterval) ? savedSampleInterval : 0.5
        let savedActivityInterval = UserDefaults.standard.double(forKey: "activityUpdateInterval")
        self.activityUpdateInterval = [0.5, 1.0, 2.0, 5.0].contains(savedActivityInterval) ? savedActivityInterval : 1.0
        // Do not silently reuse the old experimental location preference.
        self.backgroundModeEnabled = UserDefaults.standard.bool(forKey: "backgroundAlwaysModeEnabled")
        refreshActivityStatus()
        backgroundLocation.onStatusChange = { [weak self] running, status in
            guard let self else { return }
            self.backgroundLocationActive = running
            self.backgroundLocationStatus = status
            if !running && self.isInBackground { self.pauseMeasuring() }
        }
        backgroundLocation.onLocationUpdate = { [weak self] in
            guard let self, self.isInBackground, self.isMeasuring else { return }
            self.poll()
        }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let label: String
            if path.status != .satisfied {
                label = "No connection"
            } else {
                switch (path.usesInterfaceType(.wifi), path.usesInterfaceType(.cellular)) {
                case (true, true): label = "Wi-Fi + Cellular"
                case (true, false): label = "Wi-Fi"
                case (false, true): label = "Cellular"
                default: label = "Connected"
                }
            }
            Task { @MainActor [weak self] in
                self?.interfaceLabel = label
            }
        }
        pathMonitor = monitor
        monitor.start(queue: DispatchQueue(label: "com.soum91.current.network-path"))
    }

    deinit {
        pathMonitor?.cancel()
        activityStateObserver?.cancel()
    }

    func startMeasuring() {
        refreshActivityStatus()
        if !isInBackground { syncBackgroundLocation() }
        guard measuringTask == nil else { return }
        previous = InterfaceSampler.snapshot()
        previousDate = .now
        isMeasuring = true
        restartPollingTask()
        publishWidgetSnapshot(force: true)
        Task { await updateActivity(force: true) }
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
        if backgroundModeEnabled {
            if !isInBackground { backgroundLocation.enable() }
        } else {
            backgroundLocation.disable()
            if isInBackground { pauseMeasuring() }
        }
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
        if now.timeIntervalSince(lastActivityStateCheck) >= 2 {
            refreshActivityStatus()
            lastActivityStateCheck = now
        }
        let current = InterfaceSampler.snapshot()
        defer {
            previous = current
            previousDate = now
        }
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

    private func isOngoing(_ activity: Activity<SpeedActivityAttributes>) -> Bool {
        switch activity.activityState {
        case .active, .stale: return true
        case .ended, .dismissed: return false
        @unknown default: return true
        }
    }

    private func currentActivity() -> Activity<SpeedActivityAttributes>? {
        // ActivityKit hands us an Activity when request() succeeds. Its global
        // activities array can lag behind that request, so retain the handle.
        if let trackedActivity, isOngoing(trackedActivity) { return trackedActivity }
        return Activity<SpeedActivityAttributes>.activities.first(where: isOngoing)
    }

    private func track(_ activity: Activity<SpeedActivityAttributes>) {
        guard trackedActivity?.id != activity.id else { return }
        activityStateObserver?.cancel()
        trackedActivity = activity
        activityStateObserver = Task { [weak self] in
            for await _ in activity.activityStateUpdates {
                guard let self else { break }
                self.refreshActivityStatus()
            }
        }
    }

    private func refreshActivityStatus() {
        let live = currentActivity()
        if let live {
            track(live)
        } else {
            activityStateObserver?.cancel()
            activityStateObserver = nil
            trackedActivity = nil
        }
        hasLiveActivity = live != nil
        switch live?.activityState {
        case .active: activityStatus = "Active in ActivityKit"
        case .stale: activityStatus = "Stale: waiting for an update"
        case .ended, .dismissed: activityStatus = "Off"
        default:
            activityStatus = ActivityAuthorizationInfo().areActivitiesEnabled
                ? (live == nil ? "Off" : "Waiting for ActivityKit")
                : "Live Activities disabled in iOS Settings"
        }
    }

    func toggleLiveActivity() async {
        guard !activityTransitioning else { return }
        activityTransitioning = true
        defer { activityTransitioning = false }
        refreshActivityStatus()
        if hasLiveActivity {
            await endLiveActivities()
            return
        }

        await requestLiveActivity()
    }

    func restartLiveActivity() async {
        guard !activityTransitioning else { return }
        activityTransitioning = true
        defer { activityTransitioning = false }
        await endLiveActivities()
        // Give ActivityKit time to retire the previous request before replacing it.
        try? await Task.sleep(nanoseconds: 250_000_000)
        await requestLiveActivity()
    }

    private func endLiveActivities() async {
        var activities = Activity<SpeedActivityAttributes>.activities
        if let trackedActivity, !activities.contains(where: { $0.id == trackedActivity.id }) {
            activities.append(trackedActivity)
        }
        for activity in activities {
            await activity.end(ActivityContent(state: state(), staleDate: nil), dismissalPolicy: .immediate)
        }
        activityStateObserver?.cancel()
        activityStateObserver = nil
        trackedActivity = nil
        hasLiveActivity = false
        activityStatus = "Off"
        lastActivityUpdate = .distantPast
    }

    private func requestLiveActivity() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            errorMessage = "Live Activities are disabled. Enable them for Current in iOS Settings."
            refreshActivityStatus()
            return
        }
        do {
            let activity = try Activity<SpeedActivityAttributes>.request(
                attributes: SpeedActivityAttributes(),
                content: ActivityContent(state: state(), staleDate: .now.addingTimeInterval(12)),
                pushType: nil
            )
            track(activity)
            hasLiveActivity = true
            activityStatus = "Requested: \(activity.activityState)"
            lastActivityUpdate = .now
        } catch {
            errorMessage = "Could not start Live Activity: \(error.localizedDescription)"
            refreshActivityStatus()
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
        var activities = Activity<SpeedActivityAttributes>.activities.filter(isOngoing)
        if let trackedActivity, isOngoing(trackedActivity),
           !activities.contains(where: { $0.id == trackedActivity.id }) {
            activities.append(trackedActivity)
        }
        guard !activities.isEmpty else {
            refreshActivityStatus()
            return
        }
        for activity in activities {
            await activity.update(content)
        }
        lastActivityUpdate = .now
    }
}
