import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var isDragOver = false
    @State private var eventMonitor: Any?
    @EnvironmentObject var audio: AudioService
    
    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isGlass = themeManager.current == .glass
        
        ZStack {
            // Background
            if isGlass {
                AuroraBackground()
            } else {
                colors.bg.ignoresSafeArea()
            }
            
            HStack(spacing: 0) {
                sidebar.frame(width: 80)
                
                ZStack {
                    if !isGlass { colors.bg.ignoresSafeArea() }

                    switch appState.selectedTab {
                    case .player: PlayerView()
                    case .generator: GeneratorView()
                    case .library: LibraryView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Drag overlay
            if isDragOver {
                dragOverlay
            }
            
            // Toast
            ToastOverlay()
                .environmentObject(themeManager)
        }
        .preferredColorScheme(isGlass ? .dark : .light)
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
        // Drag & Drop
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
        // Keyboard shortcuts — handled via NSEvent monitor (below) to avoid
        // intercepting keys when a text field is focused
        .onAppear {
            if eventMonitor == nil {
                eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    
                    // ⌘ shortcuts always work
                    if flags == .command {
                        switch event.charactersIgnoringModifiers {
                        case "o": importAudioViaPanel(); return nil
                        case "l": importLyricsViaPanel(); return nil
                        default: break
                        }
                    }
                    
                    // Skip Space/Arrow shortcuts when a text field is focused
                    let isTextField = NSApp.mainWindow?.firstResponder is NSTextField
                                      || NSApp.mainWindow?.firstResponder is NSTextView
                                      || String(describing: type(of: NSApp.mainWindow?.firstResponder ?? NSView())).contains("TextEditor")
                    if isTextField { return event }
                    
                    switch event.keyCode {
                    case 49: // Space
                        audio.togglePlay(); return nil
                    case 123: // Left Arrow
                        audio.seek(to: max(0, audio.currentTime - 5)); return nil
                    case 124: // Right Arrow
                        audio.seek(to: min(audio.duration, audio.currentTime + 5)); return nil
                    default: break
                    }
                    
                    return event
                }
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }
    
    // MARK: - Drag Overlay
    private var dragOverlay: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        return ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(colors.accent)
                Text(lang.t(.dragDropHint))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(colors.accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isDragOver)
    }
    
    // MARK: - Drop Handler
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        let audioTypes: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        
        for provider in providers {
            for type in audioTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    provider.loadItem(forTypeIdentifier: type.identifier) { item, error in
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.async {
                                audio.importAudio(from: url)
                                ToastManager.shared.show(icon: "checkmark.circle.fill", LanguageManager.shared.t(.addedToPlaylist), style: .success)
                            }
                        } else if let url = item as? URL {
                            DispatchQueue.main.async {
                                audio.importAudio(from: url)
                                ToastManager.shared.show(icon: "checkmark.circle.fill", LanguageManager.shared.t(.addedToPlaylist), style: .success)
                            }
                        }
                    }
                    return true
                }
            }
            // Fallback: try fileURL
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            audio.importAudio(from: url)
                            ToastManager.shared.show(icon: "checkmark.circle.fill", LanguageManager.shared.t(.addedToPlaylist), style: .success)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    // MARK: - Shared Import
    private func importAudioViaPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let urls = panel.urls
            ToastManager.shared.show(icon: "arrow.down.circle", lang.t(.importing), style: .info)
            if urls.count == 1, let url = urls.first {
                audio.importAudio(from: url)
                if audio.currentIndex == -1 { audio.currentIndex = audio.playlist.count - 1; audio.play() }
            } else if !urls.isEmpty {
                audio.importMultipleAudio(from: urls); audio.play()
            }
        }
    }
    
    private func importLyricsViaPanel() {
        let panel = NSOpenPanel()
        let lrcType = UTType(filenameExtension: "lrc") ?? .plainText
        let mdType = UTType(filenameExtension: "md") ?? .plainText
        panel.allowedContentTypes = [.plainText, lrcType, mdType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            let ext = url.pathExtension.lowercased()
            if ext == "lrc" {
                audio.importLyrics(from: url)
            } else {
                guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
                let lines = content.components(separatedBy: .newlines)
                    .map { $0.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"[*_~`>]"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                let interval = audio.duration > 0 ? audio.duration / Double(max(lines.count, 1)) : 1.0
                audio.currentTrack?.lyrics = lines.enumerated().map { LyricLine(time: interval * Double($0), text: $1) }
            }
        }
    }
    
    // MARK: - Sidebar (enhanced luxury design)
    private var sidebar: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isGlass = themeManager.current == .glass

        return VStack(spacing: Spacing.xl) {
            if let _ = NSImage(named: "AppLogo") {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: CornerRadius.md).stroke(colors.cardBorder, lineWidth: isGlass ? 0.5 : 0))
                    .shadow(color: colors.accent.opacity(0.2), radius: 8, y: 4)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(colors.accent.opacity(0.15))
                    Image(systemName: "music.note")
                        .font(.system(size: IconSize.xlarge))
                        .foregroundColor(colors.accent)
                }
                .frame(width: 52, height: 52)
            }

            Spacer()

            ForEach(AppTab.allCases, id: \.self) { tab in
                VStack(spacing: Spacing.xs) {
                    sidebarBtn(icon: tab.icon, isSelected: appState.selectedTab == tab) {
                        withAnimation(.spring(response: 0.3)) { appState.selectedTab = tab }
                    }
                    Text(tab.localizedLabel)
                        .font(Typography.footnote)
                        .foregroundColor(appState.selectedTab == tab ? colors.accent : colors.textSecondary.opacity(0.7))
                }
            }

            Spacer()

            VStack(spacing: Spacing.xs) {
                Text(lang.t(.brandName)).font(Typography.captionBold).foregroundColor(colors.accent)
                Text(lang.t(.brandSubtitle)).font(Typography.footnote).foregroundColor(colors.textSecondary.opacity(0.6))
            }

            sidebarBtn(icon: "gearshape", isSelected: false) { showSettings = true }
        }
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.md)
        .background(
            Group {
                if isGlass {
                    Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                        .overlay(Rectangle().fill(Color.white.opacity(0.02)))
                } else { colors.bg }
            }
        )
    }
    
    private func sidebarBtn(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isGlass = themeManager.current == .glass

        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: IconSize.large, weight: isSelected ? .medium : .light))
                .foregroundColor(isSelected ? colors.accent : colors.textSecondary.opacity(0.7))
                .frame(width: ButtonSize.large, height: ButtonSize.large)
                .background(
                    Group {
                        if isGlass {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(isSelected ? colors.accent.opacity(0.15) : Color.white.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: CornerRadius.md).stroke(isSelected ? colors.accent.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 0.5))
                        } else {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(colors.bgCard)
                                .shadow(color: isSelected ? colors.shadowDark : .clear, radius: 4, x: -2, y: -2)
                                .shadow(color: isSelected ? colors.shadowLight : .clear, radius: 4, x: 2, y: 2)
                        }
                    }
                )
        }.buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var aiService: AIMusicService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var licenseService: LicenseService
    @Binding var isPresented: Bool
    @State private var acemusicAPIKey: String = ""
    @State private var deepseekAPIKey: String = ""
    @State private var showLicenseView = false
    @State private var showTestResult: Bool = false
    @State private var testResultMessage: String = ""
    @State private var isTesting: Bool = false

    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isGlass = themeManager.current == .glass

        VStack(spacing: 0) {
            HStack {
                Text(lang.t(.settings)).font(.system(size: 18, weight: .bold)).foregroundColor(colors.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(colors.textSecondary.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }.padding(24)

            Divider().opacity(isGlass ? 0.15 : 1)

            ScrollView {
                VStack(spacing: 16) {
                    // Trial Status Banner (only show if in trial and not activated)
                    if !licenseService.isActivated && !licenseService.isTrialExpired {
                        VStack(spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.badge.checkmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(colors.accent)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(lang.t(.trialRemaining))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(colors.textPrimary)
                                        Text("\(licenseService.trialDaysRemaining) \(lang.t(.days))")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(colors.accent)
                                    }
                                    Text("您正在体验完整功能")
                                        .font(.system(size: 11))
                                        .foregroundColor(colors.textSecondary)
                                }

                                Spacer()
                            }

                            HStack(spacing: 10) {
                                Button(action: { showLicenseView = true }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 10))
                                        Text("立即激活")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(
                                            LinearGradient(
                                                colors: [colors.accent, colors.accentSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(action: { showLicenseView = true }) {
                                    Text("查看套餐")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(colors.textPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(colors.buttonBg))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .modifier(GlassCardModifier(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(colors.accent.opacity(0.2), lineWidth: 1)
                        )
                    }

                    settingsRow(icon: "paintbrush", label: lang.t(.theme)) {
                        Picker("", selection: $themeManager.current) {
                            ForEach(AppTheme.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                        }.pickerStyle(.segmented).frame(width: 160)
                    }

                    settingsRow(icon: "globe", label: lang.t(.language)) {
                        Picker("", selection: $lang.current) {
                            Text(lang.t(.chinese)).tag("zh"); Text(lang.t(.english)).tag("en")
                        }.pickerStyle(.segmented).frame(width: 160)
                    }

                    // License Management
                    HStack {
                        Image(systemName: "key").font(.system(size: 14, weight: .light)).foregroundColor(colors.accent).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lang.t(.licenseManagement)).font(.system(size: 13, weight: .medium)).foregroundColor(colors.textPrimary)
                            if licenseService.isActivated {
                                Text("\(lang.t(.activated)) - \(licenseService.licenseInfo?.type.displayName ?? "")").font(.system(size: 10)).foregroundColor(.green)
                            } else if !licenseService.isTrialExpired {
                                Text("\(lang.t(.trialRemaining)) \(licenseService.trialDaysRemaining) \(lang.t(.days))").font(.system(size: 10)).foregroundColor(colors.textSecondary)
                            } else {
                                Text(lang.t(.trialExpired)).font(.system(size: 10)).foregroundColor(.red)
                            }
                        }
                        Spacer()
                        Button(action: { showLicenseView = true }) {
                            Text(lang.t(.manage)).font(.system(size: 11, weight: .medium)).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(colors.accent))
                        }.buttonStyle(.plain)
                    }.padding(14).modifier(GlassCardModifier(cornerRadius: 12))

                    // AceMusic API Key
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "music.note").font(.system(size: 14, weight: .light)).foregroundColor(colors.accent).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AceMusic API Key").font(.system(size: 13, weight: .medium)).foregroundColor(colors.textPrimary)
                                Text(lang.t(.builtInKeyAvailable)).font(.system(size: 10)).foregroundColor(.green)
                            }
                        }
                        Text(lang.t(.advancedUserConfig)).font(.system(size: 10)).foregroundColor(colors.textSecondary)
                        HStack(spacing: 8) {
                            SecureField(lang.t(.leaveEmptyForBuiltIn), text: $acemusicAPIKey)
                                .textFieldStyle(.plain).font(.system(size: 12)).foregroundColor(colors.textPrimary)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(isGlass ? 0.04 : 0)).overlay(RoundedRectangle(cornerRadius: 8).stroke(colors.cardBorder, lineWidth: 0.5)))
                            Button(action: saveAcemusicKey) {
                                Text(lang.t(.apiSave)).font(.system(size: 11, weight: .medium)).foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Capsule().fill(colors.accent))
                            }.buttonStyle(.plain)
                        }
                    }.padding(14).modifier(GlassCardModifier(cornerRadius: 12))

                    // DeepSeek API Key
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.bubble").font(.system(size: 14, weight: .light)).foregroundColor(colors.accent).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DeepSeek API Key").font(.system(size: 13, weight: .medium)).foregroundColor(colors.textPrimary)
                                Text(lang.t(.builtInKeyAvailable)).font(.system(size: 10)).foregroundColor(.green)
                            }
                        }
                        Text(lang.t(.advancedUserConfig)).font(.system(size: 10)).foregroundColor(colors.textSecondary)
                        HStack(spacing: 8) {
                            SecureField(lang.t(.leaveEmptyForBuiltIn), text: $deepseekAPIKey)
                                .textFieldStyle(.plain).font(.system(size: 12)).foregroundColor(colors.textPrimary)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(isGlass ? 0.04 : 0)).overlay(RoundedRectangle(cornerRadius: 8).stroke(colors.cardBorder, lineWidth: 0.5)))
                            Button(action: saveDeepseekKey) {
                                Text(lang.t(.apiSave)).font(.system(size: 11, weight: .medium)).foregroundColor(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Capsule().fill(colors.accent))
                            }.buttonStyle(.plain)
                        }
                        HStack(spacing: 8) {
                            Button(action: testDeepseekKey) {
                                HStack {
                                    if isTesting {
                                        ProgressView().scaleEffect(0.6).tint(.white)
                                    } else {
                                        Text(deepseekAPIKey.isEmpty ? lang.t(.testBuiltInKey) : lang.t(.testCustomKey)).font(.system(size: 11, weight: .medium))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(Color.green))
                            }.buttonStyle(.plain).disabled(isTesting)

                            if showTestResult {
                                Text(testResultMessage)
                                    .font(.system(size: 10))
                                    .foregroundColor(testResultMessage.contains("✅") ? .green : .red)
                            }
                        }
                    }.padding(14).modifier(GlassCardModifier(cornerRadius: 12))

                    HStack {
                        Image(systemName: "info.circle").font(.system(size: 14, weight: .light)).foregroundColor(colors.accent).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ChiefMusic").font(.system(size: 13, weight: .medium)).foregroundColor(colors.textPrimary)
                            Text(lang.t(.brandName) + " " + lang.t(.brandSubtitle)).font(.system(size: 10, weight: .medium)).foregroundColor(colors.accent.opacity(0.8))
                            Text("v1.0.0").font(.system(size: 10)).foregroundColor(colors.textSecondary.opacity(0.6))
                        }
                        Spacer()
                    }.padding(14).modifier(GlassCardModifier(cornerRadius: 12))
                }.padding(24)
            }
        }
        .frame(width: 500, height: 600)
        .background(Group { if isGlass { ZStack { Color(red: 0.06, green: 0.06, blue: 0.1); Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark) } } else { colors.bg } })
        .preferredColorScheme(isGlass ? .dark : .light)
        .onAppear(perform: loadKeys)
        .sheet(isPresented: $showLicenseView) {
            LicenseView()
                .environmentObject(licenseService)
                .environmentObject(themeManager)
        }
    }

    private func loadKeys() {
        acemusicAPIKey = UserDefaults.standard.string(forKey: "acemusic_api_key") ?? ""
        deepseekAPIKey = UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
    }

    private func saveAcemusicKey() {
        UserDefaults.standard.set(acemusicAPIKey, forKey: "acemusic_api_key")
        let message = "AceMusic \(lang.t(.apiKeySaved))"
        ToastManager.shared.show(icon: "checkmark.circle.fill", message, style: .success)
    }

    private func saveDeepseekKey() {
        UserDefaults.standard.set(deepseekAPIKey, forKey: "deepseek_api_key")
        let message = "DeepSeek \(lang.t(.apiKeySaved))"
        ToastManager.shared.show(icon: "checkmark.circle.fill", message, style: .success)
    }

    private func testDeepseekKey() {
        // Use custom key if provided, otherwise use built-in key
        let keyToTest = deepseekAPIKey.isEmpty ? SecurityConfig.defaultAPIKey : deepseekAPIKey

        guard !keyToTest.isEmpty else {
            showTestResult = true
            testResultMessage = lang.t(.noAvailableKey)
            return
        }

        isTesting = true
        showTestResult = false

        guard let url = URL(string: "https://api.deepseek.com/v1/chat/completions") else {
            isTesting = false
            showTestResult = true
            testResultMessage = lang.t(.invalidURL)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(keyToTest)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": "Hello"]
            ],
            "max_tokens": 10
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTesting = false
                showTestResult = true

                if let error = error {
                    testResultMessage = String(format: lang.t(.connectionFailed), error.localizedDescription)
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    testResultMessage = lang.t(.invalidResponse)
                    return
                }

                if httpResponse.statusCode == 200 {
                    let keyType = deepseekAPIKey.isEmpty ? lang.t(.builtIn) : lang.t(.custom)
                    testResultMessage = String(format: lang.t(.keyAvailable), keyType)
                } else if httpResponse.statusCode == 401 {
                    testResultMessage = lang.t(.keyInvalid)
                } else {
                    testResultMessage = String(format: lang.t(.errorCode), httpResponse.statusCode)
                }

                // Auto-hide after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showTestResult = false
                }
            }
        }.resume()
    }

    private func settingsRow<Content: View>(icon: String, label: String, @ViewBuilder content: () -> Content) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        return HStack {
            Image(systemName: icon).font(.system(size: 14, weight: .light)).foregroundColor(colors.accent).frame(width: 24)
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(colors.textPrimary)
            Spacer()
            content()
        }.padding(14).modifier(GlassCardModifier(cornerRadius: 12))
    }
}

// MARK: - Tab Extensions
extension AppTab {
    var icon: String {
        switch self {
        case .player: return "play.fill"
        case .generator: return "sparkles"
        case .library: return "square.stack"
        }
    }
    var localizedLabel: String {
        let lang = LanguageManager.shared
        switch self {
        case .player: return lang.t(.play)
        case .generator: return lang.t(.create)
        case .library: return lang.t(.library)
        }
    }
}
