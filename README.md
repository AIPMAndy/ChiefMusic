# 🎵 ChiefMusic

A minimalist neumorphic music player for macOS with AI music generation.

## Features

- **Music Playback** — Play local audio files with synced LRC lyrics
- **AI Music Generation** — Describe what you want to hear, powered by ACE-Step API
- **Share Cards** — Generate beautiful shareable music cards
- **License System** — 7-day free trial with activation code support

## Design

Minimalist neumorphism (soft UI) — warm gray tones, subtle shadows, clean typography.

## Setup

```bash
# Install xcodegen (if not installed)
brew install xcodegen

# Generate Xcode project & open
./setup.sh
open ChiefMusic.xcodeproj
```

Then press ⌘R in Xcode to build and run.

## Architecture

```
ChiefMusic/
├── App/                  # App entry + theme
├── Views/
│   ├── Player/           # Music playback + lyrics
│   ├── Generator/        # AI music generation
│   ├── Share/            # Share card creator
│   └── Components/       # Neumorphic UI components
├── Models/               # Data models
├── Services/
│   ├── AudioService.swift    # AVAudioPlayer wrapper
│   ├── AIMusicService.swift  # ACE-Step API client
│   └── LRCParser.swift       # LRC lyrics parser
└── Assets.xcassets/
```

## API Integration

Uses ACE-Step API for AI music generation. Set your API key in the Create tab's settings.

## License & Activation

ChiefMusic includes a 7-day free trial. For activation codes and licensing information, see [LICENSE_GUIDE.md](LICENSE_GUIDE.md).

Generate activation codes:
```bash
swift generate_license.swift personal
```

## Requirements

- macOS 14.0+
- Xcode 16.0+
- Swift 5.9+

---

> 本项目由 **AI 酋长 Andy**（[@AIPMAndy](https://github.com/AIPMAndy)）开源。开源版已移除授权服务器地址、授权密钥和内置的 AI API Key，使用前请在 `LicenseService.swift` / `SecurityConfig.swift` 中填写你自己的配置，或在应用设置里填写自己的 API Key。
