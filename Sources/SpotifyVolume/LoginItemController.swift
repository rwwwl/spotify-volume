import Foundation
import ServiceManagement

/// Wraps SMAppService.mainApp. Registers on first run, then respects the user's toggle.
@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled = false

    private static let didInitDefaultKey = "didApplyDefaultLaunchAtLogin"

    init() {
        if !UserDefaults.standard.bool(forKey: Self.didInitDefaultKey) {
            UserDefaults.standard.set(true, forKey: Self.didInitDefaultKey)
            setEnabled(true)
        }
        refresh()
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at login change failed: %@", error.localizedDescription)
        }
        refresh()
    }

    private func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}
