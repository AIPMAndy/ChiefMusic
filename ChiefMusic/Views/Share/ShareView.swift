import SwiftUI

struct ShareView: View {
    @EnvironmentObject var audio: AudioService
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @State private var selectedStyle: CardStyle = .minimalist
    
    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isGlass = themeManager.current == .glass
        
        VStack(spacing: 24) {
            HStack {
                Text(lang.t(.shareCard))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colors.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colors.textSecondary)
                }.buttonStyle(.plain)
            }
            
            HStack(spacing: 24) {
                cardPreview.frame(width: 300, height: 400)
                
                VStack(spacing: 16) {
                    Text(lang.t(.cardStyle))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(CardStyle.allCases, id: \.self) { style in
                        Button(action: { withAnimation { selectedStyle = style } }) {
                            HStack(spacing: 10) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(style.previewColor).frame(width: 24, height: 24)
                                Text(style.localizedLabel)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(colors.textPrimary)
                                Spacer()
                                if selectedStyle == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(colors.accent).font(.system(size: 14))
                                }
                            }
                            .padding(10).modifier(GlassCardModifier(cornerRadius: 10))
                        }.buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: exportCard) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                Text(lang.t(.export))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing)))
                        }.buttonStyle(.plain)
                        
                        Button(action: shareViaSystemPanel) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [colors.accent, colors.accentSecondary], startPoint: .leading, endPoint: .trailing)))
                        }.buttonStyle(.plain)
                    }
                }.frame(width: 180)
            }
        }
        .padding(24)
        .frame(width: 540, height: 500)
        .background(
            Group {
                if isGlass {
                    ZStack {
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                        Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                    }
                } else { colors.bg }
            }
        )
        .preferredColorScheme(isGlass ? .dark : .light)
    }
    
    @ViewBuilder
    private var cardPreview: some View {
        let track = audio.currentTrack
        
        ZStack {
            selectedStyle.background
            VStack(spacing: 0) {
                Spacer()
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .overlay(Image(systemName: "music.note").font(.system(size: 40)).foregroundColor(.white.opacity(0.6)))
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                Spacer()
                VStack(spacing: 8) {
                    Text(track?.title ?? lang.t(.noTrack))
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Text(track?.artist ?? lang.t(.artist))
                        .font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    
                    // Style tag, duration, and AI badge
                    HStack(spacing: 8) {
                        Text(selectedStyle.localizedLabel)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                        
                        if let track = track {
                            Text(formatDuration(track.duration))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        if track?.isAIGenerated == true {
                            HStack(spacing: 3) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 8))
                                Text("AI")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.yellow.opacity(0.15)))
                        }
                    }
                    
                    if let lyrics = track?.lyrics, audio.currentLyricIndex >= 0, audio.currentLyricIndex < lyrics.count {
                        Text(lyrics[audio.currentLyricIndex].text)
                            .font(.system(size: 13)).italic()
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20).padding(.top, 6)
                    }
                }
                Spacer()
                HStack {
                    Image(systemName: "waveform.circle.fill").font(.system(size: 14))
                    Text(lang.t(.appBranding)).font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.45)).padding(.bottom, 20)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 24, y: 12)
    }
    
    private func exportCard() {
        let renderer = ImageRenderer(content: cardPreview.frame(width: 300, height: 400))
        renderer.scale = 2
        if let nsImage = renderer.nsImage {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = "ChiefMusic-Card.png"
            if panel.runModal() == .OK, let url = panel.url {
                if let tiff = nsImage.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) {
                    do {
                        try png.write(to: url)
                        ToastManager.shared.show(icon: "checkmark.circle.fill", String(format: LanguageManager.shared.t(.toastCardSavedTo), url.lastPathComponent), style: .success)
                        isPresented = false
                    } catch {
                        ToastManager.shared.show(icon: "xmark.circle.fill", LanguageManager.shared.t(.toastSaveFailed), style: .warning)
                    }
                }
            }
        }
    }

    private func shareViaSystemPanel() {
        let renderer = ImageRenderer(content: cardPreview.frame(width: 300, height: 400))
        renderer.scale = 2
        guard let nsImage = renderer.nsImage else { return }

        guard let window = NSApp.keyWindow ?? NSApp.windows.first,
              let contentView = window.contentView else { return }

        let picker = NSSharingServicePicker(items: [nsImage])
        picker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)

        ToastManager.shared.show(icon: "square.and.arrow.up", LanguageManager.shared.t(.toastSharePanelOpened), style: .info)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension CardStyle {
    var localizedLabel: String {
        let lang = LanguageManager.shared
        switch self {
        case .minimalist: return lang.t(.styleMinimalist)
        case .gradient: return lang.t(.styleGradient)
        case .dark: return lang.t(.styleDark)
        case .vinyl: return lang.t(.styleVinyl)
        }
    }
    var background: some View {
        Group {
            switch self {
            case .minimalist:
                LinearGradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.20), Color(red: 0.25, green: 0.25, blue: 0.30)], startPoint: .top, endPoint: .bottom)
            case .gradient:
                LinearGradient(colors: [Color(red: 0.4, green: 0.3, blue: 0.8), Color(red: 0.2, green: 0.6, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
            case .dark:
                Color(red: 0.08, green: 0.08, blue: 0.12)
            case .vinyl:
                LinearGradient(colors: [Color(red: 0.85, green: 0.65, blue: 0.4), Color(red: 0.6, green: 0.35, blue: 0.2)], startPoint: .top, endPoint: .bottom)
            }
        }
    }
    var previewColor: Color {
        switch self {
        case .minimalist: return Color(red: 0.2, green: 0.2, blue: 0.25)
        case .gradient: return Color(red: 0.4, green: 0.4, blue: 0.8)
        case .dark: return Color(red: 0.1, green: 0.1, blue: 0.12)
        case .vinyl: return Color(red: 0.8, green: 0.6, blue: 0.35)
        }
    }
}
