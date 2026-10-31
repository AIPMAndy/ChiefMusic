import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var audio: AudioService
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    
    @State private var isHovering = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        let isGlass = themeManager.current == .glass
        
        VStack(spacing: 0) {
            // Top bar - drag handle + close
            HStack {
                Capsule()
                    .fill(colors.textSecondary.opacity(0.2))
                    .frame(width: 32, height: 4)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(colors.textSecondary.opacity(0.4))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Main content
            HStack(spacing: 12) {
                // Album art (small)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, isGlass ? .dark : .light)
                    
                    if let art = audio.currentAlbumArt {
                        Image(nsImage: art)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 18, weight: .ultraLight))
                            .foregroundColor(colors.accent.opacity(0.3))
                    }
                }
                .frame(width: 56, height: 56)
                
                // Track info + controls
                VStack(alignment: .leading, spacing: 6) {
                    Text(audio.currentTrack?.title ?? LanguageManager.shared.t(.notPlaying))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                        .lineLimit(1)
                    
                    // Progress bar (thin)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(colors.textSecondary.opacity(0.15))
                                .frame(height: 3)
                            Capsule()
                                .fill(colors.accent)
                                .frame(width: geo.size.width * progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let ratio = min(max(location.x / 280, 0), 1) // 280 = mini player width
                        audio.seek(to: ratio * audio.duration)
                    }
                    
                    // Controls
                    HStack(spacing: 16) {
                        Button(action: { audio.playPrevious() }) {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 11, weight: .light))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { audio.togglePlay() }) {
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(colors.accent)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { audio.playNext() }) {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 11, weight: .light))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(formatTime(audio.currentTime))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(colors.textSecondary.opacity(0.5))
                    }
                    .foregroundColor(colors.textPrimary.opacity(0.7))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(
            ZStack {
                if isGlass {
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                    Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                } else {
                    colors.bg
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .onHover { isHovering = $0 }
    }
    
    private var progress: CGFloat {
        guard audio.duration > 0 else { return 0 }
        return CGFloat(audio.currentTime / audio.duration)
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Mini Player Window Controller
struct MiniPlayerWindow: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        MiniPlayerView(isPresented: $isPresented)
            .frame(width: 280)
    }
}
