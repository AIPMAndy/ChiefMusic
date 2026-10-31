import SwiftUI

struct GeneratorView: View {
    @EnvironmentObject var aiService: AIMusicService
    @EnvironmentObject var audio: AudioService
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var prompt = ""
    @State private var style = ""
    @State private var duration: Double = 60
    @State private var selectedPreset: StylePreset?
    @State private var selectedCategory: StylePreset.PresetCategory = .relaxation

    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)

        ScrollView {
            VStack(spacing: Spacing.xxl) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(lang.t(.createMusic))
                            .font(Typography.title1)
                            .foregroundColor(colors.textPrimary)
                        Text(lang.t(.generatorSubtitle))
                            .font(Typography.body)
                            .foregroundColor(colors.textSecondary)

                        // Generation stats
                        if !aiService.generatedTracks.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 11))
                                    .foregroundColor(colors.accent.opacity(0.8))
                                Text(String(format: lang.t(.generationStats), aiService.generatedTracks.count))
                                    .font(.system(size: 12))
                                    .foregroundColor(colors.accent.opacity(0.8))
                            }
                            .padding(.top, 4)
                        }
                    }
                    Spacer()
                }

                // Category Tabs (refined)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach([StylePreset.PresetCategory.relaxation, .focus, .social, .luxury, .cultural], id: \.self) { category in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(categoryName(category))
                                    .font(Typography.captionBold)
                                    .foregroundColor(selectedCategory == category ? .white : colors.textPrimary)
                                    .padding(.horizontal, Spacing.lg)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: CornerRadius.md)
                                            .fill(selectedCategory == category
                                                ? LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [colors.buttonBg, colors.buttonBg], startPoint: .leading, endPoint: .trailing))
                                            .shadow(color: selectedCategory == category ? colors.accent.opacity(0.3) : .clear, radius: 10, y: 5)
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }

                // Style Presets (filtered by category, refined cards)
                let filteredPresets = StylePreset.all.filter { $0.category == selectedCategory }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: Spacing.md)], spacing: Spacing.md) {
                    ForEach(filteredPresets) { preset in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedPreset?.id == preset.id {
                                    selectedPreset = nil
                                    style = ""
                                } else {
                                    selectedPreset = preset
                                    style = preset.prompt
                                }
                            }
                        } label: {
                            VStack(spacing: Spacing.sm) {
                                Image(systemName: preset.icon)
                                    .font(.system(size: IconSize.xlarge))
                                    .foregroundColor(selectedPreset?.id == preset.id ? .white : colors.accent)

                                Text(presetName(preset))
                                    .font(Typography.caption)
                                    .foregroundColor(selectedPreset?.id == preset.id ? .white : colors.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: CornerRadius.lg)
                                    .fill(selectedPreset?.id == preset.id
                                        ? LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [colors.buttonBg, colors.buttonBg], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.lg)
                                            .stroke(selectedPreset?.id == preset.id ? Color.clear : colors.cardBorder, lineWidth: 0.5)
                                    )
                                    .shadow(color: selectedPreset?.id == preset.id ? colors.accent.opacity(0.3) : .clear, radius: 10, y: 5)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                
                // Input (refined design)
                VStack(spacing: Spacing.lg) {
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        TextField(
                            lang.t(.promptPlaceholder),
                            text: $prompt,
                            axis: .vertical
                        )
                        .font(Typography.body)
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(3...6)
                        .padding(Spacing.md)
                        .modifier(GlassCardModifier(cornerRadius: CornerRadius.md))

                        Text("\(prompt.count)/500")
                            .font(Typography.footnote)
                            .foregroundColor(prompt.count > 500 ? .red : colors.textSecondary.opacity(0.5))
                            .padding(.trailing, Spacing.sm)
                    }

                    HStack(spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(lang.t(.styleLabel))
                                .font(Typography.footnote)
                                .foregroundColor(colors.textSecondary)
                            TextField(lang.t(.stylePlaceholder), text: $style)
                                .font(Typography.caption)
                                .textFieldStyle(.plain)
                                .foregroundColor(colors.textPrimary)
                                .padding(Spacing.sm)
                                .modifier(GlassCardModifier(cornerRadius: CornerRadius.sm))
                        }
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("\(lang.t(.durationLabel)): \(Int(duration))s")
                                .font(Typography.footnote)
                                .foregroundColor(colors.textSecondary)
                            Slider(value: $duration, in: 15...180, step: 15).tint(colors.accent)
                        }.frame(width: 210)
                    }

                    // Generate Button (refined prominence)
                    Button(action: { aiService.generate(prompt: prompt, style: style, duration: Int(duration)) }) {
                        HStack(spacing: Spacing.sm) {
                            if aiService.isGenerating {
                                ProgressView().scaleEffect(0.85).tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(Typography.body)
                            }
                            Text(aiService.isGenerating ? lang.t(.generating) : lang.t(.generateMusic))
                                .font(Typography.bodyBold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: colors.accent.opacity(0.35), radius: 14, y: 7)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(prompt.isEmpty || aiService.isGenerating)
                    .opacity(prompt.isEmpty ? 0.6 : 1.0)

                    // 禁用状态提示
                    if prompt.isEmpty {
                        Text(lang.t(.promptRequired))
                            .font(Typography.footnote)
                            .foregroundColor(colors.textSecondary.opacity(0.6))
                    }
                }
                .padding(Spacing.xl)
                .modifier(GlassCardModifier(cornerRadius: CornerRadius.xl))
                
                // Progress (refined ritual feeling)
                if aiService.isGenerating {
                    VStack(spacing: 22) {
                        // Animated icon with glow
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 3.5
                                )
                                .frame(width: 90, height: 90)
                                .rotationEffect(.degrees(aiService.progress * 360))
                                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: aiService.progress)
                                .shadow(color: colors.accent.opacity(0.35), radius: 16, y: 8)

                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(colors.accent)
                        }

                        VStack(spacing: Spacing.sm) {
                            Text(lang.t(.generatingTitle))
                                .font(Typography.title3)
                                .foregroundColor(colors.textPrimary)

                            Text(getGenerationStage(progress: aiService.progress))
                                .font(Typography.caption)
                                .foregroundColor(colors.textSecondary)
                                .animation(.easeInOut, value: aiService.progress)

                            // Expected duration hint
                            Text(lang.t(.expectedDuration))
                                .font(.system(size: 11))
                                .foregroundColor(colors.accent.opacity(0.8))
                                .padding(.top, 4)

                            Text(lang.t(.expectedDurationHint))
                                .font(.system(size: 10))
                                .foregroundColor(colors.textSecondary.opacity(0.6))
                        }

                        // Progress bar
                        VStack(spacing: 9) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(colors.buttonBg)
                                        .frame(height: 9)

                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(
                                            LinearGradient(
                                                colors: [colors.accent, colors.accentSecondary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * aiService.progress, height: 9)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: aiService.progress)
                                        .shadow(color: colors.accent.opacity(0.45), radius: 5, y: 2)
                                }
                            }
                            .frame(height: 9)

                            HStack {
                                Text("\(Int(aiService.progress * 100))%")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .foregroundColor(colors.accent)
                                Spacer()
                                Text("\(lang.t(.estimatedTime)) \(Int((1 - aiService.progress) * 60))\(lang.t(.seconds))")
                                    .font(.system(size: 11))
                                    .foregroundColor(colors.textSecondary.opacity(0.7))
                            }
                        }

                        // Cancel button
                        Button(action: { aiService.cancelGeneration() }) {
                            HStack(spacing: 7) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(lang.t(.cancelGeneration))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(colors.buttonBg))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(26)
                    .modifier(GlassCardModifier(cornerRadius: 22))
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Error
                if let error = aiService.errorMessage {
                    VStack(spacing: 12) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(lang.t(.generationFailed))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(colors.textPrimary)

                                Text(error)
                                    .font(.system(size: 12))
                                    .foregroundColor(colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            if aiService.canRetry {
                                Button(action: { aiService.retryLastGeneration() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 11))
                                        Text(lang.t(.retry))
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
                            }

                            Button(action: { aiService.errorMessage = nil }) {
                                Text(lang.t(.dismiss))
                                    .font(.system(size: 12))
                                    .foregroundColor(colors.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(colors.buttonBg))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .modifier(GlassCardModifier(cornerRadius: 12))
                }
                
                // Generated History
                if !aiService.generatedTracks.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(lang.t(.generatedHistory))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colors.textPrimary)
                            Text("\(aiService.generatedTracks.count)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(colors.textSecondary.opacity(0.5))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(colors.buttonBg))
                            Spacer()
                            Button(action: { aiService.clearHistory() }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundColor(colors.textSecondary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(aiService.generatedTracks) { track in
                                GeneratedTrackRow(track: track) {
                                    audio.load(track: track); audio.play()
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(40)
        }
    }

    // MARK: - Helper Functions

    // Category name localization
    private func categoryName(_ category: StylePreset.PresetCategory) -> String {
        switch category {
        case .relaxation: return lang.t(.categoryRelaxation)
        case .focus: return lang.t(.categoryFocus)
        case .social: return lang.t(.categorySocial)
        case .luxury: return lang.t(.categoryLuxury)
        case .cultural: return lang.t(.categoryCultural)
        }
    }

    // Preset name localization
    private func presetName(_ preset: StylePreset) -> String {
        switch preset.name {
        case "深夜爵士": return lang.t(.styleDeepNightJazz)
        case "冥想禅音": return lang.t(.styleMeditationZen)
        case "温泉疗愈": return lang.t(.styleSpaHealing)
        case "雨夜咖啡": return lang.t(.styleRainyNightCafe)
        case "深度工作": return lang.t(.styleDeepWork)
        case "创意灵感": return lang.t(.styleCreativeInspiration)
        case "阅读时光": return lang.t(.styleReadingTime)
        case "编码节奏": return lang.t(.styleCodingRhythm)
        case "派对电音": return lang.t(.stylePartyElectronic)
        case "鸡尾酒会": return lang.t(.styleCocktailParty)
        case "下午茶": return lang.t(.styleAfternoonTea)
        case "游艇派对": return lang.t(.styleYachtParty)
        case "皇家古典": return lang.t(.styleRoyalClassical)
        case "歌剧之夜": return lang.t(.styleOperaNight)
        case "钢琴独奏": return lang.t(.stylePianoSolo)
        case "爵士大乐队": return lang.t(.styleBigBandJazz)
        case "中国古风": return lang.t(.styleChineseTraditional)
        case "日式和风": return lang.t(.styleJapaneseWafuu)
        case "印度灵性": return lang.t(.styleIndianSpiritual)
        case "拉丁热情": return lang.t(.styleLatinPassion)
        case "电影配乐": return lang.t(.styleCinematic)
        case "合成波": return lang.t(.styleSynthwave)
        default: return preset.name
        }
    }

    // Helper function for generation stages
    private func getGenerationStage(progress: Double) -> String {
        if progress < 0.2 {
            return lang.t(.stageUnderstanding)
        } else if progress < 0.4 {
            return lang.t(.stageMelody)
        } else if progress < 0.6 {
            return lang.t(.stageHarmony)
        } else if progress < 0.8 {
            return lang.t(.stageRhythm)
        } else {
            return lang.t(.stageMixing)
        }
    }
}

struct GeneratedTrackRow: View {
    let track: Track
    let onPlay: () -> Void
    @EnvironmentObject var aiService: AIMusicService
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false
    @State private var editTitle = ""
    @State private var editArtist = ""
    
    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Album art placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [colors.accent.opacity(0.3), colors.accent.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(colors.accent.opacity(0.6))
                }
                .frame(width: 44, height: 44)
                
                // Track info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(1)
                        
                        if track.title == lang.t(.generatingStatus) {
                            ProgressView().scaleEffect(0.5)
                        }
                    }
                    
                    Text(track.artist)
                        .font(.system(size: 10))
                        .foregroundColor(colors.textSecondary.opacity(0.6))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        // Style tag
                        if let style = track.style, !style.isEmpty {
                            Text(style)
                                .font(.system(size: 9))
                                .foregroundColor(colors.accent.opacity(0.7))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 160)
                        }
                        
                        Spacer()
                        
                        // Date
                        Text(formatDate(track.dateAdded))
                            .font(.system(size: 9))
                            .foregroundColor(colors.textSecondary.opacity(0.4))
                    }
                    
                    // Duration + format
                    HStack(spacing: 6) {
                        if track.duration > 0 {
                            Text(formatDuration(track.duration))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(colors.textSecondary.opacity(0.4))
                        }
                        Text("AI")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(Capsule().fill(colors.accent.opacity(0.25)))
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: {
                    editTitle = track.title
                    editArtist = track.artist
                    isEditing = true
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 18))
                        .foregroundColor(colors.textSecondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(colors.accent)
            }
            .padding(10)
            .modifier(GlassCardModifier(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isEditing) {
            EditTrackSheet(
                title: $editTitle,
                artist: $editArtist,
                colors: colors,
                onSave: {
                    aiService.updateTrack(track, title: editTitle, artist: editArtist)
                    isEditing = false
                },
                onCancel: { isEditing = false }
            )
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "\(lang.t(.today)) \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "\(lang.t(.yesterday)) \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: date)
        }
    }
    
    private func formatDuration(_ d: TimeInterval) -> String {
        String(format: "%d:%02d", Int(d) / 60, Int(d) % 60)
    }
}

// MARK: - Edit Track Sheet
struct EditTrackSheet: View {
    @EnvironmentObject var lang: LanguageManager

    @Binding var title: String
    @Binding var artist: String
    let colors: ThemeColors
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(lang.t(.editTrackInfo))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colors.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t(.trackTitle))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                TextField(lang.t(.enterSongTitle), text: $title)
                    .font(.system(size: 14))
                    .textFieldStyle(.plain)
                    .padding(10)
                    .modifier(GlassCardModifier(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(lang.t(.artist))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(colors.textSecondary)
                TextField(lang.t(.enterArtistName), text: $artist)
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
                
                Button(lang.t(.save)) { onSave() }
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
