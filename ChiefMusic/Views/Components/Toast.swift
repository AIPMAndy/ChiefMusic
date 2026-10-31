import SwiftUI

// MARK: - Toast Model
struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let message: String
    let style: ToastStyle
    
    enum ToastStyle {
        case info, success, warning
    }
    
    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    @Published var currentToast: ToastItem?
    
    func show(icon: String = "checkmark.circle.fill", _ message: String, style: ToastItem.ToastStyle = .success) {
        let toast = ToastItem(icon: icon, message: message, style: style)
        withAnimation(.spring(response: 0.3)) {
            currentToast = toast
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                if self.currentToast?.id == toast.id {
                    self.currentToast = nil
                }
            }
        }
    }
}

// MARK: - Toast Overlay View
struct ToastOverlay: View {
    @StateObject private var toastManager = ToastManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let toast = toastManager.currentToast {
                    toastView(toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .position(x: geometry.size.width - 150, y: 50)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(false)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toastManager.currentToast?.id)
        }
    }
    
    private func toastView(_ toast: ToastItem) -> some View {
        let colors = ThemeColors.colors(for: themeManager.current)
        
        return HStack(spacing: 10) {
            Image(systemName: toast.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(iconColor(for: toast.style, colors: colors))
            
            Text(toast.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(colors.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, themeManager.current == .glass ? .dark : .light)
                .overlay(
                    Capsule().stroke(colors.cardBorder, lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
        .padding(.top, 0)
    }
    
    private func iconColor(for style: ToastItem.ToastStyle, colors: ThemeColors) -> Color {
        switch style {
        case .info: return colors.accent
        case .success: return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .warning: return Color(red: 1.0, green: 0.7, blue: 0.3)
        }
    }
}
