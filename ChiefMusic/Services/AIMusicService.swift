import Foundation
import Combine

class AIMusicService: ObservableObject {
    @Published var isGenerating = false
    @Published var currentTask: MusicTask?
    @Published var generatedTracks: [Track] = []
    @Published var progress: Double = 0
    @Published var errorMessage: String?
    @Published var canRetry: Bool = false

    private var progressTimer: Timer?
    private var currentDataTask: URLSessionDataTask?
    private var lastFailedPrompt: String?
    private var lastFailedStyle: String?
    private var lastFailedDuration: Int?

    private let baseURL = "https://api.acemusic.ai"
    private let deepseekURL = "https://api.deepseek.com"
    private var apiKey: String {
        // Priority: user's custom key > built-in default key
        if let userKey = UserDefaults.standard.string(forKey: "acemusic_api_key"), !userKey.isEmpty {
            return userKey
        }
        // Always use built-in key as fallback (user doesn't need to configure anything)
        return SecurityConfig.defaultAceMusicKey
    }
    private var deepseekKey: String {
        // Priority: user's custom key > built-in default key
        if let userKey = UserDefaults.standard.string(forKey: "deepseek_api_key"), !userKey.isEmpty {
            return userKey
        }
        // Always use built-in key as fallback (user doesn't need to configure anything)
        return SecurityConfig.defaultAPIKey
    }

    weak var audioService: AudioService?

    init() {
        loadHistory()
    }

    // MARK: - Cancel Generation
    func cancelGeneration() {
        currentDataTask?.cancel()
        stopProgressAnimation()
        isGenerating = false
        progress = 0
        currentTask?.status = .failed
        ToastManager.shared.show(icon: "xmark.circle", LanguageManager.shared.t(.toastGenerationCancelled), style: .info)
    }

    // MARK: - Retry Generation
    func retryLastGeneration() {
        guard let prompt = lastFailedPrompt else { return }
        let style = lastFailedStyle ?? ""
        let duration = lastFailedDuration ?? 60

        canRetry = false
        generate(prompt: prompt, style: style, duration: duration)
    }
    
