import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct LibraryView: View {
    @EnvironmentObject var audio: AudioService
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateNew
    @State private var showImporter = false
    @State private var trackToDelete: Track? = nil
    @State private var showDeleteAlert = false
    @State private var editingTrack: Track? = nil
    @State private var showEditSheet = false
    
    private var filteredTracks: [Track] {
        var tracks = audio.library
        if !searchText.isEmpty {
            tracks = tracks.filter { $0.title.localizedCaseInsensitiveContains(searchText) || $0.artist.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOption {
        case .dateNew: tracks.sort { $0.dateAdded > $1.dateAdded }
        case .dateOld: tracks.sort { $0.dateAdded < $1.dateAdded }
        case .nameAZ: tracks.sort { $0.title < $1.title }
        case .nameZA: tracks.sort { $0.title > $1.title }
        }
        return tracks
    }
    
    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        VStack(spacing: 0) {
            // Header (enhanced luxury spacing)
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(LanguageManager.shared.t(.libraryTitle))
                        .font(Typography.title1)
                        .foregroundColor(colors.textPrimary)
                    Text("\(audio.library.count)\(lang.t(.tracksCount))")
                        .font(Typography.body)
                        .foregroundColor(colors.textSecondary)
                }
                Spacer()

                if !audio.library.isEmpty {
                    Button(action: { audio.playAllFromLibrary() }) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "play.fill")
                                .font(.system(size: IconSize.medium))
                            Text(LanguageManager.shared.t(.playAll))
                                .font(Typography.caption)
                        }
                        .foregroundColor(colors.accent)
                        .padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.sm)
                        .background(
                            Capsule()
                                .strokeBorder(colors.accent.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button(action: { showImporter = true }) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus")
                        Text(LanguageManager.shared.t(.importAudio)).font(Typography.bodyBold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xl).padding(.vertical, Spacing.md)
                    .background(RoundedRectangle(cornerRadius: CornerRadius.md)
                        .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing)))
                    .shadow(color: colors.accent.opacity(0.3), radius: 12, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, Spacing.xxl).padding(.vertical, Spacing.xl)
            
            // Search & Sort (enhanced)
            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "magnifyingglass").font(.system(size: IconSize.medium)).foregroundColor(colors.textSecondary)
                    TextField(lang.t(.searchPlaceholder), text: $searchText)
                        .textFieldStyle(.plain).font(Typography.body).foregroundColor(colors.textPrimary)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: IconSize.medium))
                                .foregroundColor(colors.textSecondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                .modifier(GlassCardModifier(cornerRadius: CornerRadius.sm))

                Picker("", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(sortLabel(option)).tag(option)
                    }
                }
                .pickerStyle(.menu).frame(width: 140)
            }
            .padding(.horizontal, Spacing.xxl).padding(.bottom, Spacing.lg)
            
            if themeManager.current == .glass { Divider().opacity(0.15) } else { Divider() }

            if filteredTracks.isEmpty {
                VStack(spacing: Spacing.lg) {
                    Spacer()
                    Image(systemName: "music.note.list")
                        .font(.system(size: 56))
                        .foregroundColor(colors.textSecondary.opacity(0.2))

                    VStack(spacing: Spacing.xs) {
                        Text(searchText.isEmpty ? lang.t(.noTracksFound) : lang.t(.noMatchingTracks))
                            .font(Typography.title2)
                            .foregroundColor(colors.textSecondary.opacity(0.7))

                        if searchText.isEmpty {
                            Text(lang.t(.startCreatingOrImport))
                                .font(Typography.body)
                                .foregroundColor(colors.textSecondary.opacity(0.5))
                        }
                    }

                    if searchText.isEmpty {
                        HStack(spacing: Spacing.md) {
                            Button(action: {
                                AppState.shared.switchToGenerator()
                            }) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "sparkles")
                                    Text(lang.t(.createNow))
                                }
                                .font(Typography.bodyBold)
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

                            Button(action: { showImporter = true }) {
                                HStack(spacing: Spacing.sm) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text(lang.t(.importMusic))
                                }
                                .font(Typography.bodyBold)
                                .foregroundColor(colors.accent)
                                .padding(.horizontal, Spacing.xl)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: CornerRadius.md)
                                        .strokeBorder(colors.accent.opacity(0.4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.top, Spacing.sm)
                    }

                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        HStack(spacing: Spacing.md) {
                            Text("").frame(width: 36)
                            Text(lang.t(.trackHeader)).font(Typography.captionBold).foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(lang.t(.durationHeader)).font(Typography.captionBold).foregroundColor(colors.textSecondary).frame(width: 70, alignment: .trailing)
                            Text("").frame(width: 130)
                        }
                        .padding(.horizontal, Spacing.xxl).padding(.vertical, Spacing.sm)
                        
                        ForEach(Array(filteredTracks.enumerated()), id: \.element.id) { index, track in
                            libraryRow(track: track, index: index)
                        }
                        .onMove { from, to in
                            // Only allow reordering when not searching/sorting
                            if searchText.isEmpty && sortOption == .dateNew {
                                audio.library.move(fromOffsets: from, toOffset: to)
                                audio.saveLibrary()
                            }
                        }
                    }.padding(.vertical, 4)
                }
            }
        }
        .background(themeManager.current == .glass ? Color.clear : colors.bg)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text(lang.t(.deleteAlertTitle)),
                message: Text(String(format: lang.t(.deleteAlertMessage), trackToDelete?.title ?? "")),
                primaryButton: .destructive(Text(lang.t(.deleteButton))) {
                    if let track = trackToDelete { audio.removeFromLibrary(track) }
                    trackToDelete = nil
                },
                secondaryButton: .cancel(Text(lang.t(.cancel))) { trackToDelete = nil }
            )
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio, .mp3, .mpeg4Audio, .wav, .aiff], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { audio.importToLibrary(urls: urls) }
        }
        .sheet(isPresented: $showEditSheet) {
            if let track = editingTrack {
                EditLibraryTrackSheet(
                    track: track,
                    colors: colors,
                    onSave: { newTitle, newArtist in
                        audio.updateLibraryTrack(track, title: newTitle, artist: newArtist)
                        showEditSheet = false
                    },
                    onCancel: { showEditSheet = false }
                )
            }
        }
    }
    
    private func libraryRow(track: Track, index: Int) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isPlaying = audio.currentTrack?.id == track.id && audio.isPlaying
        let isCurrent = audio.currentTrack?.id == track.id

        return HStack(spacing: 14) {
            ZStack {
                Text("\(index + 1)").font(.system(size: 12)).foregroundColor(colors.textSecondary.opacity(0.4)).opacity(isCurrent ? 0 : 1)
                if isCurrent {
                    Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.fill")
                        .font(.system(size: 12)).foregroundColor(colors.accent)
                }
            }.frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(track.title)
                        .font(.system(size: 14, weight: isCurrent ? .semibold : .regular))
                        .foregroundColor(isCurrent ? colors.accent : colors.textPrimary).lineLimit(1)
                    if track.isAIGenerated {
                        Text("AI").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Capsule().fill(colors.accent.opacity(0.6)))
                    }
                }
                Text(track.artist).font(.system(size: 12)).foregroundColor(colors.textSecondary).lineLimit(1)
            }
            Spacer()
            Text(formatTime(track.duration))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(colors.textSecondary).frame(width: 70, alignment: .trailing)

            HStack(spacing: 10) {
                Button(action: { audio.playFromLibrary(track) }) {
                    Image(systemName: "play.circle").font(.system(size: 20)).foregroundColor(colors.accent)
                }.buttonStyle(ScaleButtonStyle())
                Button(action: { audio.addToPlaylist(track) }) {
                    Image(systemName: "plus.circle").font(.system(size: 20)).foregroundColor(colors.textSecondary)
                }.buttonStyle(ScaleButtonStyle())
                Button(action: { editingTrack = track; showEditSheet = true }) {
                    Image(systemName: "pencil.circle").font(.system(size: 20)).foregroundColor(colors.textSecondary)
                }.buttonStyle(ScaleButtonStyle())
                Button(action: { trackToDelete = track; showDeleteAlert = true }) {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(colors.textSecondary.opacity(0.4))
                }.buttonStyle(ScaleButtonStyle())
            }.frame(width: 130)
        }
        .padding(.horizontal, 36).padding(.vertical, 10)
        .contentShape(Rectangle())
        .background(isCurrent ? colors.accent.opacity(0.08) : (index % 2 == 0 ? Color.clear : colors.bgCard.opacity(0.3)))
        .onHover { isHovered in
            if !isCurrent && isHovered {
                NSCursor.pointingHand.push()
            } else if !isCurrent {
                NSCursor.pop()
            }
        }
        .onTapGesture { audio.playFromLibrary(track) }
    }
    
    private func sortLabel(_ option: SortOption) -> String {
        switch option {
        case .dateNew: return LanguageManager.shared.t(.sortNewest)
        case .dateOld: return LanguageManager.shared.t(.sortOldest)
        case .nameAZ: return LanguageManager.shared.t(.sortAZ)
        case .nameZA: return LanguageManager.shared.t(.sortZA)
        }
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        guard t > 0 else { return "--:--" }
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Edit Library Track Sheet
struct EditLibraryTrackSheet: View {
    @EnvironmentObject var lang: LanguageManager

    let track: Track
    let colors: ThemeColors
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var editTitle: String
    @State private var editArtist: String
    
    init(track: Track, colors: ThemeColors, onSave: @escaping (String, String) -> Void, onCancel: @escaping () -> Void) {
        self.track = track
        self.colors = colors
        self.onSave = onSave
        self.onCancel = onCancel
        _editTitle = State(initialValue: track.title)
        _editArtist = State(initialValue: track.artist)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(lang.t(.editTrackInfo))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colors.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t(.trackTitle))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                TextField(lang.t(.enterSongTitle), text: $editTitle)
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .modifier(GlassCardModifier(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t(.artist))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                TextField(lang.t(.enterArtistName), text: $editArtist)
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .modifier(GlassCardModifier(cornerRadius: 8))
            }
            
            HStack(spacing: 16) {
                Button(lang.t(.cancel)) { onCancel() }
                    .font(.system(size: 14))
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(colors.buttonBg))

                Button(lang.t(.save)) { onSave(editTitle, editArtist) }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing)))
            }
        }
        .padding(24)
        .frame(width: 360)
        .background(colors.bg)
    }
}
