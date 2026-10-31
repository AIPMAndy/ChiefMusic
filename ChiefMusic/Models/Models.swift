import Foundation

// MARK: - Track
struct Track: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    var fileURL: URL?
    var coverImage: String?
    var lyrics: [LyricLine]?
    var lyricsFileURL: URL?       // Path to .lrc file if exists
    var isAIGenerated: Bool = false
    var dateAdded: Date = Date()
    var audioFormat: String?      // e.g. "FLAC", "MP3", "AAC"
    var sampleRate: Double?       // e.g. 44100, 48000
    var bitRate: Int?             // e.g. 320000 (bps)
    var fileSize: Int64?          // bytes
    var style: String?            // AI generation style/prompt
    
    init(id: UUID = UUID(), title: String, artist: String = "", duration: TimeInterval = 0, fileURL: URL? = nil, coverImage: String? = nil, lyrics: [LyricLine]? = nil, isAIGenerated: Bool = false) {
        self.id = id
        self.title = title
        self.artist = artist.isEmpty ? LanguageManager.shared.t(.defaultArtist) : artist
        self.duration = duration
        self.fileURL = fileURL
        self.coverImage = coverImage
        self.lyrics = lyrics
        self.isAIGenerated = isAIGenerated
    }
}

// MARK: - Audio Quality Display
extension Track {
    var qualityDescription: String {
        var parts: [String] = []
        if let fmt = audioFormat { parts.append(fmt) }
        if let sr = sampleRate { parts.append(String(format: "%.1fkHz", sr / 1000)) }
        if let br = bitRate { parts.append("\(br / 1000)kbps") }
        if let size = fileSize {
            if size > 1_048_576 {
                parts.append(String(format: "%.1fMB", Double(size) / 1_048_576))
            } else {
                parts.append(String(format: "%.0fKB", Double(size) / 1024))
            }
        }
        return parts.isEmpty ? "" : parts.joined(separator: " · ")
    }
}

// MARK: - Lyric Line
struct LyricLine: Identifiable, Codable, Hashable {
    let id: UUID
    var time: TimeInterval
    var text: String
    
    init(id: UUID = UUID(), time: TimeInterval, text: String) {
        self.id = id
        self.time = time
        self.text = text
    }
}

// MARK: - Music Task
struct MusicTask: Identifiable {
    var id: String
    var status: TaskStatus
    var prompt: String
    var title: String?
    var audioURL: URL?
    var progress: Double
    
    enum TaskStatus: String {
        case pending, generating, completed, failed
    }
}

// MARK: - Card Style
enum CardStyle: String, CaseIterable {
    case minimalist = "Minimalist"
    case gradient = "Gradient"
    case dark = "Dark"
    case vinyl = "Vinyl"
}

// MARK: - Tab
enum AppTab: String, CaseIterable {
    case player = "Play"
    case generator = "Create"
    case library = "Library"
}

// MARK: - Sort Option
enum SortOption: String, CaseIterable {
    case dateNew = "最新添加"
    case dateOld = "最早添加"
    case nameAZ = "名称 A-Z"
    case nameZA = "名称 Z-A"
}

