# Spotify Volume

A macOS menu bar app with a slider that controls **Spotify's own volume** (not the system volume). The icon appears only while Spotify is running. Includes a "Launch at login" toggle and a Quit button.

## Requirements

- macOS 13+
- Swift toolchain (Xcode Command Line Tools is enough)
- Spotify desktop app

## Build and install

```sh
./build.sh
cp -R "build/Spotify Volume.app" /Applications/
```

`build.sh` produces a universal `build/Spotify Volume.app`. It signs ad-hoc by default; to sign with your own certificate:

```sh
SIGN_IDENTITY="Apple Development: Your Name (TEAMID)" ./build.sh
```

The app isn't notarized, so on another Mac you must right-click it and choose Open the first time.

## Permissions

On first use macOS asks to let Spotify Volume control Spotify (Automation). If the prompt doesn't appear, reset it with `tccutil reset AppleEvents com.local.spotify-volume`.

## License

[MIT](LICENSE)
