# JustPlay

JustPlay is a native macOS menu bar app for local audio playback.

## Features

- Menu bar playback controls
- Native macOS Preferences window
- Configurable global shortcuts
- Recent files history
- Floating playback window with:
  - Transport controls
  - Seek slider
  - Volume control
  - Adjustable opacity
- Finder Open With support for common audio formats
- Optional auto-play when files are opened from Finder
- Optional open at login support

## Requirements

- macOS 13.0+
- Xcode 15+
- XcodeGen 2.38.0+

Install XcodeGen if needed:

```bash
brew install xcodegen
```

## Build

From the repository root:

```bash
xcodegen generate
xcodebuild -project JustPlay.xcodeproj -scheme JustPlay -configuration Debug -derivedDataPath /tmp/JustPlay-DerivedData build
```

The built app will be located at:

```text
/tmp/JustPlay-DerivedData/Build/Products/Debug/JustPlay.app
```

## Install to /Applications

```bash
rm -rf /Applications/JustPlay.app
ditto /tmp/JustPlay-DerivedData/Build/Products/Debug/JustPlay.app /Applications/JustPlay.app
```

## Development Scripts

### Bump version

```bash
bash scripts/bump-version.sh
```

This updates:

- `MARKETING_VERSION` in `project.yml`
- `CURRENT_PROJECT_VERSION` in `project.yml`

### Generate icon assets

```bash
zsh scripts/generate-icons.sh
```

This generates app/document icon PNG sets from:

- `JustPlay/Resources/AppIcon.svg`
- `JustPlay/Resources/DocumentIcon.svg`

## Signing

Local signing settings are stored in:

- `JustPlay/Config/Signing.xcconfig` (gitignored)

Template:

- `JustPlay/Config/Signing.xcconfig.example`

Do not commit machine-specific signing values.

## Privacy

JustPlay processes audio files locally. It does not use cloud services or telemetry.