    func generate(prompt: String, style: String = "", duration: Int = 60) {
        isGenerating = true
        errorMessage = nil
        canRetry = false
        progress = 0

        // Save params for retry
        lastFailedPrompt = prompt
        lastFailedStyle = style
        lastFailedDuration = duration

        let task = MusicTask(id: UUID().uuidString, status: .pending, prompt: prompt, progress: 0)
        currentTask = task

        // Step 1: Generate lyrics via DeepSeek
        ToastManager.shared.show(icon: "text.bubble", LanguageManager.shared.t(.toastGeneratingLyrics), style: .info)
        generateLyricsViaAPI(from: prompt, style: style) { [weak self] lyrics in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if lyrics.isEmpty {
                    self.handleGenerationError(LanguageManager.shared.t(.toastLyricsGenerationFailed), detail: "DeepSeek API 无响应或返回空内容")
                    return
                }

                // Step 2: Generate music with lyrics
                ToastManager.shared.show(icon: "music.note", LanguageManager.shared.t(.toastComposingMusic), style: .info)
                self.generateMusicWithLyrics(prompt: prompt, style: style, lyrics: lyrics, duration: duration)
            }
        }
    }

    private func handleGenerationError(_ message: String, detail: String) {
        isGenerating = false
        errorMessage = "\(message)\n\(detail)"
        canRetry = true
        ToastManager.shared.show(icon: "xmark.circle.fill", message, style: .warning)
        print("❌ Generation error: \(message) - \(detail)")
    }
    
    private func generateMusicWithLyrics(prompt: String, style: String, lyrics: String, duration: Int) {

        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 600 // 10 min timeout for generation (music generation takes time)

        // Build content as JSON string (nested JSON)
        let fullPrompt = style.isEmpty ? prompt : "\(style), \(prompt)"
        let contentDict: [String: Any] = [
            "prompt": fullPrompt,
            "lyrics": lyrics,
            "thinking": true,
            "audio_duration": duration,
            "vocal_language": "zh",
            "audio_format": "mp3"
        ]
        let contentString = String(data: try! JSONSerialization.data(withJSONObject: contentDict), encoding: .utf8) ?? "{}"

        let body: [String: Any] = [
            "model": "acemusic/acestep-v1.5-turbo",
            "messages": [
                ["role": "user", "content": contentString]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Start fake progress animation
        startProgressAnimation()

        currentDataTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.stopProgressAnimation()

                // Check if cancelled
                if let error = error as NSError?, error.code == NSURLErrorCancelled {
                    return
                }

                if let error = error {
                    let errorDetail = self.parseNetworkError(error)
                    self.handleGenerationError("网络错误", detail: errorDetail)
                    return
                }

                // Check HTTP status code first
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Status: \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 200 {
                        let statusMsg = self.parseHTTPError(httpResponse.statusCode)
                        self.handleGenerationError("API 错误", detail: statusMsg)

                        // Try to read error message
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            print("❌ Error response: \(errorStr.prefix(500))")
                        }
                        return
                    }
                }

                guard let data = data else {
                    self.handleGenerationError("API 无响应", detail: "未收到任何数据")
                    return
                }

                // Try to parse error response
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMsg = json["error"] as? String ?? (json["error"] as? [String: Any])?["message"] as? String {
                    self.handleGenerationError("API 错误", detail: errorMsg)
                    return
                }

                // Parse OpenAI format response
                print("📦 Parsing API response...")
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let rawStr = String(data: data, encoding: .utf8) ?? "nil"
                    self.handleGenerationError("JSON 解析失败", detail: "响应格式无效")
                    print("❌ Failed to parse JSON. Raw response:")
                    print(rawStr.prefix(1000))
                    return
                }

                print("✅ JSON parsed successfully")
                print("📋 JSON keys: \(json.keys.joined(separator: ", "))")

                guard let choices = json["choices"] as? [[String: Any]] else {
                    self.handleGenerationError("响应格式错误", detail: "缺少 choices 字段")
                    return
                }

                guard let message = choices.first?["message"] as? [String: Any] else {
                    self.handleGenerationError("响应格式错误", detail: "缺少 message 字段")
                    return
                }

                print("✅ Found message field")
                print("📋 Message keys: \(message.keys.joined(separator: ", "))")

                // Extract audio data
                if let audioArr = message["audio"] as? [[String: Any]],
                   let audioUrl = audioArr.first?["audio_url"] as? [String: Any],
                   let urlStr = audioUrl["url"] as? String,
                   urlStr.hasPrefix("data:audio/mpeg;base64,") {

                    let base64 = String(urlStr.dropFirst("data:audio/mpeg;base64,".count))
                    guard let audioData = Data(base64Encoded: base64) else {
                        self.handleGenerationError("音频解码失败", detail: "Base64 数据无效")
                        return
                    }

                    self.saveAudioData(audioData, title: self.currentTask?.prompt ?? "AI Track", lyrics: lyrics)
                } else {
                    self.handleGenerationError("响应中无音频数据", detail: "API 返回了响应但不包含音频")
                }
            }
        }

        currentDataTask?.resume()
    }

    // MARK: - Error Parsing
    private func parseNetworkError(_ error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case NSURLErrorTimedOut:
            return LanguageManager.shared.t(.errorTimeout)
        case NSURLErrorNotConnectedToInternet:
            return LanguageManager.shared.t(.errorNoConnection)
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            return LanguageManager.shared.t(.errorCannotReach)
        case NSURLErrorNetworkConnectionLost:
            return LanguageManager.shared.t(.errorConnectionLost)
        default:
            return error.localizedDescription
        }
    }

    private func parseHTTPError(_ statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return LanguageManager.shared.t(.errorBadRequest)
        case 401:
            return LanguageManager.shared.t(.errorUnauthorized)
        case 403:
            return LanguageManager.shared.t(.errorForbidden)
        case 429:
            return LanguageManager.shared.t(.errorTooManyRequests)
        case 500...599:
            return String(format: LanguageManager.shared.t(.errorServer), statusCode)
        default:
            return "HTTP \(statusCode)"
        }
    }
    
    private func saveAudioData(_ data: Data, title: String, lyrics: String) {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let fileName = "AI_\(timestamp).mp3"
        let lrcFileName = "AI_\(timestamp).lrc"
        let dest = docs.appendingPathComponent("ChiefMusic/\(fileName)")
        let lrcDest = docs.appendingPathComponent("ChiefMusic/\(lrcFileName)")

        // Move file I/O to background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Create directory
            try? FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)

            // Save audio
            do {
                try data.write(to: dest)
            } catch {
                DispatchQueue.main.async {
                    self.isGenerating = false
                    self.errorMessage = "Save failed: \(error.localizedDescription)"
                    ToastManager.shared.show(icon: "xmark.circle.fill", LanguageManager.shared.t(.toastSaveFailed), style: .warning)
                }
                return
            }

            // Save lyrics as .lrc file
            do {
                try lyrics.write(to: lrcDest, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to save lyrics: \(error)")
            }

            // Back to main thread for UI updates
            DispatchQueue.main.async {
                // Save with a temporary title first
                let tempTitle = title.isEmpty ? LanguageManager.shared.t(.aiGenerated) : title
                var track = Track(title: tempTitle, artist: "", fileURL: dest, isAIGenerated: true)
                track.style = self.currentTask?.prompt
                track.dateAdded = Date()
                track.lyricsFileURL = lrcDest
                self.generatedTracks.insert(track, at: 0)

                self.audioService?.addToPlaylist(track)
                self.audioService?.addToLibrary(track)

                // 🎯 关键优化：生成完成后自动播放并切换到播放器
                self.audioService?.load(track: track)
                self.audioService?.play()

                self.isGenerating = false
                self.progress = 1.0
                self.currentTask?.status = .completed

                // 自动切换到播放器标签
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AppState.shared.switchToPlayer()
                }

                // 显示成功提示（更情感化）
                ToastManager.shared.show(icon: "sparkles", LanguageManager.shared.t(.generationCompleteAndPlaying), style: .success)

                // Try to generate a better song title via DeepSeek (optional, non-blocking)
                let trackId = track.id
                let prompt = title
                self.generateSongTitleViaAPI(from: prompt) { [weak self] songTitle in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        // Only update if we got a better title
                        if !songTitle.isEmpty && songTitle != tempTitle {
                            if let idx = self.generatedTracks.firstIndex(where: { $0.id == trackId }) {
                                self.generatedTracks[idx].title = songTitle
                                self.saveHistory()
                                self.audioService?.updateTrackMetadata(trackId, title: songTitle, artist: "AI 酋长 Andy")
                            }
                        }
                    }
                }

                // 延迟显示第二条 Toast，避免覆盖第一条
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    ToastManager.shared.show(icon: "music.note", LanguageManager.shared.t(.addedToLibraryAndPlaylist), style: .success)
                }
            }
        }
    }
    
    // MARK: - Title Generation via DeepSeek API
    private func generateSongTitleViaAPI(from prompt: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "\(deepseekURL)/v1/chat/completions") else {
            completion(fallbackTitle(from: prompt))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(deepseekKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let systemMsg = "You are a creative song naming assistant. Given a music description/prompt, generate a short, catchy song title in the SAME language as the input. Rules: 1) Max 20 characters. 2) Only return the title, nothing else. 3) Make it poetic and memorable. 4) No quotes or punctuation."
        
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemMsg],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 30,
            "temperature": 0.8
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                let title = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "「", with: "")
                    .replacingOccurrences(of: "」", with: "")
                completion(title.isEmpty ? self?.fallbackTitle(from: prompt) ?? "Untitled" : title)
            } else {
                completion(self?.fallbackTitle(from: prompt) ?? "Untitled")
            }
        }.resume()
    }
    
    // MARK: - Lyrics Generation via DeepSeek API
    private func generateLyricsViaAPI(from prompt: String, style: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: "\(deepseekURL)/v1/chat/completions") else {
            completion("")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(deepseekKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let fullPrompt = style.isEmpty ? prompt : "\(style), \(prompt)"
        let systemMsg = """
You are a professional songwriter. Generate song lyrics in LRC format with timestamps.

Rules:
1. Output in LRC format with timestamps: [mm:ss.xx]lyric line
2. Use the SAME language as the input (Chinese → Chinese lyrics, English → English lyrics)
3. Structure: 2-3 verses + 1 chorus, repeat chorus at the end
4. Each line should be singable (8-15 syllables)
5. Keep it poetic, emotional, and memorable
6. Total length: 150-250 words
7. Timestamps should be evenly distributed (assume 60 second song, ~3-4 seconds per line)

Example format:
[00:00.00]
[00:03.50]Line 1 of verse 1
[00:07.00]Line 2 of verse 1
[00:10.50]Line 3 of verse 1
[00:14.00]
[00:17.50]Chorus line 1
[00:21.00]Chorus line 2
[00:24.50]
[00:28.00]Line 1 of verse 2
...
"""

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": systemMsg],
                ["role": "user", "content": "Generate LRC format lyrics for: \(fullPrompt)"]
            ],
            "max_tokens": 800,
            "temperature": 0.9
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Log error if any
            if let error = error {
                print("❌ Lyrics API Error: \(error.localizedDescription)")
                completion("")
                return
            }

            // Log response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Lyrics API Status: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("❌ No data received from lyrics API")
                completion("")
                return
            }

            // Try to parse response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ Lyrics API Response: \(json.keys.joined(separator: ", "))")

                // Check for error in response
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("❌ API Error: \(message)")
                    completion("")
                    return
                }

                if let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    let lyrics = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ Generated lyrics (\(lyrics.count) chars)")
                    completion(lyrics.isEmpty ? "La la la\nLa la la\nLa la la" : lyrics)
                } else {
                    print("❌ Failed to parse lyrics from response")
                    completion("")
                }
            } else {
                print("❌ Invalid JSON response")
                if let rawStr = String(data: data, encoding: .utf8) {
                    print("Raw response: \(rawStr.prefix(500))")
                }
                completion("")
            }
        }.resume()
    }
    
    private func fallbackTitle(from prompt: String) -> String {
        let cleaned = prompt.prefix(30).trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Untitled" : String(cleaned.prefix(1).uppercased() + cleaned.dropFirst())
    }
    
    // MARK: - Track Editing
    func updateTrack(_ track: Track, title: String, artist: String) {
        if let index = generatedTracks.firstIndex(where: { $0.id == track.id }) {
            generatedTracks[index].title = title
            generatedTracks[index].artist = artist
            saveHistory()
            
            // Update in audio service too
            audioService?.updateTrackMetadata(track.id, title: title, artist: artist)
            
            ToastManager.shared.show(icon: "checkmark.circle.fill", "已更新", style: .success)
        }
    }
    
    // MARK: - Fake Progress Animation
    private func startProgressAnimation() {
        progress = 0
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Slow progress: 0-95% gradually, slower as it approaches 95%
            if self.progress < 0.95 {
                // Slower increment as progress increases
                let increment = self.progress < 0.8 ? 0.01 : 0.002
                self.progress += increment
            }
        }
    }
    
    private func stopProgressAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - History Persistence
    private func saveHistory() {
        let tracks = generatedTracks  // 捕获当前值
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(tracks) {
                UserDefaults.standard.set(data, forKey: "ai_generated_tracks")
            }
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "ai_generated_tracks"),
              let saved = try? JSONDecoder().decode([Track].self, from: data) else { return }
        generatedTracks = saved
    }
    
    func clearHistory() {
        generatedTracks.removeAll()
        saveHistory()
        ToastManager.shared.show(icon: "trash", "历史已清空", style: .info)
    }
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "acemusic_api_key")
        ToastManager.shared.show(icon: "key.fill", "API Key 已保存", style: .success)
    }
}
