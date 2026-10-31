import SwiftUI

struct ContentView: View {
    @ObservedObject var spotify: SpotifyController
    @ObservedObject var loginItem: LoginItemController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Spotify Volume")
                    .font(.headline)
                Spacer()
                Text(spotify.isRunning ? "\(Int(spotify.volume))" : "–")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                Slider(
                    value: Binding(
                        get: { spotify.volume },
                        set: { spotify.userChangedVolume($0) }
                    ),
                    in: 0...100,
                    step: 1,
                    onEditingChanged: { spotify.setDragging($0) }
                )
                .disabled(!spotify.isRunning)
                Image(systemName: "speaker.wave.3.fill")
            }
            .foregroundStyle(spotify.isRunning ? .primary : .tertiary)

            Divider()

            Toggle("Launch at login", isOn: Binding(
                get: { loginItem.isEnabled },
                set: { loginItem.setEnabled($0) }
            ))
            .toggleStyle(.checkbox)

            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 260)
    }
}
