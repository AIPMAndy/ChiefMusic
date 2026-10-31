import SwiftUI
import AppKit

/// Generates unique album art for tracks based on their style/prompt
/// Uses deterministic hashing so the same track always gets the same cover
struct CoverArtGenerator {
    
    // MARK: - Style Color Palettes
    static let palettes: [(bg: [Color], accent: Color, name: String)] = [
        // Lo-fi: warm amber/brown
        (bg: [Color(red: 0.18, green: 0.12, blue: 0.08), Color(red: 0.35, green: 0.22, blue: 0.12)],
         accent: Color(red: 0.95, green: 0.75, blue: 0.4), name: "lofi"),
        // Jazz: deep blue/gold
        (bg: [Color(red: 0.05, green: 0.08, blue: 0.18), Color(red: 0.12, green: 0.15, blue: 0.3)],
         accent: Color(red: 0.95, green: 0.82, blue: 0.35), name: "jazz"),
        // Electronic: cyan/purple
        (bg: [Color(red: 0.05, green: 0.02, blue: 0.15), Color(red: 0.15, green: 0.05, blue: 0.25)],
         accent: Color(red: 0.3, green: 0.9, blue: 1.0), name: "electronic"),
        // Classical: cream/gold
        (bg: [Color(red: 0.12, green: 0.1, blue: 0.08), Color(red: 0.2, green: 0.18, blue: 0.14)],
         accent: Color(red: 0.85, green: 0.72, blue: 0.5), name: "classical"),
        // Ambient: teal/dark
        (bg: [Color(red: 0.03, green: 0.1, blue: 0.12), Color(red: 0.08, green: 0.18, blue: 0.2)],
         accent: Color(red: 0.4, green: 0.85, blue: 0.75), name: "ambient"),
        // Rock: red/dark
        (bg: [Color(red: 0.15, green: 0.03, blue: 0.03), Color(red: 0.25, green: 0.08, blue: 0.05)],
         accent: Color(red: 1.0, green: 0.35, blue: 0.2), name: "rock"),
        // R&B: purple/pink
        (bg: [Color(red: 0.12, green: 0.05, blue: 0.15), Color(red: 0.22, green: 0.1, blue: 0.25)],
         accent: Color(red: 0.9, green: 0.5, blue: 0.7), name: "rnb"),
        // Hip-hop: orange/dark
        (bg: [Color(red: 0.1, green: 0.06, blue: 0.02), Color(red: 0.2, green: 0.12, blue: 0.04)],
         accent: Color(red: 1.0, green: 0.6, blue: 0.15), name: "hiphop"),
        // Chinese: vermillion/dark red
        (bg: [Color(red: 0.12, green: 0.04, blue: 0.04), Color(red: 0.2, green: 0.06, blue: 0.06)],
         accent: Color(red: 0.9, green: 0.25, blue: 0.15), name: "chinese"),
        // Cinematic: dark blue/silver
        (bg: [Color(red: 0.04, green: 0.05, blue: 0.1), Color(red: 0.08, green: 0.1, blue: 0.18)],
         accent: Color(red: 0.75, green: 0.8, blue: 0.9), name: "cinematic"),
        // Acoustic: warm green
        (bg: [Color(red: 0.08, green: 0.1, blue: 0.06), Color(red: 0.15, green: 0.18, blue: 0.1)],
         accent: Color(red: 0.7, green: 0.85, blue: 0.5), name: "acoustic"),
        // Synthwave: neon pink/blue
        (bg: [Color(red: 0.08, green: 0.02, blue: 0.12), Color(red: 0.15, green: 0.04, blue: 0.2)],
         accent: Color(red: 1.0, green: 0.3, blue: 0.7), name: "synthwave"),
        // Default: dark grey/blue
        (bg: [Color(red: 0.08, green: 0.08, blue: 0.1), Color(red: 0.15, green: 0.15, blue: 0.2)],
         accent: Color(red: 0.5, green: 0.6, blue: 0.9), name: "default"),
    ]
    
    // MARK: - Generate Cover Art
    @MainActor static func generate(for track: Track, size: CGFloat = 300) -> NSImage {
        let hash = deterministicHash(track.title + (track.style ?? ""))
        let paletteIndex = hash % palettes.count
        let palette = palettes[paletteIndex]
        let patternType = (hash / 10) % 5
        
        let renderer = ImageRenderer(content:
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: palette.bg,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Pattern overlay
                patternView(type: patternType, accent: palette.accent, hash: hash)
                
                // Vignette
                RadialGradient(
                    colors: [.clear, .black.opacity(0.4)],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.7
                )
                
                // Bottom text area
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                            if track.isAIGenerated {
                                Text("AI酋长Andy")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(palette.accent.opacity(0.7))
                            }
                        }
                        Spacer()
                    }
                    .padding(16)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        
        renderer.scale = 2
        return renderer.nsImage ?? NSImage(size: NSSize(width: size, height: size))
    }
    
    // MARK: - Pattern Views
    @ViewBuilder
    private static func patternView(type: Int, accent: Color, hash: Int) -> some View {
        switch type {
        case 0:
            // Concentric circles
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .stroke(accent.opacity(0.08 - Double(i) * 0.015), lineWidth: 1)
                        .frame(width: CGFloat(80 + i * 60), height: CGFloat(80 + i * 60))
                }
            }
            .offset(x: CGFloat((hash % 40) - 20), y: CGFloat((hash % 30) - 15))
            
        case 1:
            // Scattered dots
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(accent.opacity(0.06 + Double(i % 3) * 0.02))
                        .frame(width: CGFloat(4 + (i * 7 + hash) % 20),
                               height: CGFloat(4 + (i * 7 + hash) % 20))
                        .offset(x: CGFloat((i * 31 + hash) % 200 - 100),
                                y: CGFloat((i * 47 + hash) % 200 - 100))
                }
            }
            
        case 2:
            // Diagonal lines
            ZStack {
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(accent.opacity(0.04))
                        .frame(width: 2, height: 400)
                        .rotationEffect(.degrees(30))
                        .offset(x: CGFloat(i * 50 - 125))
                }
            }
            
        case 3:
            // Wave bars
            ZStack {
                ForEach(0..<8, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(accent.opacity(0.06 + Double(i % 3) * 0.02))
                        .frame(width: 4, height: CGFloat(40 + (i * 13 + hash) % 120))
                        .offset(x: CGFloat(i * 36 - 126), y: CGFloat((i * 17 + hash) % 60 - 30))
                }
            }
            
        default:
            // Single accent shape
            ZStack {
                Circle()
                    .fill(accent.opacity(0.06))
                    .frame(width: 180, height: 180)
                    .offset(x: CGFloat((hash % 60) - 30),
                            y: CGFloat((hash % 40) - 20))
            }
        }
    }
    
    // MARK: - Deterministic Hash
    private static func deterministicHash(_ string: String) -> Int {
        var hash = 5381
        for char in string.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(char)
        }
        return abs(hash)
    }
}
