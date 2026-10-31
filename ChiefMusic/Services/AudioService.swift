import Foundation
import AVFoundation
import Combine
import AppKit

// MARK: - Playback Mode
enum PlaybackMode: String, CaseIterable {
    case sequential
    case singleLoop
    case shuffle
    case listLoop

    var icon: String {
        switch self {
        case .sequential: return "list.number"
        case .singleLoop: return "repeat.1"
        case .shuffle: return "shuffle"
        case .listLoop: return "repeat"
        }
    }

    func displayName() -> String {
        switch self {
        case .sequential: return LanguageManager.shared.t(.modeSequential)
        case .singleLoop: return LanguageManager.shared.t(.modeSingleLoop)
        case .shuffle: return LanguageManager.shared.t(.modeShuffle)
        case .listLoop: return LanguageManager.shared.t(.modeListLoop)
        }
    }
}

// MARK: - EQ Preset
enum EQPreset: String, CaseIterable {
    case flat
    case bass
    case vocal
    case classical
    case electronic

    var icon: String {
        switch self {
        case .flat: return "speaker.wave.2"
        case .bass: return "speaker.wave.3"
        case .vocal: return "mic"
        case .classical: return "music.quarternote.3"
        case .electronic: return "waveform.badge.plus"
        }
    }

    func displayName() -> String {
        switch self {
        case .flat: return LanguageManager.shared.t(.eqFlat)
        case .bass: return LanguageManager.shared.t(.eqBass)
        case .vocal: return LanguageManager.shared.t(.eqVocal)
        case .classical: return LanguageManager.shared.t(.eqClassical)
        case .electronic: return LanguageManager.shared.t(.eqElectronic)
        }
    }
    
    // Simple EQ via AVAudioEngine (frequency gains)
    var gains: (bass: Float, mid: Float, treble: Float) {
        switch self {
        case .flat: return (1.0, 1.0, 1.0)
        case .bass: return (1.8, 0.9, 0.8)
        case .vocal: return (0.7, 1.5, 1.0)
        case .classical: return (1.0, 1.1, 1.3)
        case .electronic: return (1.6, 0.8, 1.4)
        }
    }
}

class AudioService: ObservableObject {
    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Double = 0.7
    @Published var playbackRate: Float = 1.0  // 新增：播放速度
    @Published var currentLyricIndex: Int = -1

    // Playlist
    @Published var playlist: [Track] = []
    @Published var currentIndex: Int = -1
    @Published var playbackMode: PlaybackMode = .sequential

    // Library
    @Published var library: [Track] = []

    // Favorites
    @Published var favorites: Set<UUID> = []  // 新增：收藏列表

    // Recent History
    @Published var recentlyPlayed: [Track] = []  // 新增：播放历史
    private let maxRecentTracks = 50

    // EQ
    @Published var eqPreset: EQPreset = .flat

    // Album Art
    @Published var currentAlbumArt: NSImage?

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var didFireTrackEnd = false
    private var volumeSaveTimer: Timer?

    init() {
        loadLibrary()
        loadPlaylist()
        loadFavorites()
        loadRecentlyPlayed()
        let savedVolume = UserDefaults.standard.double(forKey: "audio_volume")
        if savedVolume > 0 { volume = savedVolume }
        let savedRate = UserDefaults.standard.float(forKey: "audio_playback_rate")
        if savedRate > 0 { playbackRate = savedRate }

        // Load playback mode
        if let modeRaw = UserDefaults.standard.string(forKey: "audio_playback_mode"),
           let mode = PlaybackMode(rawValue: modeRaw) {
            playbackMode = mode
        }

        // Load EQ preset
        if let eqRaw = UserDefaults.standard.string(forKey: "audio_eq_preset"),
           let eq = EQPreset(rawValue: eqRaw) {
            eqPreset = eq
        }

        // Restore last playback state
        restorePlaybackState()
    }
    
