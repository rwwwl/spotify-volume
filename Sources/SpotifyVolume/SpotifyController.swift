import AppKit
import Foundation

/// Talks to Spotify via AppleScript. Controls Spotify's own volume, not the system volume.
@MainActor
final class SpotifyController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var volume: Double = 0

    private static let bundleID = "com.spotify.client"
    private static let writeDebounce: TimeInterval = 0.15
    /// After the user touches the slider, ignore polled values for this long so
    /// a stale read can't yank the slider back.
    private static let pollQuietPeriod: TimeInterval = 1.5

    // NSAppleScript isn't thread-safe; funnel every script through one serial queue
    // so we never block the main thread or run two scripts at once.
    private let scriptQueue = DispatchQueue(label: "spotify-volume.applescript")

    private var pollTimer: Timer?
    private var writeTask: Task<Void, Never>?
    private var isDragging = false
    private var lastUserChange = Date.distantPast

    init() {
        refreshRunning()
        updatePolling()

        // Launch/quit notifications drive visibility; the timer only runs while Spotify does.
        let nc = NSWorkspace.shared.notificationCenter
        let spotifyID = Self.bundleID
        for name in [NSWorkspace.didLaunchApplicationNotification,
                     NSWorkspace.didTerminateApplicationNotification] {
            nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
                let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
                guard app?.bundleIdentifier == spotifyID else { return }
                MainActor.assumeIsolated { self?.spotifyStateChanged() }
            }
        }
    }

    private func spotifyStateChanged() {
        refreshRunning()
        updatePolling()
    }

    /// Poll only while Spotify is running; idle otherwise.
    private func updatePolling() {
        if isRunning {
            guard pollTimer == nil else { return }
            poll()
            let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.poll() }
            }
            RunLoop.main.add(timer, forMode: .common)
            pollTimer = timer
        } else {
            pollTimer?.invalidate()
            pollTimer = nil
            writeTask?.cancel()
            writeTask = nil
            isDragging = false
        }
    }

    // MARK: - UI hooks

    func setDragging(_ dragging: Bool) {
        isDragging = dragging
        if !dragging {
            lastUserChange = Date()
            flushWrite()
        }
    }

    func userChangedVolume(_ newValue: Double) {
        volume = newValue
        lastUserChange = Date()
        writeTask?.cancel()
        writeTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.writeDebounce * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.flushWrite()
        }
    }

    // MARK: - Polling

    private func refreshRunning() {
        isRunning = !NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.bundleID).isEmpty
    }

    private func poll() {
        refreshRunning()
        guard isRunning else { return }
        guard !isDragging, writeTask == nil,
              Date().timeIntervalSince(lastUserChange) > Self.pollQuietPeriod else { return }

        run("tell application id \"\(Self.bundleID)\" to return sound volume") { [weak self] result in
            guard let self, let value = result?.int32Value else { return }
            // Re-check: user may have started interacting while the script ran.
            guard !self.isDragging, self.writeTask == nil,
                  Date().timeIntervalSince(self.lastUserChange) > Self.pollQuietPeriod else { return }
            let v = Double(value)
            if v != self.volume { self.volume = v }
        }
    }

    // MARK: - Writing

    private func flushWrite() {
        writeTask?.cancel()
        writeTask = nil
        guard isRunning else { return }
        let target = Int(volume.rounded())
        run("tell application id \"\(Self.bundleID)\" to set sound volume to \(target)") { _ in }
    }

    // MARK: - AppleScript

    private func run(_ source: String, completion: @escaping @MainActor (NSAppleEventDescriptor?) -> Void) {
        scriptQueue.async {
            var error: NSDictionary?
            let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
            if let error { NSLog("AppleScript error: %@", error) }
            DispatchQueue.main.async {
                MainActor.assumeIsolated { completion(error == nil ? result : nil) }
            }
        }
    }
}
