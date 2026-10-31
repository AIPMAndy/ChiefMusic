import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct PlayerView: View {
    @EnvironmentObject var audio: AudioService
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showShareSheet = false
    @State private var showPlaylist = true
    @State private var showLyrics = false
    @State private var showHistory = false  // 新增：播放历史
    @State private var isEditingTitle = false
    @State private var isEditingArtist = false
    @State private var editedTitle = ""
    @State private var editedArtist = ""
    @State private var showClearPlaylistAlert = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Controls (balanced width for better layout)
            VStack(spacing: 24) {
                albumArt
                Spacer().frame(height: 6)

                // 空状态优化：显示欢迎引导
                if audio.currentTrack == nil && audio.playlist.isEmpty {
                    emptyStateView
                } else {
                    trackInfo
                }

                Spacer().frame(height: 2)
                progressBar
                Spacer().frame(height: 6)
                transportControls
                Spacer().frame(height: 2)
                toggleRow
            }
            .frame(width: 360)
            .padding(.vertical, 36)
            .padding(.horizontal, 28)
            
            divider
            
            HStack(spacing: 0) {
                if showPlaylist {
                    playlistPanel.frame(width: 260)
                    divider
                }
                if showHistory {
                    historyPanel.frame(width: 260)
                    divider
                }
                if showLyrics { lyricsPanel }
                if !showPlaylist && !showLyrics && !showHistory {
                    VStack(spacing: 12) {
                        Spacer()
                        miniToggle(icon: "list.bullet", text: LanguageManager.shared.t(.playlist)) { withAnimation { showPlaylist = true } }
                        miniToggle(icon: "clock.arrow.circlepath", text: lang.t(.playHistory)) { withAnimation { showHistory = true } }
                        miniToggle(icon: "text.alignleft", text: LanguageManager.shared.t(.lyrics)) { withAnimation { showLyrics = true } }
                        Spacer()
                    }.frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showShareSheet) { ShareView(isPresented: $showShareSheet) }
        .alert(isPresented: $showClearPlaylistAlert) {
            Alert(
                title: Text(lang.t(.clearPlaylistTitle)),
                message: Text(String(format: lang.t(.clearPlaylistMessage), audio.playlist.count)),
                primaryButton: .destructive(Text(lang.t(.clearPlaylist))) {
                    audio.clearPlaylist()
                },
                secondaryButton: .cancel(Text(lang.t(.cancel)))
            )
        }
    }
    
    // MARK: - Album Art (200px, balanced luxury size)
    private var albumArt: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return ZStack {
            // Outer glow
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [colors.accent.opacity(0.12), colors.accentSecondary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blur(radius: 16)
                .offset(y: 6)

            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, themeManager.current == .glass ? .dark : .light)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(colors.cardBorder, lineWidth: 0.5))
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [colors.accent.opacity(0.12), colors.accentSecondary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing))

            if let art = audio.currentAlbumArt {
                // Real album art with enhanced presentation
                Image(nsImage: art)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            } else if audio.isPlaying {
                // Enhanced visualization when playing
                ZStack {
                    // Background circular spectrum
                    CircularSpectrumView()
                        .frame(width: 160, height: 160)

                    // Center waveform
                    WaveformView()
                        .frame(width: 90, height: 90)
                }
            } else {
                Image(systemName: "waveform")
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(colors.accent.opacity(0.2))
            }
        }
        .frame(width: 200, height: 200)
        .shadow(color: colors.accent.opacity(0.12), radius: 24, y: 12)
    }
    
    // MARK: - Track Info (refined typography)
    private var trackInfo: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return VStack(spacing: Spacing.xs) {
            // Editable Title
            if isEditingTitle {
                TextField("", text: $editedTitle, onCommit: {
                    saveTitle()
                })
                .font(Typography.title3)
                .foregroundColor(colors.textPrimary)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(RoundedRectangle(cornerRadius: CornerRadius.sm).fill(colors.buttonBg))
                .onAppear { editedTitle = audio.currentTrack?.title ?? "" }
            } else {
                Text(audio.currentTrack?.title ?? lang.t(.noTrack))
                    .font(Typography.title3)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        if audio.currentTrack != nil {
                            editedTitle = audio.currentTrack?.title ?? ""
                            isEditingTitle = true
                        }
                    }
            }

            // Editable Artist
            if isEditingArtist {
                TextField("", text: $editedArtist, onCommit: {
                    saveArtist()
                })
                .font(Typography.caption)
                .foregroundColor(colors.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(RoundedRectangle(cornerRadius: CornerRadius.sm).fill(colors.buttonBg))
                .onAppear { editedArtist = audio.currentTrack?.artist ?? "" }
            } else {
                Text(audio.currentTrack?.artist ?? " ")
                    .font(Typography.caption)
                    .foregroundColor(colors.textSecondary.opacity(0.7))
                    .onTapGesture {
                        if audio.currentTrack != nil {
                            editedArtist = audio.currentTrack?.artist ?? ""
                            isEditingArtist = true
                        }
                    }
            }

            if let track = audio.currentTrack, !track.qualityDescription.isEmpty {
                Text(track.qualityDescription)
                    .font(Typography.footnote)
                    .foregroundColor(colors.textSecondary.opacity(0.4))
                    .padding(.top, Spacing.xs)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Empty State (欢迎引导)
    private var emptyStateView: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return VStack(spacing: Spacing.md) {
            Text(lang.t(.welcomeTitle))
                .font(Typography.title2)
                .foregroundColor(colors.textPrimary)

            Text(lang.t(.welcomeSubtitle))
                .font(Typography.body)
                .foregroundColor(colors.textSecondary)

            Text(lang.t(.welcomeValueProp))
                .font(Typography.caption)
                .foregroundColor(colors.accent)
                .padding(.top, 2)

            Button(action: {
                ToastManager.shared.show(icon: "sparkles", lang.t(.navigatingToGenerator), style: .info)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AppState.shared.switchToGenerator()
                }
            }) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(Typography.body)
                    Text(lang.t(.createNow))
                        .font(Typography.bodyBold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: colors.accent.opacity(0.3), radius: 12, y: 6)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, Spacing.sm)

            Text(lang.t(.orImportLocalMusic))
                .font(Typography.footnote)
                .foregroundColor(colors.textSecondary.opacity(0.6))
                .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private func saveTitle() {
        guard let track = audio.currentTrack, !editedTitle.isEmpty else {
            isEditingTitle = false
            return
        }
        audio.updateTrackMetadata(track.id, title: editedTitle, artist: nil)
        isEditingTitle = false
        ToastManager.shared.show(icon: "checkmark.circle.fill", lang.t(.titleUpdated), style: .success)
    }
    
    private func saveArtist() {
        guard let track = audio.currentTrack, !editedArtist.isEmpty else {
            isEditingArtist = false
            return
        }
        audio.updateTrackMetadata(track.id, title: nil, artist: editedArtist)
        isEditingArtist = false
        ToastManager.shared.show(icon: "checkmark.circle.fill", lang.t(.artistUpdated), style: .success)
    }
    
    // MARK: - Progress Bar (enhanced with better spacing)
    private var progressBar: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return VStack(spacing: Spacing.xs) {
            Slider(value: Binding(get: { audio.currentTime }, set: { audio.seek(to: $0) }), in: 0...max(audio.duration, 1))
                .tint(colors.accent)
            HStack {
                Text(fmtTime(audio.currentTime))
                Spacer()
                Text(fmtTime(audio.duration))
            }
            .font(Typography.footnote)
            .foregroundColor(colors.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, Spacing.md)
    }
    
    // MARK: — Transport Controls (refined balance)
    private var transportControls: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return VStack(spacing: Spacing.lg) {
            // Main controls row
            HStack(spacing: Spacing.lg) {
                // Mode toggle (small)
                Button(action: { audio.cyclePlaybackMode() }) {
                    Image(systemName: audio.playbackMode.icon)
                        .font(.system(size: IconSize.small, weight: .light))
                        .foregroundColor(audio.playbackMode == .sequential ? colors.textSecondary.opacity(0.4) : colors.accent.opacity(0.7))
                        .frame(width: ButtonSize.small, height: ButtonSize.small)
                        .background(
                            Circle()
                                .fill(themeManager.current == .glass ? Color.white.opacity(0.03) : colors.bgCard)
                                .overlay(Circle().strokeBorder(colors.cardBorder, lineWidth: themeManager.current == .glass ? 0.5 : 0))
                        )
                }.buttonStyle(ScaleButtonStyle())

                // EQ toggle - 隐藏未实现的功能
                // Button(action: { audio.cycleEQ() }) { ... }

                // Prev (medium)
                secondaryBtn(icon: "backward.end.fill", label: lang.t(.previous)) { audio.playPrevious() }

                // ★ PLAY — Hero button
                Button(action: { audio.togglePlay() }) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: colors.accent.opacity(0.35), radius: 18, y: 9)
                        Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: IconSize.hero, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: audio.isPlaying ? 0 : 2)
                    }
                    .frame(width: ButtonSize.hero, height: ButtonSize.hero)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(audio.isPlaying ? lang.t(.pause) : lang.t(.play))
                .help(lang.t(.shortcutPlayPause))

                // Next (medium)
                secondaryBtn(icon: "forward.end.fill", label: lang.t(.next)) { audio.playNext() }

                // Favorite button (medium)
                Button(action: {
                    if let trackId = audio.currentTrack?.id {
                        audio.toggleFavorite(trackId)
                    }
                }) {
                    Image(systemName: audio.currentTrack != nil && audio.isFavorite(audio.currentTrack!.id) ? "heart.fill" : "heart")
                        .font(.system(size: IconSize.medium, weight: .light))
                        .foregroundColor(audio.currentTrack != nil && audio.isFavorite(audio.currentTrack!.id) ? .red : colors.textPrimary.opacity(0.6))
                        .frame(width: ButtonSize.medium, height: ButtonSize.medium)
                        .background(
                            Circle()
                                .fill(themeManager.current == .glass ? Color.white.opacity(0.05) : colors.bgCard)
                                .overlay(Circle().strokeBorder(colors.cardBorder, lineWidth: themeManager.current == .glass ? 0.5 : 0))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .help(lang.t(.favoriteTooltip))

                // Share (small)
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: IconSize.small, weight: .light))
                        .foregroundColor(colors.textPrimary.opacity(0.6))
                        .frame(width: ButtonSize.small, height: ButtonSize.small)
                        .background(
                            Circle()
                                .fill(themeManager.current == .glass ? Color.white.opacity(0.05) : colors.bgCard)
                                .overlay(Circle().strokeBorder(colors.cardBorder, lineWidth: themeManager.current == .glass ? 0.5 : 0))
                        )
                }.buttonStyle(ScaleButtonStyle())
            }

            // Volume and Speed controls
            HStack(spacing: Spacing.xl) {
                // Volume control
                HStack(spacing: Spacing.sm) {
                    Image(systemName: audio.volume == 0 ? "speaker.slash.fill" : audio.volume < 0.3 ? "speaker.wave.1.fill" : audio.volume < 0.7 ? "speaker.wave.2.fill" : "speaker.wave.3.fill")
                        .font(.system(size: IconSize.medium))
                        .foregroundColor(colors.textSecondary.opacity(0.6))
                        .frame(width: 20)

                    Slider(value: Binding(
                        get: { audio.volume },
                        set: { audio.setVolume($0) }
                    ), in: 0...1)
                        .tint(colors.accent)
                        .frame(width: 110)
                }

                // Playback speed control
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "gauge")
                        .font(.system(size: IconSize.medium))
                        .foregroundColor(colors.textSecondary.opacity(0.6))
                        .frame(width: 20)

                    Button(action: { audio.decreasePlaybackRate() }) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: IconSize.large))
                            .foregroundColor(colors.textSecondary.opacity(0.6))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Text(String(format: "%.1fx", audio.playbackRate))
                        .font(Typography.caption)
                        .foregroundColor(colors.textPrimary)
                        .frame(width: 42)

                    Button(action: { audio.increasePlaybackRate() }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: IconSize.large))
                            .foregroundColor(colors.textSecondary.opacity(0.6))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .help(lang.t(.playbackSpeedTooltip))
            }
            .padding(.horizontal, Spacing.sm)
        }
    }
    
    private func secondaryBtn(icon: String, label: String, action: @escaping () -> Void) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: IconSize.medium, weight: .light))
                .foregroundColor(colors.textPrimary.opacity(0.6))
                .frame(width: ButtonSize.medium, height: ButtonSize.medium)
                .background(
                    Circle()
                        .fill(themeManager.current == .glass ? Color.white.opacity(0.05) : colors.bgCard)
                        .overlay(Circle().strokeBorder(colors.cardBorder, lineWidth: themeManager.current == .glass ? 0.5 : 0))
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
    }
    
    // MARK: - Toggle Row
    private var toggleRow: some View {
        HStack(spacing: 6) {
            panelToggle(LanguageManager.shared.t(.playlist), icon: "list.bullet", isOn: showPlaylist) { withAnimation { showPlaylist.toggle(); if showPlaylist { showHistory = false } } }
            panelToggle(lang.t(.historyLabel), icon: "clock.arrow.circlepath", isOn: showHistory) { withAnimation { showHistory.toggle(); if showHistory { showPlaylist = false } } }
            panelToggle(LanguageManager.shared.t(.lyrics), icon: "text.alignleft", isOn: showLyrics) { withAnimation { showLyrics.toggle() } }
            Spacer()
            // Shortcut hints
            HStack(spacing: 8) {
                shortcutHint("Space", description: lang.t(.shortcutPlayPause))
                shortcutHint("← →", description: lang.t(.shortcutSeek))
                shortcutHint("⌘O", description: lang.t(.shortcutImport))
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func panelToggle(_ label: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        return Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon).font(.system(size: IconSize.small, weight: .medium))
                Text(label).font(Typography.footnote)
            }
            .foregroundColor(isOn ? colors.accent : colors.textSecondary.opacity(0.5))
            .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(isOn ? colors.accent.opacity(0.1) : Color.clear)
                    .overlay(Capsule().strokeBorder(isOn ? colors.accent.opacity(0.2) : colors.cardBorder, lineWidth: 0.5))
            )
        }.buttonStyle(.plain)
    }
    
    private func shortcutHint(_ text: String, description: String) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        return Text(text)
            .font(.system(size: IconSize.small, weight: .medium, design: .monospaced))
            .foregroundColor(colors.textSecondary.opacity(0.3))
            .padding(.horizontal, Spacing.xs).padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.04)))
            .help(description)
    }

    private func miniToggle(icon: String, text: String, action: @escaping () -> Void) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        return Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon).font(.system(size: IconSize.medium, weight: .light))
                Text(text).font(Typography.footnote)
            }
            .foregroundColor(colors.accent)
            .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
            .modifier(GlassCardModifier(cornerRadius: 10))
        }.buttonStyle(.plain)
    }
    
    // MARK: - Playlist
    private var playlistPanel: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(LanguageManager.shared.t(.playlist)).font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                Text("\(audio.playlist.count)").font(.system(size: 10, design: .monospaced)).foregroundColor(colors.textSecondary.opacity(0.5))
                Button(action: { importAudio() }) {
                    Image(systemName: "plus").font(.system(size: 11, weight: .light)).foregroundColor(colors.accent.opacity(0.7)).frame(width: 24, height: 24)
                }.buttonStyle(.plain)
                if !audio.playlist.isEmpty {
                    Button(action: { showClearPlaylistAlert = true }) {
                        Image(systemName: "trash").font(.system(size: 10, weight: .light)).foregroundColor(colors.textSecondary.opacity(0.3)).frame(width: 24, height: 24)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 14).padding(.vertical, 10)
            
            divider
            
            if audio.playlist.isEmpty {
                VStack(spacing: Spacing.md) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(colors.textSecondary.opacity(0.2))

                    VStack(spacing: Spacing.xs) {
                        Text(lang.t(.playlistEmpty))
                            .font(Typography.body)
                            .foregroundColor(colors.textSecondary.opacity(0.5))
                        Text(lang.t(.startCreatingOrImport))
                            .font(Typography.footnote)
                            .foregroundColor(colors.textSecondary.opacity(0.3))
                    }

                    VStack(spacing: Spacing.sm) {
                        Button(action: {
                            ToastManager.shared.show(icon: "sparkles", lang.t(.navigatingToGenerator), style: .info)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                AppState.shared.switchToGenerator()
                            }
                        }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: IconSize.small))
                                Text(lang.t(.createNow))
                                    .font(Typography.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing))
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button(action: { importAudio() }) {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: IconSize.small))
                                Text(lang.t(.importMusic))
                                    .font(Typography.caption)
                            }
                            .foregroundColor(colors.accent)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .strokeBorder(colors.accent.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.top, Spacing.sm)

                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(audio.playlist.enumerated()), id: \.element.id) { index, track in
                            playlistRow(track: track, index: index)
                        }
                    }.padding(.vertical, 4)
                }
            }
        }
    }
    
    private func playlistRow(track: Track, index: Int) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isCurrent = index == audio.currentIndex
        
        return HStack(spacing: 10) {
            ZStack {
                Text("\(index + 1)").font(.system(size: 9, design: .monospaced)).foregroundColor(colors.textSecondary.opacity(0.25))
                    .opacity(isCurrent ? 0 : 1)
                if isCurrent {
                    Image(systemName: audio.isPlaying ? "waveform" : "play.fill")
                        .font(.system(size: 9, weight: .medium)).foregroundColor(colors.accent)
                }
            }.frame(width: 20)
            
            Text(track.title)
                .font(.system(size: 11, weight: isCurrent ? .medium : .regular))
                .foregroundColor(isCurrent ? colors.accent : colors.textPrimary.opacity(0.8))
                .lineLimit(1)
            Spacer()
            if track.isAIGenerated {
                Text("AI").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(Capsule().fill(colors.accent.opacity(0.25)))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture { audio.playFromPlaylist(at: index) }
        .background(isCurrent ? colors.accent.opacity(0.06) : Color.clear)
    }
    
    // MARK: - Lyrics
    private var lyricsPanel: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(LanguageManager.shared.t(.lyrics)).font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                if audio.currentTrack?.lyrics != nil {
                    Text(LanguageManager.shared.t(.synced)).font(.system(size: 9, weight: .medium)).foregroundColor(colors.accent.opacity(0.7))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(colors.accent.opacity(0.1)))
                }
                Button(action: { importLyrics() }) {
                    Image(systemName: "doc.badge.plus").font(.system(size: 11, weight: .light)).foregroundColor(colors.accent.opacity(0.7)).frame(width: 24, height: 24)
                }.buttonStyle(.plain)
            }.padding(.horizontal, 14).padding(.top, 10)

            divider

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if let lyrics = audio.currentTrack?.lyrics, !lyrics.isEmpty {
                            ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                                Text(line.text)
                                    .font(.system(size: index == audio.currentLyricIndex ? 15 : 13,
                                                  weight: index == audio.currentLyricIndex ? .semibold : .light))
                                    .foregroundColor(index == audio.currentLyricIndex ? colors.accent : colors.textSecondary.opacity(0.55))
                                    .animation(.easeInOut(duration: 0.3), value: audio.currentLyricIndex)
                                    .id(index)
                            }
                        } else {
                            VStack(spacing: Spacing.md) {
                                Spacer()
                                Image(systemName: "text.quote")
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .foregroundColor(colors.textSecondary.opacity(0.2))

                                VStack(spacing: Spacing.xs) {
                                    Text(lang.t(.noLyrics))
                                        .font(Typography.body)
                                        .foregroundColor(colors.textSecondary.opacity(0.5))
                                    Text(lang.t(.clickToImportLyrics))
                                        .font(Typography.footnote)
                                        .foregroundColor(colors.textSecondary.opacity(0.3))
                                }

                                Button(action: { importLyrics() }) {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "doc.badge.plus")
                                            .font(.system(size: IconSize.small))
                                        Text(lang.t(.importLyrics))
                                            .font(Typography.caption)
                                    }
                                    .foregroundColor(colors.accent)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        Capsule()
                                            .strokeBorder(colors.accent.opacity(0.4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.top, Spacing.sm)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }.padding(.horizontal, 14).padding(.vertical, 6)
                }
                .onChange(of: audio.currentLyricIndex) { _, new in withAnimation { proxy.scrollTo(new, anchor: .center) } }
                .onAppear {
                    if audio.currentLyricIndex >= 0 {
                        proxy.scrollTo(audio.currentLyricIndex, anchor: .center)
                    }
                }
            }
        }.padding(.bottom, 12).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - History Panel
    private var historyPanel: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(lang.t(.playHistory)).font(.system(size: 12, weight: .semibold)).foregroundColor(colors.textPrimary)
                Spacer()
                Text("\(audio.recentlyPlayed.count)").font(.system(size: 10, design: .monospaced)).foregroundColor(colors.textSecondary.opacity(0.5))
                if !audio.recentlyPlayed.isEmpty {
                    Button(action: {
                        audio.clearRecentlyPlayed()
                    }) {
                        Image(systemName: "trash").font(.system(size: 10, weight: .light)).foregroundColor(colors.textSecondary.opacity(0.3)).frame(width: 24, height: 24)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 14).padding(.vertical, 10)

            divider

            if audio.recentlyPlayed.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath").font(.system(size: 28, weight: .ultraLight)).foregroundColor(colors.textSecondary.opacity(0.2))
                    Text(lang.t(.noPlayHistory)).font(.system(size: 11)).foregroundColor(colors.textSecondary.opacity(0.35))
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(audio.recentlyPlayed.enumerated()), id: \.element.id) { index, track in
                            historyRow(track: track, index: index)
                        }
                    }.padding(.vertical, 4)
                }
            }
        }
    }

    private func historyRow(track: Track, index: Int) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isCurrent = track.id == audio.currentTrack?.id

        return HStack(spacing: 10) {
            // Time indicator
            Image(systemName: "clock")
                .font(.system(size: 9))
                .foregroundColor(colors.textSecondary.opacity(0.4))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 11, weight: isCurrent ? .medium : .regular))
                    .foregroundColor(isCurrent ? colors.accent : colors.textPrimary.opacity(0.8))
                    .lineLimit(1)

                Text(track.artist)
                    .font(.system(size: 9))
                    .foregroundColor(colors.textSecondary.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            if track.isAIGenerated {
                Text("AI").font(.system(size: 7, weight: .bold)).foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(Capsule().fill(colors.accent.opacity(0.25)))
            }

            // Favorite indicator
            if audio.isFavorite(track.id) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            audio.load(track: track)
            audio.play()
        }
        .background(isCurrent ? colors.accent.opacity(0.06) : Color.clear)
    }
    
    private var divider: some View {
        Group { if themeManager.current == .glass { Divider().opacity(0.1) } else { Divider() } }
    }
    
    // MARK: - Import
    private func importAudio() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            let urls = panel.urls
            if urls.count == 1, let url = urls.first {
                audio.importAudio(from: url)
                if audio.currentIndex == -1 { audio.currentIndex = audio.playlist.count - 1; audio.play() }
            } else if !urls.isEmpty { audio.importMultipleAudio(from: urls); audio.play() }
        }
    }
    
    private func importLyrics() {
        let panel = NSOpenPanel()
        let lrcType = UTType(filenameExtension: "lrc") ?? .plainText
        let mdType = UTType(filenameExtension: "md") ?? .plainText
        panel.allowedContentTypes = [.plainText, lrcType, mdType]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            let ext = url.pathExtension.lowercased()
            if ext == "lrc" { audio.importLyrics(from: url) } else { importUnsynced(from: url) }
        }
    }
    
    private func importUnsynced(from url: URL) {
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
    
    private func fmtTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Waveform
struct WaveformView: View {
    @State private var animate = false
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<14, id: \.self) { i in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.65, blue: 1.0),
                                Color(red: 0.80, green: 0.50, blue: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3)
                    .frame(height: animate ? CGFloat.random(in: 16...70) : 8)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6)
                        .repeatForever()
                        .delay(Double(i) * 0.05),
                        value: animate
                    )
                    .shadow(color: Color(red: 0.45, green: 0.65, blue: 1.0).opacity(0.5), radius: 4, y: 2)
            }
        }
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

// MARK: - Circular Spectrum (Apple Music Style)
struct CircularSpectrumView: View {
    @State private var animate = false
    let barCount = 32

    var body: some View {
        ZStack {
            ForEach(0..<barCount, id: \.self) { index in
                SpectrumBar(
                    angle: Double(index) * (360.0 / Double(barCount)),
                    height: animate ? CGFloat.random(in: 20...50) : 15,
                    index: index
                )
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

struct SpectrumBar: View {
    let angle: Double
    let height: CGFloat
    let index: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.45, green: 0.65, blue: 1.0).opacity(0.8),
                        Color(red: 0.80, green: 0.50, blue: 1.0).opacity(0.4)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: height)
            .offset(y: -70 + height / 2)
            .rotationEffect(.degrees(angle))
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7)
                .repeatForever()
                .delay(Double(index) * 0.02),
                value: height
            )
            .shadow(
                color: Color(red: 0.45, green: 0.65, blue: 1.0).opacity(0.3),
                radius: 3,
                y: 1
            )
    }
}

// MARK: - Apple-Style Button Animations
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}