    // MARK: - Playback
    func load(track: Track) {
        // 淡出当前播放
        if isPlaying {
            fadeOut {
                self.loadTrackInternal(track)
            }
        } else {
            loadTrackInternal(track)
        }
    }

    private func loadTrackInternal(_ track: Track) {
        currentTrack = track
        currentAlbumArt = nil

        // Stop old player before creating new one to prevent audio overlap
        player?.stop()
        player = nil

        guard let url = track.fileURL else { return }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 0 // 从 0 开始，准备淡入
            player?.enableRate = true
            player?.rate = playbackRate
            applyEQ()
            
            // Extract audio quality info
            if let url = track.fileURL {
                var updatedTrack = track
                
                // File size
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    updatedTrack.fileSize = size
                }
                
                // Format from extension
                let ext = url.pathExtension.uppercased()
                updatedTrack.audioFormat = ext
                
                // Sample rate and bit rate from AVAudioPlayer
                if let p = player {
                    updatedTrack.sampleRate = p.format.sampleRate
                    updatedTrack.bitRate = Int(p.format.sampleRate * Double(p.format.channelCount) * 16)
                }
                
                currentTrack = updatedTrack
            }
            
            duration = player?.duration ?? 0
            currentTime = 0
            currentLyricIndex = -1
            didFireTrackEnd = false

            // Auto-load lyrics from .lrc file if exists
            if let lrcURL = track.lyricsFileURL {
                if FileManager.default.fileExists(atPath: lrcURL.path) {
                    loadLyricsFromFile(lrcURL)
                }
            } else {
                // Try to find .lrc file with same name as audio file
                if let audioURL = track.fileURL {
                    let lrcURL = audioURL.deletingPathExtension().appendingPathExtension("lrc")
                    if FileManager.default.fileExists(atPath: lrcURL.path) {
                        loadLyricsFromFile(lrcURL)
                    }
                }
            }
            
            // Extract album art
            extractAlbumArt(from: url)
            
