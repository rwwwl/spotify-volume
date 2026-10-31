import SwiftUI

@main
struct SpotifyVolumeApp: App {
    @StateObject private var spotify = SpotifyController()
    @StateObject private var loginItem = LoginItemController()

    var body: some Scene {
        MenuBarExtra("Spotify Volume", systemImage: "speaker.wave.2.fill", isInserted: .constant(spotify.isRunning)) {
            ContentView(spotify: spotify, loginItem: loginItem)
        }
        .menuBarExtraStyle(.window)
    }
}
