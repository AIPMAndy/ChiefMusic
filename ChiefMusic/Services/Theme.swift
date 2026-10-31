import SwiftUI

// MARK: - Theme
enum AppTheme: String, CaseIterable {
    case glass = "流光玻璃"
    case classic = "经典"
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var current: AppTheme {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "app_theme") }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme") ?? "流光玻璃"
        self.current = AppTheme(rawValue: saved) ?? .glass
    }
}

// MARK: - Theme Colors
struct ThemeColors {
    let bg: Color
    let bgCard: Color
    let accent: Color
    let accentSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let shadowLight: Color
    let shadowDark: Color
    let cardBorder: Color
    let buttonBg: Color
    
    static func colors(for theme: AppTheme) -> ThemeColors {
        switch theme {
        case .glass:
            return ThemeColors(
                bg: Color.clear,
                bgCard: Color.white.opacity(0.06),
                accent: Color(red: 0.45, green: 0.65, blue: 1.0),
                accentSecondary: Color(red: 0.80, green: 0.50, blue: 1.0),
                textPrimary: Color.white.opacity(0.92),
                textSecondary: Color.white.opacity(0.50),
                shadowLight: Color.white.opacity(0.05),
                shadowDark: Color.black.opacity(0.3),
                cardBorder: Color.white.opacity(0.10),
                buttonBg: Color.white.opacity(0.06)
            )
        case .classic:
            return ThemeColors(
                bg: Color(red: 0.92, green: 0.91, blue: 0.90),
                bgCard: Color(red: 0.92, green: 0.91, blue: 0.90),
                accent: Color(red: 0.40, green: 0.55, blue: 0.85),
                accentSecondary: Color(red: 0.40, green: 0.55, blue: 0.85),
                textPrimary: Color(red: 0.15, green: 0.15, blue: 0.18),
                textSecondary: Color(red: 0.45, green: 0.45, blue: 0.50),
                shadowLight: Color.white.opacity(0.7),
                shadowDark: Color.black.opacity(0.15),
                cardBorder: Color.clear,
                buttonBg: Color(red: 0.92, green: 0.91, blue: 0.90)
            )
        }
    }
}

// MARK: - Aurora Background — flowing aurora with real motion
struct AuroraBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Deep dark base
            Color(red: 0.04, green: 0.04, blue: 0.08)
                .ignoresSafeArea()
            
            // Aurora blobs — each one moves on its own path
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Blob 1: Blue
                blob(size: 400,
                     x: w * 0.5 + sin(phase * 0.7) * w * 0.25,
                     y: h * 0.3 + cos(phase * 0.5) * h * 0.2,
                     color1: Color(red: 0.15, green: 0.4, blue: 1.0),
                     color2: Color(red: 0.1, green: 0.2, blue: 0.6),
                     opacity: 0.45)
                
                // Blob 2: Purple
                blob(size: 350,
                     x: w * 0.7 + cos(phase * 0.6) * w * 0.2,
                     y: h * 0.6 + sin(phase * 0.8) * h * 0.25,
                     color1: Color(red: 0.6, green: 0.2, blue: 1.0),
                     color2: Color(red: 0.3, green: 0.1, blue: 0.5),
                     opacity: 0.40)
                
                // Blob 3: Cyan
                blob(size: 300,
                     x: w * 0.3 + sin(phase * 0.9) * w * 0.2,
                     y: h * 0.7 + cos(phase * 0.4) * h * 0.15,
                     color1: Color(red: 0.1, green: 0.7, blue: 0.9),
                     color2: Color(red: 0.05, green: 0.3, blue: 0.5),
                     opacity: 0.35)
                
                // Blob 4: Pink
                blob(size: 280,
                     x: w * 0.6 + cos(phase * 0.5) * w * 0.3,
                     y: h * 0.2 + sin(phase * 0.7) * h * 0.2,
                     color1: Color(red: 0.9, green: 0.3, blue: 0.6),
                     color2: Color(red: 0.4, green: 0.1, blue: 0.3),
                     opacity: 0.30)
                
                // Blob 5: Green-teal
                blob(size: 260,
                     x: w * 0.2 + sin(phase * 1.1) * w * 0.15,
                     y: h * 0.5 + cos(phase * 0.6) * h * 0.2,
                     color1: Color(red: 0.2, green: 0.8, blue: 0.6),
                     color2: Color(red: 0.1, green: 0.3, blue: 0.3),
                     opacity: 0.25)
            }
            
            // Subtle glass tint overlay
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                phase = .pi * 4
            }
        }
    }
    
    private func blob(size: CGFloat, x: CGFloat, y: CGFloat, color1: Color, color2: Color, opacity: Double) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color1.opacity(opacity), color2.opacity(opacity * 0.3), Color.clear], center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .blur(radius: 50)
            .blendMode(.screen)
    }
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        content.background(
            Group {
                if themeManager.current == .glass {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.03))
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(colors.cardBorder, lineWidth: 0.5)
                    }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(colors.bgCard)
                        .shadow(color: colors.shadowDark, radius: 6, x: -4, y: -4)
                        .shadow(color: colors.shadowLight, radius: 6, x: 4, y: 4)
                }
            }
        )
    }
}