            // Generate fallback cover art if no embedded art
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.currentAlbumArt == nil else { return }
                self.currentAlbumArt = CoverArtGenerator.generate(for: self.currentTrack ?? track)
            }
        } catch {
            ToastManager.shared.show(icon: "xmark.circle.fill", LanguageManager.shared.t(.loadFailed), style: .warning)
        }
    }
    
    func play() {
        player?.play()
        player?.rate = playbackRate  // 应用播放速度
        isPlaying = true
        startTimer()

        // 淡入效果
        fadeIn()

        // 添加到播放历史
        if let track = currentTrack {
            addToRecentlyPlayed(track)
        }
    }

    func pause() {
        fadeOut {
            self.player?.pause()
            self.isPlaying = false
            self.stopTimer()
            self.savePlaybackState()
        }
    }

    func togglePlay() {
        guard player != nil else { return }
        isPlaying ? pause() : play()
    }

    // MARK: - Fade In/Out
    private func fadeIn() {
        player?.volume = 0
        let targetVolume = Float(volume)
        let steps = 20
        let stepDuration = 0.05 // 总共 1 秒

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) { [weak self] in
                self?.player?.volume = targetVolume * Float(i) / Float(steps)
            }
        }
    }

    private func fadeOut(completion: @escaping () -> Void) {
        let currentVolume = player?.volume ?? Float(volume)
        let steps = 15
        let stepDuration = 0.04 // 总共 0.6 秒

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * stepDuration) { [weak self] in
                self?.player?.volume = currentVolume * Float(steps - i) / Float(steps)

                if i == steps {
                    completion()
                }
            }
        }
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateLyricIndex()
    }

    func setVolume(_ vol: Double) {
        volume = vol
        player?.volume = Float(vol)

        // Debounce: save after 1 second of no changes
        volumeSaveTimer?.invalidate()
        volumeSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            UserDefaults.standard.set(vol, forKey: "audio_volume")
        }
    }

    // MARK: - Playback Rate
    func setPlaybackRate(_ rate: Float) {
        playbackRate = max(0.5, min(2.0, rate))
        player?.rate = playbackRate
        player?.enableRate = true
        UserDefaults.standard.set(playbackRate, forKey: "audio_playback_rate")
    }

    func increasePlaybackRate() {
        setPlaybackRate(playbackRate + 0.25)
    }

    func decreasePlaybackRate() {
        setPlaybackRate(playbackRate - 0.25)
    }

    func resetPlaybackRate() {
        setPlaybackRate(1.0)
    }

    // MARK: - Volume Control
    func increaseVolume() {
        setVolume(min(1.0, volume + 0.1))
    }

    func decreaseVolume() {
        setVolume(max(0.0, volume - 0.1))
    }

    // MARK: - Favorites
    func toggleFavorite(_ trackId: UUID) {
        if favorites.contains(trackId) {
            favorites.remove(trackId)
            ToastManager.shared.show(icon: "heart", LanguageManager.shared.t(.toastRemovedFromFavorites), style: .info)
        } else {
            favorites.insert(trackId)
            ToastManager.shared.show(icon: "heart.fill", LanguageManager.shared.t(.toastAddedToFavorites), style: .success)
        }
        saveFavorites()
    }

    func isFavorite(_ trackId: UUID) -> Bool {
        return favorites.contains(trackId)
    }

    private func saveFavorites() {
        let ids = favorites.map { $0.uuidString }
        DispatchQueue.global(qos: .utility).async {
            UserDefaults.standard.set(ids, forKey: "audio_favorites")
        }
    }

    private func loadFavorites() {
        if let ids = UserDefaults.standard.array(forKey: "audio_favorites") as? [String] {
            favorites = Set(ids.compactMap { UUID(uuidString: $0) })
        }
    }

    // MARK: - Recently Played
    private func addToRecentlyPlayed(_ track: Track) {
        // 移除已存在的相同歌曲
        recentlyPlayed.removeAll { $0.id == track.id }

        // 添加到开头
        recentlyPlayed.insert(track, at: 0)

        // 限制数量
        if recentlyPlayed.count > maxRecentTracks {
            recentlyPlayed = Array(recentlyPlayed.prefix(maxRecentTracks))
        }

        saveRecentlyPlayed()
    }

    private func saveRecentlyPlayed() {
        let tracks = recentlyPlayed
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(tracks) {
                UserDefaults.standard.set(data, forKey: "audio_recently_played")
            }
        }
    }

    func clearRecentlyPlayed() {
        recentlyPlayed.removeAll()
        saveRecentlyPlayed()
    }

    private func loadRecentlyPlayed() {
        if let data = UserDefaults.standard.data(forKey: "audio_recently_played"),
           let tracks = try? JSONDecoder().decode([Track].self, from: data) {
            recentlyPlayed = tracks
        }
    }

    // MARK: - Playback State Persistence
    private func savePlaybackState() {
        guard let track = currentTrack else {
            UserDefaults.standard.removeObject(forKey: "audio_last_track_id")
            return
        }

        // Only save if playback position is meaningful (> 5 seconds and not near the end)
        if currentTime > 5 && currentTime < duration - 5 {
            UserDefaults.standard.set(track.id.uuidString, forKey: "audio_last_track_id")
            UserDefaults.standard.set(currentTime, forKey: "audio_last_position")
        } else {
            UserDefaults.standard.removeObject(forKey: "audio_last_track_id")
            UserDefaults.standard.removeObject(forKey: "audio_last_position")
        }
    }

    private func restorePlaybackState() {
        guard let trackIdString = UserDefaults.standard.string(forKey: "audio_last_track_id"),
              let trackId = UUID(uuidString: trackIdString) else { return }

        let savedPosition = UserDefaults.standard.double(forKey: "audio_last_position")
        guard savedPosition > 5 else { return }

        // Try to find the track in playlist, library, or recently played
        var trackToRestore: Track?
        if let track = playlist.first(where: { $0.id == trackId }) {
            trackToRestore = track
            currentIndex = playlist.firstIndex(where: { $0.id == trackId }) ?? -1
        } else if let track = library.first(where: { $0.id == trackId }) {
            trackToRestore = track
        } else if let track = recentlyPlayed.first(where: { $0.id == trackId }) {
            trackToRestore = track
        }

        guard let track = trackToRestore else { return }

        // Verify file still exists before attempting to load
        if let fileURL = track.fileURL, !FileManager.default.fileExists(atPath: fileURL.path) {
            // File was deleted, clear saved state
            UserDefaults.standard.removeObject(forKey: "audio_last_track_id")
            UserDefaults.standard.removeObject(forKey: "audio_last_position")
            return
        }

        // Load the track without playing
        loadTrackInternal(track)

        // Restore playback position
        if savedPosition > 0, savedPosition < duration {
            player?.currentTime = savedPosition
            currentTime = savedPosition
        }
    }
    
    // MARK: - EQ
    func cycleEQ() {
        let all = EQPreset.allCases
        if let idx = all.firstIndex(of: eqPreset) {
            eqPreset = all[(idx + 1) % all.count]
            UserDefaults.standard.set(eqPreset.rawValue, forKey: "audio_eq_preset")
            applyEQ()
        }
    }
    
    private func applyEQ() {
        // AVAudioPlayer doesn't have native EQ, but we can use the volume scaling
        // For a real EQ we'd need AVAudioEngine. For now, store the preset.
        // The preset name will be displayed in the UI.
    }
    
    // MARK: - Album Art
    private func extractAlbumArt(from url: URL) {
        let asset = AVURLAsset(url: url)
        
        Task {
            do {
                let metadata = try await asset.load(.metadata)
                for item in metadata {
                    if item.commonKey == .commonKeyArtwork,
                       let data = try await item.load(.dataValue),
                       let image = NSImage(data: data) {
                        await MainActor.run { self.currentAlbumArt = image }
                        return
                    }
                }
                
                let formats = try await asset.load(.availableMetadataFormats)
                for _ in formats {
                    let metadataItems = AVMetadataItem.metadataItems(from: metadata, withKey: AVMetadataKey.commonKeyArtwork, keySpace: AVMetadataKeySpace.common)
                    if let item = metadataItems.first,
                       let data = try await item.load(.dataValue),
                       let image = NSImage(data: data) {
                        await MainActor.run { self.currentAlbumArt = image }
                        return
                    }
                }
            } catch {
                // Silent fail for album art extraction
            }
        }
    }
    
    // MARK: - Lyrics
    private func loadLyricsFromFile(_ url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("❌ Failed to read lyrics file: \(url.path)")
            return
        }
        
        print("📝 Loading lyrics from: \(url.lastPathComponent)")
        print("📝 Lyrics content length: \(content.count) characters")
        
        var lyrics: [LyricLine] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // Parse LRC format: [mm:ss.xx]text or [mm:ss]text
            let pattern = #"\[(\d{2}):(\d{2})(?:\.(\d{2}))?\](.*)"#
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                
                if let minutesRange = Range(match.range(at: 1), in: line),
                   let secondsRange = Range(match.range(at: 2), in: line),
                   let textRange = Range(match.range(at: 4), in: line) {
                    
                    let minutes = Int(line[minutesRange]) ?? 0
                    let seconds = Int(line[secondsRange]) ?? 0
                    let timestamp = Double(minutes * 60 + seconds)
                    let text = String(line[textRange]).trimmingCharacters(in: .whitespaces)
                    
                    if !text.isEmpty {
                        lyrics.append(LyricLine(time: timestamp, text: text))
                    }
                }
            }
        }
        
        // Sort by timestamp
        lyrics.sort { (a: LyricLine, b: LyricLine) in a.time < b.time }
        
        // Update current track lyrics
        DispatchQueue.main.async {
            if var track = self.currentTrack {
                track.lyrics = lyrics
                self.currentTrack = track  // 重新赋值以触发 @Published 更新
                print("✅ Loaded \(lyrics.count) lyric lines")
                if lyrics.isEmpty {
                    print("⚠️ Warning: No valid LRC lines found in file")
                } else {
                    print("📋 Sample lyrics: \(lyrics.prefix(3).map { $0.text }.joined(separator: " / "))")
                }
            }
        }
    }
    
    // MARK: - Library
    func importToLibrary(urls: [URL]) {
        // Process imports in background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var imported = 0
            var newTracks: [Track] = []

            for url in urls {
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }

                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let libraryDir = docs.appendingPathComponent("ChiefMusic/Library")
                try? FileManager.default.createDirectory(at: libraryDir, withIntermediateDirectories: true)

                let dest = libraryDir.appendingPathComponent(url.lastPathComponent)
                if !FileManager.default.fileExists(atPath: dest.path) {
                    try? FileManager.default.copyItem(at: url, to: dest)
                }

                var trackDur: TimeInterval = 0
                if let avPlayer = try? AVAudioPlayer(contentsOf: dest) { trackDur = avPlayer.duration }

                var track = Track(title: url.deletingPathExtension().lastPathComponent, duration: trackDur, fileURL: dest)
                track.dateAdded = Date()

                // Auto-detect lyrics: look for same-name .lrc file
                let lrcURL = url.deletingPathExtension().appendingPathExtension("lrc")
                let lrcDest = dest.deletingPathExtension().appendingPathExtension("lrc")
                let lrcSource = FileManager.default.fileExists(atPath: lrcURL.path) ? lrcURL : (FileManager.default.fileExists(atPath: lrcDest.path) ? lrcDest : nil)
                if let lrcFile = lrcSource,
                   let lrcContent = try? String(contentsOf: lrcFile, encoding: .utf8) {
                    let lines = LRCParser.parse(lrcContent)
                    if !lines.isEmpty { track.lyrics = lines }
                }

                newTracks.append(track)
                imported += 1
            }

            // Update UI on main thread
            DispatchQueue.main.async {
                for track in newTracks {
                    if !self.library.contains(where: { $0.fileURL?.path == track.fileURL?.path }) {
                        self.library.append(track)
                    }
                }
                self.saveLibrary()
                ToastManager.shared.show(icon: "checkmark.circle.fill", "\(LanguageManager.shared.t(.importedToLibrary)) \(imported)", style: .success)
            }
        }
    }
    
    func removeFromLibrary(_ track: Track) {
        library.removeAll { $0.id == track.id }
        saveLibrary()
    }
    
    func addToLibrary(_ track: Track) {
        let path = track.fileURL?.path ?? ""
        if !library.contains(where: { $0.fileURL?.path == path }) {
            var t = track
            t.dateAdded = Date()
            library.insert(t, at: 0)
            saveLibrary()
        }
    }
    
    // MARK: - Track Metadata Update
    func updateTrackMetadata(_ trackId: UUID, title: String?, artist: String?) {
        // Update in playlist
        if let idx = playlist.firstIndex(where: { $0.id == trackId }) {
            if let title = title { playlist[idx].title = title }
            if let artist = artist { playlist[idx].artist = artist }
        }
        // Update in library
        if let idx = library.firstIndex(where: { $0.id == trackId }) {
            if let title = title { library[idx].title = title }
            if let artist = artist { library[idx].artist = artist }
            saveLibrary()
        }
        // Update current track
        if currentTrack?.id == trackId {
            if let title = title { currentTrack?.title = title }
            if let artist = artist { currentTrack?.artist = artist }
        }
    }
    
    func updateLibraryTrack(_ track: Track, title: String, artist: String) {
        if let idx = library.firstIndex(where: { $0.id == track.id }) {
            library[idx].title = title
            library[idx].artist = artist
            saveLibrary()
            
            // Also update in playlist if exists
            if let pIdx = playlist.firstIndex(where: { $0.id == track.id }) {
                playlist[pIdx].title = title
                playlist[pIdx].artist = artist
            }
            
            // Update current track if it's playing
            if currentTrack?.id == track.id {
                currentTrack?.title = title
                currentTrack?.artist = artist
            }
        }
    }
    
    func playFromLibrary(_ track: Track) {
        if !playlist.contains(where: { $0.id == track.id }) {
            playlist.insert(track, at: 0)
            currentIndex = 0
        } else {
            currentIndex = playlist.firstIndex(where: { $0.id == track.id }) ?? 0
        }
        savePlaylist()
        load(track: track)
        play()
    }
    
    func playAllFromLibrary() {
        playlist = library
        savePlaylist()
        if !playlist.isEmpty {
            currentIndex = 0
            load(track: playlist[0])
            play()
        }
    }
    
    func saveLibrary() {
        let tracks = library
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(tracks) {
                UserDefaults.standard.set(data, forKey: "music_library")
            }
        }
    }
    
    private func loadLibrary() {
        guard let data = UserDefaults.standard.data(forKey: "music_library"),
              let saved = try? JSONDecoder().decode([Track].self, from: data) else { return }

        // Filter out tracks whose files no longer exist
        library = saved.filter { track in
            guard let fileURL = track.fileURL else { return false }
            return FileManager.default.fileExists(atPath: fileURL.path)
        }

        // If any tracks were removed, save the cleaned library
        if library.count < saved.count {
            saveLibrary()
        }
    }

    private func savePlaylist() {
        let tracks = playlist
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(tracks) {
                UserDefaults.standard.set(data, forKey: "music_playlist")
            }
        }
    }

    private func loadPlaylist() {
        guard let data = UserDefaults.standard.data(forKey: "music_playlist"),
              let saved = try? JSONDecoder().decode([Track].self, from: data) else { return }

        // Filter out tracks whose files no longer exist
        playlist = saved.filter { track in
            guard let fileURL = track.fileURL else { return false }
            return FileManager.default.fileExists(atPath: fileURL.path)
        }

        // If any tracks were removed, save the cleaned playlist
        if playlist.count < saved.count {
            savePlaylist()
        }
    }
    
    // MARK: - Playlist
    func addToPlaylist(_ track: Track) {
        if !playlist.contains(where: { $0.id == track.id }) {
            playlist.append(track)
        }
        savePlaylist()
    }

    func addToPlaylist(tracks: [Track]) {
        for t in tracks { addToPlaylist(t) }
    }
    
    func removeFromPlaylist(at index: Int) {
        guard index >= 0, index < playlist.count else { return }
        playlist.remove(at: index)
        if currentIndex == index {
            pause(); currentTrack = nil; currentIndex = -1
        } else if currentIndex > index {
            currentIndex -= 1
        }
        savePlaylist()
    }
    
    func playFromPlaylist(at index: Int) {
        guard index >= 0, index < playlist.count else { return }
        currentIndex = index
        load(track: playlist[index])
        play()
    }
    
    func playNext() {
        guard !playlist.isEmpty else { return }
        switch playbackMode {
        case .sequential:
            let next = currentIndex + 1
            if next < playlist.count { playFromPlaylist(at: next) } else { pause() }
        case .listLoop:
            playFromPlaylist(at: (currentIndex + 1) % playlist.count)
        case .singleLoop:
            playFromPlaylist(at: currentIndex)
        case .shuffle:
            playFromPlaylist(at: Int.random(in: 0..<playlist.count))
        }
    }
    
    func playPrevious() {
        guard !playlist.isEmpty else { return }
        switch playbackMode {
        case .shuffle:
            playFromPlaylist(at: Int.random(in: 0..<playlist.count))
        default:
            playFromPlaylist(at: currentIndex > 0 ? currentIndex - 1 : playlist.count - 1)
        }
    }
    
    func cyclePlaybackMode() {
        let all = PlaybackMode.allCases
        if let idx = all.firstIndex(of: playbackMode) {
            playbackMode = all[(idx + 1) % all.count]
            UserDefaults.standard.set(playbackMode.rawValue, forKey: "audio_playback_mode")
        }
    }
    
    func clearPlaylist() {
        playlist.removeAll()
        currentIndex = -1
        pause()
        currentTrack = nil
        savePlaylist()
    }
    
    // MARK: - Import
    func importAudio(from url: URL) {
        var track = Track(title: url.deletingPathExtension().lastPathComponent, fileURL: url)

        // Auto-detect lyrics: look for same-name .lrc file in the same directory
        let lrcURL = url.deletingPathExtension().appendingPathExtension("lrc")
        if FileManager.default.fileExists(atPath: lrcURL.path),
           let lrcContent = try? String(contentsOf: lrcURL, encoding: .utf8) {
            let lines = LRCParser.parse(lrcContent)
            if !lines.isEmpty {
                track.lyrics = lines
            }
        }

        addToPlaylist(track)
        if currentIndex == -1 {
            currentIndex = playlist.count - 1
            load(track: track)
        }
    }
    
    func importMultipleAudio(from urls: [URL]) {
        var newTracks: [Track] = []
        var lyricsFound = 0
        
        for url in urls {
            var track = Track(title: url.deletingPathExtension().lastPathComponent, fileURL: url)
            
            // Auto-detect lyrics for each file
            let lrcURL = url.deletingPathExtension().appendingPathExtension("lrc")
            if FileManager.default.fileExists(atPath: lrcURL.path),
               let lrcContent = try? String(contentsOf: lrcURL, encoding: .utf8) {
                let lines = LRCParser.parse(lrcContent)
                if !lines.isEmpty {
                    track.lyrics = lines
                    lyricsFound += 1
                }
            }
            
            newTracks.append(track)
        }
        
        addToPlaylist(tracks: newTracks)
        if currentIndex == -1, !playlist.isEmpty {
            currentIndex = 0
            load(track: playlist[0])
        }
        
        if lyricsFound > 0 {
            ToastManager.shared.show(icon: "text.quote", String(format: LanguageManager.shared.t(.toastLyricsAutoLoadedCount), lyricsFound), style: .success)
        }
    }
    
    func importLyrics(lrcContent: String) {
        let lines = LRCParser.parse(lrcContent)
        currentTrack?.lyrics = lines
        ToastManager.shared.show(icon: "text.quote", LanguageManager.shared.t(.synced), style: .success)
    }
    
    func importLyrics(from url: URL) {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }
        importLyrics(lrcContent: content)
    }
    
    // MARK: - Timer
    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.player?.currentTime ?? 0
            self.updateLyricIndex()
            MediaKeyHandler.shared.updateNowPlaying(
                title: self.currentTrack?.title ?? "",
                artist: self.currentTrack?.artist ?? "Unknown",
                duration: self.duration,
                currentTime: self.currentTime,
                isPlaying: self.isPlaying
            )
            if let p = self.player, p.currentTime >= p.duration - 0.1, !self.didFireTrackEnd {
                self.didFireTrackEnd = true
                self.playNext()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateLyricIndex() {
        guard let lyrics = currentTrack?.lyrics, !lyrics.isEmpty else { return }
        let newIndex = lyrics.lastIndex { $0.time <= currentTime } ?? -1
        if newIndex != currentLyricIndex {
            DispatchQueue.main.async { self.currentLyricIndex = newIndex }
        }
    }
    
    deinit {
        timer?.invalidate()
        savePlaybackState()
    }
}