// MARK: - Style Preset for AI Generation
struct StylePreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let prompt: String
    let icon: String
    let category: PresetCategory

    enum PresetCategory: String {
        case relaxation = "放松"
        case focus = "专注"
        case social = "社交"
        case luxury = "奢华"
        case cultural = "文化"
    }

    static let all: [StylePreset] = [
        // 放松系列
        StylePreset(name: "深夜爵士", prompt: "late night jazz, smooth saxophone, soft piano, intimate lounge atmosphere, sophisticated", icon: "moon.stars", category: .relaxation),
        StylePreset(name: "冥想禅音", prompt: "meditation zen, tibetan singing bowls, nature sounds, peaceful, spiritual healing", icon: "leaf", category: .relaxation),
        StylePreset(name: "温泉疗愈", prompt: "spa healing music, gentle water sounds, soft flute, relaxation therapy, tranquil", icon: "drop", category: .relaxation),
        StylePreset(name: "雨夜咖啡", prompt: "rainy night cafe, lo-fi chill beats, warm vinyl texture, soft piano, cozy atmosphere", icon: "cloud.rain", category: .relaxation),

        // 专注系列
        StylePreset(name: "深度工作", prompt: "deep work focus, minimal ambient, subtle rhythm, concentration enhancing, productivity", icon: "brain.head.profile", category: .focus),
        StylePreset(name: "创意灵感", prompt: "creative inspiration, uplifting electronic, innovative sounds, artistic flow state", icon: "lightbulb", category: .focus),
        StylePreset(name: "阅读时光", prompt: "reading time, classical chamber music, soft strings, intellectual atmosphere, elegant", icon: "book", category: .focus),
        StylePreset(name: "编码节奏", prompt: "coding rhythm, lo-fi hip-hop beats, steady tempo, programmer's flow, focused energy", icon: "chevron.left.forwardslash.chevron.right", category: .focus),

        // 社交系列
        StylePreset(name: "派对电音", prompt: "party electronic dance, energetic beats, club atmosphere, celebration vibes, exciting", icon: "party.popper", category: .social),
        StylePreset(name: "鸡尾酒会", prompt: "cocktail party, smooth jazz trio, sophisticated lounge, elegant social gathering", icon: "wineglass", category: .social),
        StylePreset(name: "下午茶", prompt: "afternoon tea, light classical, string quartet, refined and graceful, high society", icon: "cup.and.saucer", category: .social),
        StylePreset(name: "游艇派对", prompt: "yacht party, tropical house, summer vibes, luxury lifestyle, ocean breeze", icon: "sailboat", category: .social),

        // 奢华系列
        StylePreset(name: "皇家古典", prompt: "royal classical, grand orchestra, baroque style, majestic and luxurious, palace atmosphere", icon: "crown", category: .luxury),
        StylePreset(name: "歌剧之夜", prompt: "opera night, dramatic vocals, orchestral grandeur, theatrical and elegant, high culture", icon: "theatermasks", category: .luxury),
        StylePreset(name: "钢琴独奏", prompt: "piano solo, concert grand piano, virtuoso performance, sophisticated and emotional", icon: "pianokeys", category: .luxury),
        StylePreset(name: "爵士大乐队", prompt: "big band jazz, swing era, brass section, vintage luxury, golden age glamour", icon: "music.note.list", category: .luxury),

        // 文化系列
        StylePreset(name: "中国古风", prompt: "chinese traditional, guzheng, pipa, bamboo flute, ancient poetry, elegant oriental", icon: "character.textbox", category: .cultural),
        StylePreset(name: "日式和风", prompt: "japanese traditional, koto, shakuhachi, zen garden, peaceful wabi-sabi aesthetic", icon: "mountain.2", category: .cultural),
        StylePreset(name: "印度灵性", prompt: "indian spiritual, sitar, tabla, raga meditation, mystical and transcendent", icon: "sparkle", category: .cultural),
        StylePreset(name: "拉丁热情", prompt: "latin passion, salsa, bossa nova, acoustic guitar, rhythmic and romantic", icon: "flame", category: .cultural),

        // 经典保留
        StylePreset(name: "电影配乐", prompt: "cinematic epic, orchestral, dramatic, movie soundtrack, heroic and emotional", icon: "film", category: .luxury),
        StylePreset(name: "合成波", prompt: "synthwave retro, 80s synth, neon aesthetics, nostalgic, pulsing rhythm", icon: "waveform.path", category: .social),
    ]

    // 按分类分组
    static func grouped() -> [PresetCategory: [StylePreset]] {
        Dictionary(grouping: all, by: { $0.category })
    }
}

// MARK: - AppState (Global app coordination)
import SwiftUI

class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .player

    static let shared = AppState()

    func switchToPlayer() {
        selectedTab = .player
    }

    func switchToGenerator() {
        selectedTab = .generator
    }

    func switchToLibrary() {
        selectedTab = .library
    }
}

// MARK: - Design System (统一的设计规范)

/// 字体系统 - 只使用这些预定义的字体大小
enum Typography {
    // 标题层级
    static let title1 = Font.system(size: 28, weight: .bold)      // 页面主标题
    static let title2 = Font.system(size: 20, weight: .semibold)  // 卡片标题
    static let title3 = Font.system(size: 16, weight: .semibold)  // 小标题

    // 正文层级
    static let body = Font.system(size: 14, weight: .regular)     // 正文
    static let bodyBold = Font.system(size: 14, weight: .semibold)

    // 辅助文字
    static let caption = Font.system(size: 12, weight: .regular)  // 说明文字
    static let captionBold = Font.system(size: 12, weight: .semibold)

    // 小字
    static let footnote = Font.system(size: 10, weight: .regular) // 最小文字
    static let footnoteBold = Font.system(size: 10, weight: .semibold)
}

/// 间距系统 - 只使用这些预定义的间距
enum Spacing {
    static let xs: CGFloat = 4      // 极小间距
    static let sm: CGFloat = 8      // 小间距
    static let md: CGFloat = 12     // 中等间距
    static let lg: CGFloat = 16     // 大间距
    static let xl: CGFloat = 24     // 超大间距
    static let xxl: CGFloat = 32    // 巨大间距
}

/// 圆角系统
enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}

/// 按钮尺寸系统
enum ButtonSize {
    static let small: CGFloat = 32      // 小按钮（辅助功能）
    static let medium: CGFloat = 40     // 中等按钮（次要操作）
    static let large: CGFloat = 56      // 大按钮（主要操作）
    static let hero: CGFloat = 64       // 英雄按钮（核心操作）
}

/// 图标尺寸系统
enum IconSize {
    static let small: CGFloat = 12
    static let medium: CGFloat = 14
    static let large: CGFloat = 16
    static let xlarge: CGFloat = 20
    static let hero: CGFloat = 24
}
