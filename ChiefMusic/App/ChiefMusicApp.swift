import SwiftUI
import UniformTypeIdentifiers

@main
struct ChiefMusicApp: App {
    @StateObject private var audioService = AudioService()
    @StateObject private var aiService = AIMusicService()
    @StateObject private var licenseService = LicenseService.shared
    @StateObject private var appState = AppState.shared
    @StateObject private var lang = LanguageManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var toastManager = ToastManager.shared
    @State private var showMiniPlayer = false
    @State private var showLicenseSheet = false

    var body: some Scene {
        WindowGroup {
            Group {
                if licenseService.canUseApp() {
                    ContentView()
                        .environmentObject(audioService)
                        .environmentObject(aiService)
                        .environmentObject(appState)
                        .environmentObject(lang)
                        .environmentObject(themeManager)
                        .environmentObject(toastManager)
                        .environmentObject(licenseService)
                        .frame(minWidth: 1100, minHeight: 700)
                        .onAppear {
                            aiService.audioService = audioService
                            MediaKeyHandler.shared.setup(audioService: audioService)

                            // Show license sheet if trial is about to expire (优化：5天提前提醒)
                            if !licenseService.isActivated && licenseService.trialDaysRemaining <= 5 {
                                showLicenseSheet = true
                            }
                        }
                        .background(MiniPlayerKeyHandler(showMiniPlayer: $showMiniPlayer))
                        .sheet(isPresented: $showLicenseSheet) {
                            LicenseView()
                                .environmentObject(licenseService)
                                .environmentObject(themeManager)
                                .environmentObject(lang)
                        }
                } else {
                    TrialExpiredView()
                        .environmentObject(themeManager)
                        .environmentObject(licenseService)
                        .environmentObject(lang)
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button(lang.t(.shortcutsOpenAudio) + "...") {
                    importAudioViaPanel()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button(lang.t(.importLyrics) + "...") {
                    importLyricsViaPanel()
                }
                .keyboardShortcut("l", modifiers: .command)

                Divider()
            }

            // Edit Menu - Keep default

            // View Menu
            CommandMenu(lang.t(.menuView)) {
                Button(lang.t(.menuMiniPlayer)) {
                    showMiniPlayer.toggle()
                }
                .keyboardShortcut("m", modifiers: .command)
            }

            // Playback Menu
            CommandMenu(lang.t(.menuPlayback)) {
                Button(lang.t(.menuPlayPause)) {
                    audioService.togglePlay()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button(lang.t(.menuPrevious)) {
                    audioService.playPrevious()
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)

                Button(lang.t(.menuNext)) {
                    audioService.playNext()
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)

                Divider()

                Button(lang.t(.menuRewind5s)) {
                    audioService.seek(to: max(0, audioService.currentTime - 5))
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Button(lang.t(.menuForward5s)) {
                    audioService.seek(to: min(audioService.duration, audioService.currentTime + 5))
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Divider()

                Button(lang.t(.menuVolumeUp)) {
                    audioService.increaseVolume()
                }
                .keyboardShortcut(.upArrow, modifiers: [])

                Button(lang.t(.menuVolumeDown)) {
                    audioService.decreaseVolume()
                }
                .keyboardShortcut(.downArrow, modifiers: [])

                Divider()

                Button(lang.t(.menuSpeedUp)) {
                    audioService.increasePlaybackRate()
                }
                .keyboardShortcut(.upArrow, modifiers: .command)

                Button(lang.t(.menuSpeedDown)) {
                    audioService.decreasePlaybackRate()
                }
                .keyboardShortcut(.downArrow, modifiers: .command)

                Button(lang.t(.menuResetSpeed)) {
                    audioService.resetPlaybackRate()
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Button(lang.t(.menuFavorite)) {
                    if let trackId = audioService.currentTrack?.id {
                        audioService.toggleFavorite(trackId)
                    }
                }
                .keyboardShortcut("f", modifiers: [])
            }

            // Help Menu
            CommandGroup(replacing: .help) {
                Button("ChiefMusic 帮助") {
                    if let url = URL(string: "https://github.com/yourusername/chiefmusic") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Button(lang.t(.menuKeyboardShortcuts)) {
                    showKeyboardShortcuts()
                }

                Divider()

                Button(lang.t(.menuLicense)) {
                    showLicenseSheet = true
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])

                if licenseService.isActivated {
                    Text("\(lang.t(.licenseStatus)): \(lang.t(.activated)) (\(licenseService.licenseInfo?.type.displayName ?? ""))")
                        .disabled(true)
                } else if !licenseService.isTrialExpired {
                    Text("试用剩余: \(licenseService.trialDaysRemaining) 天")
                        .disabled(true)
                } else {
                    Text("状态: 试用已过期")
                        .disabled(true)
                }

                Divider()

                Button("检查更新...") {
                    checkForUpdates()
                }

                Divider()

                Button("关于 ChiefMusic") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "ChiefMusic",
                            .applicationVersion: "1.0.0",
                            .version: "Build 1",
                            .credits: NSAttributedString(string: "AI 酋长 Andy 出品\n极简音乐播放器 + AI 音乐生成")
                        ]
                    )
                }
            }
        }
        
        // Mini Player Window
        WindowGroup("Mini Player") {
            MiniPlayerView(isPresented: $showMiniPlayer)
                .environmentObject(audioService)
                .environmentObject(themeManager)
                .onAppear { showMiniPlayer = true }
                .onDisappear { showMiniPlayer = false }
        }
        .defaultSize(width: 280, height: 120)
        .windowResizability(.contentSize)
        
        // Menu Bar Extra
        MenuBarExtra {
            MenuBarPlayerView()
                .environmentObject(audioService)
                .environmentObject(themeManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: audioService.isPlaying ? "waveform.circle.fill" : "waveform.circle")
                    .font(.system(size: 14))
                if audioService.currentTrack != nil {
                    Text(audioService.currentTrack?.title ?? "")
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .frame(maxWidth: 120)
                }
            }
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Helper Functions
    private func importAudioViaPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let urls = panel.urls
            if urls.count == 1, let url = urls.first {
                audioService.importAudio(from: url)
                if audioService.currentIndex == -1 {
                    audioService.currentIndex = audioService.playlist.count - 1
                    audioService.play()
                }
            } else if !urls.isEmpty {
                audioService.importMultipleAudio(from: urls)
                audioService.play()
            }
        }
    }

    private func importLyricsViaPanel() {
        let panel = NSOpenPanel()
        let lrcType = UTType(filenameExtension: "lrc") ?? .plainText
        panel.allowedContentTypes = [.plainText, lrcType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            audioService.importLyrics(from: url)
        }
    }

    private func showKeyboardShortcuts() {
        let alert = NSAlert()
        alert.messageText = lang.t(.shortcutsTitle)
        alert.informativeText = """
        \(lang.t(.shortcutsFileOps)):
        ⌘O - \(lang.t(.shortcutsOpenAudio))
        ⌘L - \(lang.t(.importLyrics))

        \(lang.t(.shortcutsPlaybackControl)):
        \(lang.t(.shortcutSpace)) - \(lang.t(.menuPlayPause))
        ⌘← - \(lang.t(.menuPrevious))
        ⌘→ - \(lang.t(.menuNext))
        ← - \(lang.t(.menuRewind5s))
        → - \(lang.t(.menuForward5s))

        \(lang.t(.shortcutsVolumeControl)):
        ↑ - \(lang.t(.menuVolumeUp))
        ↓ - \(lang.t(.menuVolumeDown))

        \(lang.t(.shortcutsSpeed)):
        ⌘↑ - \(lang.t(.menuSpeedUp)) (0.25x)
        ⌘↓ - \(lang.t(.menuSpeedDown)) (0.25x)
        ⌘0 - \(lang.t(.menuResetSpeed)) (1.0x)

        \(lang.t(.shortcutsOther)):
        F - \(lang.t(.menuFavorite))
        ⌘M - \(lang.t(.menuMiniPlayer))
        ⇧⌘K - \(lang.t(.menuLicense))
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: lang.t(.menuOK))
        alert.runModal()
    }

    private func checkForUpdates() {
        let alert = NSAlert()
        alert.messageText = lang.t(.menuCheckUpdates)
        alert.informativeText = lang.t(.updateMessage)
        alert.alertStyle = .informational
        alert.addButton(withTitle: lang.t(.menuOK))
        alert.runModal()
    }
}

// MARK: - Menu Bar Player
struct MenuBarPlayerView: View {
    @EnvironmentObject var audio: AudioService
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        VStack(spacing: 12) {
            // Track Info
            HStack(spacing: 10) {
                // Mini album art
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(colors.accent.opacity(0.15))
                    if let art = audio.currentAlbumArt {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundColor(colors.accent.opacity(0.4))
                    }
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(audio.currentTrack?.title ?? LanguageManager.shared.t(.notPlaying))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)
                    Text(audio.currentTrack?.artist ?? "")
                        .font(.system(size: 10))
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            
            // Controls
            HStack(spacing: 20) {
                Button(action: { audio.playPrevious() }) {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 14, weight: .light))
                }.buttonStyle(.plain)
                
                Button(action: { audio.togglePlay() }) {
                    Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.accent)
                }.buttonStyle(.plain)
                
                Button(action: { audio.playNext() }) {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 14, weight: .light))
                }.buttonStyle(.plain)
            }
            
            // Volume
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 9))
                    .foregroundColor(colors.textSecondary)
                Slider(value: $audio.volume, in: 0...1)
                    .tint(colors.accent)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 9))
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(
            ZStack {
                if themeManager.current == .glass {
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                    Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                } else {
                    colors.bg
                }
            }
        )
    }
}

// MARK: - ⌘M Key Handler
struct MiniPlayerKeyHandler: NSViewRepresentable {
    @Binding var showMiniPlayer: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "m" {
                showMiniPlayer.toggle()
                return nil
            }
            return event
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
