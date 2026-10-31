import SwiftUI

enum LangKey: String {
    // Tab labels
    case play, create, share, library
    
    // Player
    case noTrack, importAudio, importLyrics, synced, noLyrics, importLrcHint, artist
    case playlist, playlistEmpty, playlistDragHint, playAll, clearPlaylist, addedToPlaylist, playlistCleared, alreadyInPlaylist
    case clearPlaylistTitle, clearPlaylistMessage
    case lyrics, importLyricsHint, lrcFormats
    case dragDropHint, releaseToImport
    
    // Generator
    case createMusic, describeHint, styleLabel, durationLabel, generating, generateMusic, generated, aiGenerated, apiKeyLabel, apiSettings, dismiss
    case generatedAdded
    
    // Share
    case cardStyle, export
    case styleMinimalist, styleGradient, styleDark, styleVinyl
    case shareCard, shareHint, cardSaved, cardSaveFailed
    
    // Library
    case libraryTitle, libraryEmpty, libraryImportHint, importedToLibrary, deleteConfirm, deleted
    case sortBy, sortNewest, sortOldest, sortAZ, sortZA
    
    // Settings
    case settings, language, chinese, english, apiConfig, about, version
    case theme, themeGlass, themeClassic
    case apiSave, apiSaved
    
    // Playback
    case sequential, singleLoop, shuffle, listLoop

    // Brand
    case brandName, brandSubtitle

    // License & Activation
    case activateTitle, trialRemaining, trialExpired, activated, activatedOffline, offlineDays
    case deviceCode, deviceCodeHint, deviceCodeCopied, scanQRCode
    case enterLicenseKey, licenseKeyPlaceholder, activateButton, activating
    case licenseType, activationDate, expiresAt
    case licenseManagement, manage, removeLicense

    // Purchase
    case monthlyPlan, yearlyPlan, recommended, devices, save
    case contactPurchase, contactEmail, contactDiscord, wechat
    case priceMonthly, priceYearly, priceMonthlyCurrency, priceYearlyCurrency
    case featureUnlimited, featureLyrics, featureStyles, featureImport, featureSyncLyrics, featureMultiDevice, featurePrioritySupport
    case whyActivate

    // Activation Errors
    case activationSuccess, activationSuccessExpiry
    case errorLicenseNotExist, errorLicenseDisabled, errorDeviceLimit, errorLicenseExpired
    case errorNetworkTimeout, errorNoInternet, errorCannotConnect, errorActivationFailed
    case errorRetrying, errorInvalidFormat

    // Trial
    case continueTrialButton, trialExpiredTitle, trialExpiredMessage
    case enterLicenseButton, exitApp

    // License types
    case licenseTypeTrial, licenseTypeMonthly, licenseTypeYearly
    case activationFailedWithError, networkErrorRetrying
    case purchaseContactInfo, purchaseDetailsInfo, contactCopied

    // API Settings
    case builtInKeyAvailable, advancedUserConfig, testBuiltInKey, testCustomKey
    case keyTesting, keyTestSuccess, keyTestFailed, keyInvalid, keySaved
    case importing

    // Library detailed
    case tracksCount, searchPlaceholder, noTracksFound, noMatchingTracks
    case startCreatingOrImport, createNow, importMusic, trackHeader, durationHeader
    case deleteAlertTitle, deleteAlertMessage, deleteButton, cancel

    // Generator detailed
    case generatorSubtitle, promptPlaceholder, promptRequired, generatingTitle
    case estimatedTime, cancelGeneration, seconds, expectedDuration, expectedDurationHint
    case generationStats
    case categoryRelaxation, categoryFocus, categorySocial, categoryLuxury, categoryCultural
    case generatedHistory, clearHistory, retry, generationFailed

    // Player detailed
    case playHistory, welcomeTitle, welcomeSubtitle, welcomeValueProp
    case defaultArtist

    // Toast Messages
    case toastGenerationCancelled, toastGeneratingLyrics, toastComposingMusic
    case toastLyricsGenerationFailed, toastSaveFailed
    case toastLoadingLyrics, toastLyricsFileNotExist
    case toastPlaybackSpeed, toastRemovedFromFavorites, toastAddedToFavorites
    case toastEQMode, toastLyricsAutoLoaded, toastLyricsAutoLoadedCount
    case toastCardSavedTo, toastSharePanelOpened

    // Enums - PlaybackMode
    case modeSequential, modeSingleLoop, modeShuffle, modeListLoop

    // Enums - EQPreset
    case eqFlat, eqBass, eqVocal, eqClassical, eqElectronic

    // Style Presets
    case styleDeepNightJazz, styleMeditationZen, styleSpaHealing, styleRainyNightCafe
    case styleDeepWork, styleCreativeInspiration, styleReadingTime, styleCodingRhythm
    case stylePartyElectronic, styleCocktailParty, styleAfternoonTea, styleYachtParty
    case styleRoyalClassical, styleOperaNight, stylePianoSolo, styleBigBandJazz
    case styleChineseTraditional, styleJapaneseWafuu, styleIndianSpiritual, styleLatinPassion
    case styleCinematic, styleSynthwave

    // Additional UI text
    case notPlaying, orImportLocalMusic, titleUpdated, artistUpdated
    case clickToImportLyrics, enterSongTitle, enterArtistName
    case navigatingToGenerator, editTrackInfo, trackTitle
    case noPlayHistory

    // Menu items
    case menuView, menuMiniPlayer, menuPlayback, menuPlayPause
    case menuPrevious, menuNext, menuRewind5s, menuForward5s
    case menuVolumeUp, menuVolumeDown, menuSpeedUp, menuSpeedDown
    case menuResetSpeed, menuFavorite, menuKeyboardShortcuts
    case menuCheckUpdates, menuOK, menuClose, menuExit
    case favoriteTooltip, playbackSpeedTooltip, historyLabel
    case builtIn, custom

    // Keyboard shortcuts dialog
    case shortcutsTitle, shortcutsFileOps, shortcutsOpenAudio
    case shortcutsPlaybackControl, shortcutsVolumeControl, shortcutsSpeed, shortcutsOther
    case menuLicense, licenseStatus, updateMessage

    // Additional UI strings
    case days, licenseKeyLabel, perMonth, perYear, devicesSave
    case activationFailedDefault, qrCodeContact
    case leaveEmptyForBuiltIn, apiKeySaved, noAvailableKey, invalidURL
    case connectionFailed, invalidResponse, keyAvailable, errorCode
    case stylePlaceholder

    // Generation stages
    case stageUnderstanding, stageMelody, stageHarmony, stageRhythm, stageMixing
    case today, yesterday, generatingStatus

    // Branding
    case appBranding

    // Network errors
    case errorTimeout, errorNoConnection, errorCannotReach, errorConnectionLost
    case errorBadRequest, errorUnauthorized, errorForbidden, errorTooManyRequests, errorServer

    // Misc
    case loadFailed, shortcutSpace, shortcutArrows
    case shortcutPlayPause, shortcutSeek, shortcutImport
    case pause, previous, next
    case generationCompleteAndPlaying, addedToLibraryAndPlaylist
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var current: String {
        didSet {
            UserDefaults.standard.set(current, forKey: "app_language")
        }
    }
    
    init() {
        self.current = UserDefaults.standard.string(forKey: "app_language") ?? "zh"
    }
    
    func t(_ key: LangKey) -> String {
        current == "zh" ? Self.zh[key] ?? key.rawValue : Self.en[key] ?? key.rawValue
    }
    
    static let zh: [LangKey: String] = [
        .play: "播放",
        .create: "创作",
        .share: "分享",
        .library: "歌库",
        .noTrack: "暂无曲目",
        .importAudio: "导入音频",
        .importLyrics: "导入歌词",
        .synced: "已同步",
        .noLyrics: "暂无歌词",
        .importLrcHint: "导入 .lrc 文件同步歌词",
        .artist: "未知艺术家",
        .playlist: "歌单",
        .playlistEmpty: "拖入音频或点击 +",
        .playlistDragHint: "拖入音频文件添加到歌单",
        .playAll: "播放全部",
        .clearPlaylist: "清空歌单",
        .addedToPlaylist: "已加入歌单",
        .playlistCleared: "歌单已清空",
        .alreadyInPlaylist: "歌曲已在歌单中",
        .clearPlaylistTitle: "确认清空歌单",
        .clearPlaylistMessage: "将清空歌单中的 %d 首歌曲，此操作不可恢复。",
        .lyrics: "歌词",
        .importLyricsHint: "⌘L 导入歌词",
        .lrcFormats: ".lrc / .md / .txt",
        .dragDropHint: "松开添加到歌单",
        .releaseToImport: "松开添加到歌单",
        .createMusic: "创作音乐",
        .describeHint: "描述你想听的音乐",
        .styleLabel: "风格",
        .durationLabel: "时长",
        .generating: "生成中...",
        .generateMusic: "生成音乐",
        .generated: "已生成",
        .aiGenerated: "AI 生成",
        .apiKeyLabel: "ACE-Step API Key",
        .apiSettings: "API 设置",
        .dismiss: "关闭",
        .generatedAdded: "生成完毕，已加入歌单",
        .cardStyle: "卡片风格",
        .export: "导出",
        .styleMinimalist: "极简",
        .styleGradient: "渐变",
        .styleDark: "暗黑",
        .styleVinyl: "唱片",
        .shareCard: "分享卡片",
        .shareHint: "创建一张音乐分享卡片",
        .cardSaved: "卡片已保存",
        .cardSaveFailed: "保存失败",
        .libraryTitle: "歌库",
        .libraryEmpty: "歌库为空",
        .libraryImportHint: "点击导入按钮添加音乐",
        .importedToLibrary: "已导入到歌库",
        .deleteConfirm: "确认删除？",
        .deleted: "已删除",
        .sortBy: "排序",
        .sortNewest: "最新",
        .sortOldest: "最早",
        .sortAZ: "A→Z",
        .sortZA: "Z→A",
        .settings: "设置",
        .language: "语言",
        .chinese: "中文",
        .english: "English",
        .apiConfig: "API 配置",
        .about: "关于",
        .version: "版本",
        .theme: "主题",
        .themeGlass: "流光玻璃",
        .themeClassic: "经典",
        .apiSave: "保存",
        .apiSaved: "API Key 已保存",
        .sequential: "顺序",
        .singleLoop: "单曲循环",
        .shuffle: "随机",
        .listLoop: "列表循环",
        .brandName: "AI酋长",
        .brandSubtitle: "Andy出品",
        .loadFailed: "加载失败",
        .shortcutSpace: "Space",
        .shortcutArrows: "← →",
        .shortcutPlayPause: "播放/暂停",
        .shortcutSeek: "快进/快退 5 秒",
        .shortcutImport: "导入音频",
        .pause: "暂停",
        .previous: "上一首",
        .next: "下一首",
        .generationCompleteAndPlaying: "✨ 创作完成，正在为您播放",
        .addedToLibraryAndPlaylist: "已加入歌库和播放列表",

        // License & Activation
        .activateTitle: "激活 ChiefMusic",
        .trialRemaining: "试用剩余",
        .trialExpired: "试用已过期",
        .activated: "已激活",
        .activatedOffline: "已激活（离线模式 - 剩余",
        .offlineDays: "天）",
        .deviceCode: "设备码",
        .deviceCodeHint: "请将此设备码提供给管理员以获取授权码",
        .deviceCodeCopied: "✓ 已复制到剪贴板",
        .scanQRCode: "扫码发送给客服",
        .enterLicenseKey: "请输入授权码",
        .licenseKeyPlaceholder: "CHIEF-XXXXX-XXXXX-XXXXX-XXXXX",
        .activateButton: "激活",
        .activating: "正在激活，请稍候...",
        .licenseType: "授权类型:",
        .activationDate: "激活日期:",
        .expiresAt: "授权有效期至",
        .licenseManagement: "授权管理",
        .manage: "管理",
        .removeLicense: "移除授权",

        // Purchase
        .monthlyPlan: "按月订阅",
        .yearlyPlan: "按年订阅",
        .recommended: "推荐",
        .devices: "台设备",
        .save: "省",
        .contactPurchase: "联系购买",
        .contactEmail: "邮箱",
        .contactDiscord: "Discord",
        .wechat: "微信",
        .priceMonthly: "29",
        .priceYearly: "199",
        .priceMonthlyCurrency: "¥",
        .priceYearlyCurrency: "¥",
        .featureUnlimited: "AI 音乐生成（无限次数）",
        .featureLyrics: "歌词智能创作",
        .featureStyles: "20+ 精选风格预设",
        .featureImport: "导入本地音乐",
        .featureSyncLyrics: "歌词同步显示",
        .featureMultiDevice: "多设备同步",
        .featurePrioritySupport: "优先技术支持",
        .whyActivate: "激活后享有",

        // Activation Errors
        .activationSuccess: "激活成功！",
        .activationSuccessExpiry: "授权有效期至",
        .errorLicenseNotExist: "授权码不存在，请检查是否输入正确",
        .errorLicenseDisabled: "此授权码已被禁用，请联系管理员",
        .errorDeviceLimit: "此授权码已绑定 2 台设备，请联系管理员解绑",
        .errorLicenseExpired: "授权码已过期，请续费",
        .errorNetworkTimeout: "网络连接超时，正在重试",
        .errorNoInternet: "无法连接到互联网，请检查网络设置",
        .errorCannotConnect: "无法连接到服务器，请检查网络或稍后重试",
        .errorActivationFailed: "激活失败，已重试 3 次。请检查网络连接或联系技术支持",
        .errorRetrying: "网络错误，正在重试...",
        .errorInvalidFormat: "授权码格式错误",

        // Trial
        .continueTrialButton: "稍后激活，继续试用（剩余",
        .trialExpiredTitle: "试用已过期",
        .trialExpiredMessage: "感谢您试用 ChiefMusic\n请输入授权码以继续使用",
        .enterLicenseButton: "输入授权码",
        .exitApp: "退出应用",

        // License types
        .licenseTypeTrial: "试用版",
        .licenseTypeMonthly: "按月订阅",
        .licenseTypeYearly: "按年订阅",
        .activationFailedWithError: "激活失败: %@",
        .networkErrorRetrying: "网络错误（代码 %d），正在重试...",
        .purchaseContactInfo: "微信: AIPMAndy",
        .purchaseDetailsInfo: """
微信号: AIPMAndy

按月订阅: ¥29/月（2 台设备）
按年订阅: ¥199/年（2 台设备，省 ¥149）

微信号已复制到剪贴板
""",
        .contactCopied: "AIPMAndy",

        // API Settings
        .builtInKeyAvailable: "✅ 已内置可用 Key，无需配置即可使用",
        .advancedUserConfig: "高级用户可配置自己的 Key（可选）",
        .testBuiltInKey: "测试内置 Key",
        .testCustomKey: "测试自定义 Key",
        .keyTesting: "测试中...",
        .keyTestSuccess: "✅ Key 可用！",
        .keyTestFailed: "❌ 连接失败",
        .keyInvalid: "❌ Key 无效或已过期",
        .keySaved: "已保存",
        .importing: "正在导入...",

        // Library detailed
        .tracksCount: "首歌曲",
        .searchPlaceholder: "搜索歌曲...",
        .noTracksFound: "您的音乐库空空如也",
        .noMatchingTracks: "未找到匹配的歌曲",
        .startCreatingOrImport: "AI 创作新音乐或导入本地收藏",
        .createNow: "立即创作",
        .importMusic: "导入音乐",
        .trackHeader: "歌曲",
        .durationHeader: "时长",
        .deleteAlertTitle: "删除确认",
        .deleteAlertMessage: "确定要从曲库中删除「%@」吗？",
        .deleteButton: "删除",
        .cancel: "取消",

        // Generator detailed
        .generatorSubtitle: "选择风格，描述您的创意，开始创作",
        .promptPlaceholder: "一首轻松的 Lo-Fi 音乐，适合深夜编码...",
        .promptRequired: "请输入创作描述",
        .generatingTitle: "正在为您创作...",
        .estimatedTime: "预计剩余",
        .cancelGeneration: "取消生成",
        .seconds: "秒",
        .expectedDuration: "预计需要 30-90 秒",
        .expectedDurationHint: "实际时间取决于服务器负载",
        .generationStats: "已创作 %d 首音乐",
        .categoryRelaxation: "放松",
        .categoryFocus: "专注",
        .categorySocial: "社交",
        .categoryLuxury: "奢华",
        .categoryCultural: "文化",

        // Generator extra
        .generatedHistory: "生成历史",
        .clearHistory: "清空",
        .retry: "重试",
        .generationFailed: "生成失败",

        // Player detailed
        .playHistory: "播放历史",
        .welcomeTitle: "欢迎使用 ChiefMusic",
        .welcomeSubtitle: "AI 酋长为您创作专属音乐",
        .welcomeValueProp: "30 秒生成，无限可能",
        .defaultArtist: "AI 酋长 Andy",

        // Style Presets
        .styleDeepNightJazz: "深夜爵士",
        .styleMeditationZen: "冥想禅音",
        .styleSpaHealing: "温泉疗愈",
        .styleRainyNightCafe: "雨夜咖啡",
        .styleDeepWork: "深度工作",
        .styleCreativeInspiration: "创意灵感",
        .styleReadingTime: "阅读时光",
        .styleCodingRhythm: "编码节奏",
        .stylePartyElectronic: "派对电音",
        .styleCocktailParty: "鸡尾酒会",
        .styleAfternoonTea: "下午茶",
        .styleYachtParty: "游艇派对",
        .styleRoyalClassical: "皇家古典",
        .styleOperaNight: "歌剧之夜",
        .stylePianoSolo: "钢琴独奏",
        .styleBigBandJazz: "爵士大乐队",
        .styleChineseTraditional: "中国古风",
        .styleJapaneseWafuu: "日式和风",
        .styleIndianSpiritual: "印度灵性",
        .styleLatinPassion: "拉丁热情",
        .styleCinematic: "电影配乐",
        .styleSynthwave: "合成波",

        // Toast Messages
        .toastGenerationCancelled: "已取消生成",
        .toastGeneratingLyrics: "💭 AI 正在构思歌词...",
        .toastComposingMusic: "🎵 正在为您谱曲...",
        .toastLyricsGenerationFailed: "歌词生成失败",
        .toastSaveFailed: "保存失败",
        .toastLoadingLyrics: "正在加载歌词...",
        .toastLyricsFileNotExist: "歌词文件不存在",
        .toastPlaybackSpeed: "播放速度",
        .toastRemovedFromFavorites: "已取消收藏",
        .toastAddedToFavorites: "已添加到收藏",
        .toastEQMode: "音效",
        .toastLyricsAutoLoaded: "歌词已自动加载",
        .toastLyricsAutoLoadedCount: "自动加载了 %d 首歌词",
        .toastCardSavedTo: "卡片已保存到 %@",
        .toastSharePanelOpened: "已打开分享面板",

        // Enums - PlaybackMode
        .modeSequential: "顺序",
        .modeSingleLoop: "单曲循环",
        .modeShuffle: "随机",
        .modeListLoop: "列表循环",

        // Enums - EQPreset
        .eqFlat: "原声",
        .eqBass: "低音增强",
        .eqVocal: "人声清晰",
        .eqClassical: "古典",
        .eqElectronic: "电子",

        // Additional UI text
        .notPlaying: "未播放",
        .orImportLocalMusic: "或导入本地音乐",
        .titleUpdated: "歌名已更新",
        .artistUpdated: "艺术家已更新",
        .clickToImportLyrics: "点击导入 LRC 或 Markdown 格式歌词",
        .enterSongTitle: "输入歌名",
        .enterArtistName: "输入艺术家名称",
        .navigatingToGenerator: "正在前往创作页面",
        .editTrackInfo: "编辑歌曲信息",
        .trackTitle: "歌名",
        .noPlayHistory: "暂无播放历史",

        // Menu items
        .menuView: "视图",
        .menuMiniPlayer: "迷你播放器",
        .menuPlayback: "播放",
        .menuPlayPause: "播放/暂停",
        .menuPrevious: "上一首",
        .menuNext: "下一首",
        .menuRewind5s: "快退 5 秒",
        .menuForward5s: "快进 5 秒",
        .menuVolumeUp: "音量增加",
        .menuVolumeDown: "音量减少",
        .menuSpeedUp: "播放速度增加",
        .menuSpeedDown: "播放速度减少",
        .menuResetSpeed: "重置播放速度",
        .menuFavorite: "收藏当前歌曲",
        .menuKeyboardShortcuts: "快捷键说明",
        .menuCheckUpdates: "检查更新",
        .menuOK: "确定",
        .menuClose: "关闭",
        .menuExit: "退出",
        .favoriteTooltip: "收藏",
        .playbackSpeedTooltip: "播放速度",
        .historyLabel: "历史",
        .builtIn: "内置",
        .custom: "自定义",

        // Keyboard shortcuts dialog
        .shortcutsTitle: "快捷键说明",
        .shortcutsFileOps: "文件操作",
        .shortcutsOpenAudio: "打开音频文件",
        .shortcutsPlaybackControl: "播放控制",
        .shortcutsVolumeControl: "音量控制",
        .shortcutsSpeed: "播放速度",
        .shortcutsOther: "其他",
        .menuLicense: "授权管理...",
        .licenseStatus: "状态",
        .updateMessage: "当前版本: 1.0.0\n您正在使用最新版本。",

        // Additional UI strings
        .days: "天",
        .licenseKeyLabel: "授权码:",
        .perMonth: "/月",
        .perYear: "/年",
        .devicesSave: "2 台设备 · 省 ¥149",
        .activationFailedDefault: "激活失败，请检查授权码或网络连接",
        .qrCodeContact: "微信: AIPMAndy",
        .leaveEmptyForBuiltIn: "留空使用内置 Key",
        .apiKeySaved: "API Key 已保存",
        .noAvailableKey: "❌ 无可用 Key",
        .invalidURL: "❌ URL 无效",
        .connectionFailed: "❌ 连接失败: %@",
        .invalidResponse: "❌ 无效响应",
        .keyAvailable: "✅ %@ Key 可用！",
        .errorCode: "❌ 错误码: %d",
        .stylePlaceholder: "流行, 电子, 爵士",

        // Generation stages
        .stageUnderstanding: "🎯 理解您的创意...",
        .stageMelody: "🎹 编织旋律线条...",
        .stageHarmony: "🎼 构建和声层次...",
        .stageRhythm: "🥁 打磨节奏律动...",
        .stageMixing: "✨ 精心混音处理...",
        .today: "今天",
        .yesterday: "昨天",
        .generatingStatus: "生成中...",

        // Branding
        .appBranding: "ChiefMusic · AI酋长Andy出品",

        // Network errors
        .errorTimeout: "请求超时，请检查网络连接",
        .errorNoConnection: "无网络连接",
        .errorCannotReach: "无法连接到服务器",
        .errorConnectionLost: "网络连接中断",
        .errorBadRequest: "请求参数错误 (HTTP 400)",
        .errorUnauthorized: "API Key 无效或已过期 (HTTP 401)",
        .errorForbidden: "无权限访问 (HTTP 403)",
        .errorTooManyRequests: "请求过于频繁，请稍后再试 (HTTP 429)",
        .errorServer: "服务器错误 (HTTP %d)，请稍后重试",
    ]
    
    static let en: [LangKey: String] = [
        .play: "Play",
        .create: "Create",
        .share: "Share",
        .library: "Library",
        .noTrack: "No Track",
        .importAudio: "Import Audio",
        .importLyrics: "Import Lyrics",
        .synced: "Synced",
        .noLyrics: "No lyrics loaded",
        .importLrcHint: "Import a .lrc file to sync lyrics",
        .artist: "Unknown Artist",
        .playlist: "Playlist",
        .playlistEmpty: "Drop audio files or tap +",
        .playlistDragHint: "Drag audio files to add to playlist",
        .playAll: "Play All",
        .clearPlaylist: "Clear Playlist",
        .addedToPlaylist: "Added to playlist",
        .playlistCleared: "Playlist cleared",
        .alreadyInPlaylist: "Already in playlist",
        .clearPlaylistTitle: "Confirm Clear Playlist",
        .clearPlaylistMessage: "This will clear %d tracks from the playlist. This action cannot be undone.",
        .lyrics: "Lyrics",
        .importLyricsHint: "⌘L Import Lyrics",
        .lrcFormats: ".lrc / .md / .txt",
        .dragDropHint: "Drop to add to playlist",
        .releaseToImport: "Release to add",
        .createMusic: "Create Music",
        .describeHint: "Describe what you want to hear",
        .styleLabel: "Style",
        .durationLabel: "Duration",
        .generating: "Generating...",
        .generateMusic: "Generate Music",
        .generated: "Generated",
        .aiGenerated: "AI Generated",
        .apiKeyLabel: "ACE-Step API Key",
        .apiSettings: "API Settings",
        .dismiss: "Dismiss",
        .generatedAdded: "Generated, added to playlist",
        .cardStyle: "Card Style",
        .export: "Export",
        .styleMinimalist: "Minimalist",
        .styleGradient: "Gradient",
        .styleDark: "Dark",
        .styleVinyl: "Vinyl",
        .shareCard: "Share Card",
        .shareHint: "Create a shareable music card",
        .cardSaved: "Card saved",
        .cardSaveFailed: "Save failed",
        .libraryTitle: "Library",
        .libraryEmpty: "Library is empty",
        .libraryImportHint: "Tap import to add music",
        .importedToLibrary: "Imported to library",
        .deleteConfirm: "Confirm delete?",
        .deleted: "Deleted",
        .sortBy: "Sort",
        .sortNewest: "Newest",
        .sortOldest: "Oldest",
        .sortAZ: "A→Z",
        .sortZA: "Z→A",
        .settings: "Settings",
        .language: "Language",
        .chinese: "中文",
        .english: "English",
        .apiConfig: "API Configuration",
        .about: "About",
        .version: "Version",
        .theme: "Theme",
        .themeGlass: "Glass",
        .themeClassic: "Classic",
        .apiSave: "Save",
        .apiSaved: "API Key saved",
        .sequential: "Sequential",
        .singleLoop: "Single Loop",
        .shuffle: "Shuffle",
        .listLoop: "List Loop",
        .brandName: "Chief",
        .brandSubtitle: "by Andy",
        .loadFailed: "Load failed",
        .shortcutSpace: "Space",
        .shortcutArrows: "← →",
        .shortcutPlayPause: "Play/Pause",
        .shortcutSeek: "Seek ±5 seconds",
        .shortcutImport: "Import audio",
        .pause: "Pause",
        .previous: "Previous",
        .next: "Next",
        .generationCompleteAndPlaying: "✨ Complete! Now playing your creation",
        .addedToLibraryAndPlaylist: "Added to library and playlist",

        // License & Activation
        .activateTitle: "Activate ChiefMusic",
        .trialRemaining: "Trial remaining",
        .trialExpired: "Trial expired",
        .activated: "Activated",
        .activatedOffline: "Activated (Offline mode - ",
        .offlineDays: " days remaining)",
        .deviceCode: "Device Code",
        .deviceCodeHint: "Provide this device code to get your license key",
        .deviceCodeCopied: "✓ Copied to clipboard",
        .scanQRCode: "Scan to send to support",
        .enterLicenseKey: "Enter License Key",
        .licenseKeyPlaceholder: "CHIEF-XXXXX-XXXXX-XXXXX-XXXXX",
        .activateButton: "Activate",
        .activating: "Activating, please wait...",
        .licenseType: "License Type:",
        .activationDate: "Activation Date:",
        .expiresAt: "Valid until",
        .licenseManagement: "License Management",
        .manage: "Manage",
        .removeLicense: "Remove License",

        // Purchase
        .monthlyPlan: "Monthly",
        .yearlyPlan: "Yearly",
        .recommended: "Recommended",
        .devices: "devices",
        .save: "save",
        .contactPurchase: "Contact for Purchase",
        .contactEmail: "Email",
        .contactDiscord: "Discord",
        .wechat: "WeChat",
        .priceMonthly: "4.99",
        .priceYearly: "29.99",
        .priceMonthlyCurrency: "$",
        .priceYearlyCurrency: "$",
        .featureUnlimited: "AI Music Generation (Unlimited)",
        .featureLyrics: "Intelligent Lyrics Creation",
        .featureStyles: "20+ Curated Style Presets",
        .featureImport: "Import Local Music",
        .featureSyncLyrics: "Synced Lyrics Display",
        .featureMultiDevice: "Multi-Device Sync",
        .featurePrioritySupport: "Priority Support",
        .whyActivate: "Activate to Enjoy",

        // Activation Errors
        .activationSuccess: "Activation Successful!",
        .activationSuccessExpiry: "Valid until",
        .errorLicenseNotExist: "License key does not exist, please check your input",
        .errorLicenseDisabled: "This license key has been disabled, please contact support",
        .errorDeviceLimit: "This license key has reached the device limit (2 devices), please contact support",
        .errorLicenseExpired: "License key has expired, please renew",
        .errorNetworkTimeout: "Network timeout, retrying",
        .errorNoInternet: "No internet connection, please check your network settings",
        .errorCannotConnect: "Cannot connect to server, please check network or try again later",
        .errorActivationFailed: "Activation failed after 3 retries. Please check your network or contact support",
        .errorRetrying: "Network error, retrying...",
        .errorInvalidFormat: "Invalid license key format",

        // Trial
        .continueTrialButton: "Continue Trial (",
        .trialExpiredTitle: "Trial Expired",
        .trialExpiredMessage: "Thank you for trying ChiefMusic\nPlease enter a license key to continue",
        .enterLicenseButton: "Enter License Key",
        .exitApp: "Exit App",

        // License types
        .licenseTypeTrial: "Trial",
        .licenseTypeMonthly: "Monthly",
        .licenseTypeYearly: "Yearly",
        .activationFailedWithError: "Activation failed: %@",
        .networkErrorRetrying: "Network error (code %d), retrying...",
        .purchaseContactInfo: "Email: supera6@qq.com",
        .purchaseDetailsInfo: """
Email: supera6@qq.com
Discord: discord.gg/chiefmusic

Monthly: $4.99/month (2 devices)
Yearly: $29.99/year (2 devices, save $25)

Email has been copied to clipboard
""",
        .contactCopied: "supera6@qq.com",

        // API Settings
        .builtInKeyAvailable: "✅ Built-in key available, no configuration needed",
        .advancedUserConfig: "Advanced users can configure custom key (optional)",
        .testBuiltInKey: "Test Built-in Key",
        .testCustomKey: "Test Custom Key",
        .keyTesting: "Testing...",
        .keyTestSuccess: "✅ Key is valid!",
        .keyTestFailed: "❌ Connection failed",
        .keyInvalid: "❌ Key is invalid or expired",
        .keySaved: "Saved",
        .importing: "Importing...",

        // Library detailed
        .tracksCount: " tracks",
        .searchPlaceholder: "Search tracks...",
        .noTracksFound: "Your music library is empty",
        .noMatchingTracks: "No matching tracks found",
        .startCreatingOrImport: "Create with AI or import your collection",
        .createNow: "Create Now",
        .importMusic: "Import Music",
        .trackHeader: "Track",
        .durationHeader: "Duration",
        .deleteAlertTitle: "Confirm Delete",
        .deleteAlertMessage: "Are you sure you want to remove \"%@\" from library?",
        .deleteButton: "Delete",
        .cancel: "Cancel",

        // Generator detailed
        .generatorSubtitle: "Choose a style, describe your creativity, start creating",
        .promptPlaceholder: "A chill lo-fi beat for late night coding...",
        .promptRequired: "Please enter a description",
        .generatingTitle: "Creating for you...",
        .estimatedTime: "Est. remaining",
        .cancelGeneration: "Cancel",
        .seconds: "s",
        .expectedDuration: "Expected 30-90 seconds",
        .expectedDurationHint: "Actual time depends on server load",
        .generationStats: "%d tracks created",
        .categoryRelaxation: "Relaxation",
        .categoryFocus: "Focus",
        .categorySocial: "Social",
        .categoryLuxury: "Luxury",
        .categoryCultural: "Cultural",

        // Generator extra
        .generatedHistory: "Generated History",
        .clearHistory: "Clear",
        .retry: "Retry",
        .generationFailed: "Generation Failed",

        // Player detailed
        .playHistory: "History",
        .welcomeTitle: "Welcome to ChiefMusic",
        .welcomeSubtitle: "AI Chief creates your unique music",
        .welcomeValueProp: "Generate in 30s, infinite possibilities",
        .defaultArtist: "Chief Andy AI",

        // Style Presets
        .styleDeepNightJazz: "Late Night Jazz",
        .styleMeditationZen: "Meditation Zen",
        .styleSpaHealing: "Spa Healing",
        .styleRainyNightCafe: "Rainy Night Cafe",
        .styleDeepWork: "Deep Work",
        .styleCreativeInspiration: "Creative Inspiration",
        .styleReadingTime: "Reading Time",
        .styleCodingRhythm: "Coding Rhythm",
        .stylePartyElectronic: "Party Electronic",
        .styleCocktailParty: "Cocktail Party",
        .styleAfternoonTea: "Afternoon Tea",
        .styleYachtParty: "Yacht Party",
        .styleRoyalClassical: "Royal Classical",
        .styleOperaNight: "Opera Night",
        .stylePianoSolo: "Piano Solo",
        .styleBigBandJazz: "Big Band Jazz",
        .styleChineseTraditional: "Chinese Traditional",
        .styleJapaneseWafuu: "Japanese Wafuu",
        .styleIndianSpiritual: "Indian Spiritual",
        .styleLatinPassion: "Latin Passion",
        .styleCinematic: "Cinematic",
        .styleSynthwave: "Synthwave",

        // Toast Messages
        .toastGenerationCancelled: "Generation cancelled",
        .toastGeneratingLyrics: "Generating lyrics...",
        .toastComposingMusic: "Composing music...",
        .toastLyricsGenerationFailed: "Lyrics generation failed",
        .toastSaveFailed: "Save failed",
        .toastLoadingLyrics: "Loading lyrics...",
        .toastLyricsFileNotExist: "Lyrics file does not exist",
        .toastPlaybackSpeed: "Playback Speed",
        .toastRemovedFromFavorites: "Removed from favorites",
        .toastAddedToFavorites: "Added to favorites",
        .toastEQMode: "EQ Mode",
        .toastLyricsAutoLoaded: "Lyrics auto-loaded",
        .toastLyricsAutoLoadedCount: "Auto-loaded %d lyrics",
        .toastCardSavedTo: "Card saved to %@",
        .toastSharePanelOpened: "Share panel opened",

        // Enums - PlaybackMode
        .modeSequential: "Sequential",
        .modeSingleLoop: "Single Loop",
        .modeShuffle: "Shuffle",
        .modeListLoop: "List Loop",

        // Enums - EQPreset
        .eqFlat: "Flat",
        .eqBass: "Bass Boost",
        .eqVocal: "Vocal Clarity",
        .eqClassical: "Classical",
        .eqElectronic: "Electronic",

        // Additional UI text
        .notPlaying: "Not Playing",
        .orImportLocalMusic: "or import local music",
        .titleUpdated: "Title updated",
        .artistUpdated: "Artist updated",
        .clickToImportLyrics: "Click to import LRC or Markdown lyrics",
        .enterSongTitle: "Enter song title",
        .enterArtistName: "Enter artist name",
        .navigatingToGenerator: "Opening generator...",
        .editTrackInfo: "Edit Track Info",
        .trackTitle: "Title",
        .noPlayHistory: "No play history",

        // Menu items
        .menuView: "View",
        .menuMiniPlayer: "Mini Player",
        .menuPlayback: "Playback",
        .menuPlayPause: "Play/Pause",
        .menuPrevious: "Previous",
        .menuNext: "Next",
        .menuRewind5s: "Rewind 5s",
        .menuForward5s: "Forward 5s",
        .menuVolumeUp: "Volume Up",
        .menuVolumeDown: "Volume Down",
        .menuSpeedUp: "Speed Up",
        .menuSpeedDown: "Speed Down",
        .menuResetSpeed: "Reset Speed",
        .menuFavorite: "Favorite Current Track",
        .menuKeyboardShortcuts: "Keyboard Shortcuts",
        .menuCheckUpdates: "Check for Updates",
        .menuOK: "OK",
        .menuClose: "Close",
        .menuExit: "Exit",
        .favoriteTooltip: "Favorite",
        .playbackSpeedTooltip: "Playback Speed",
        .historyLabel: "History",
        .builtIn: "Built-in",
        .custom: "Custom",

        // Keyboard shortcuts dialog
        .shortcutsTitle: "Keyboard Shortcuts",
        .shortcutsFileOps: "File Operations",
        .shortcutsOpenAudio: "Open Audio File",
        .shortcutsPlaybackControl: "Playback Control",
        .shortcutsVolumeControl: "Volume Control",
        .shortcutsSpeed: "Playback Speed",
        .shortcutsOther: "Other",
        .menuLicense: "License Management...",
        .licenseStatus: "Status",
        .updateMessage: "Current Version: 1.0.0\nYou are using the latest version.",

        // Additional UI strings
        .days: "days",
        .licenseKeyLabel: "License Key:",
        .perMonth: "/month",
        .perYear: "/year",
        .devicesSave: "2 devices · save $25",
        .activationFailedDefault: "Activation failed, please check your license key or network",
        .qrCodeContact: "Email: supera6@qq.com",
        .leaveEmptyForBuiltIn: "Leave empty to use built-in key",
        .apiKeySaved: "API Key saved",
        .noAvailableKey: "❌ No available key",
        .invalidURL: "❌ Invalid URL",
        .connectionFailed: "❌ Connection failed: %@",
        .invalidResponse: "❌ Invalid response",
        .keyAvailable: "✅ %@ Key available!",
        .errorCode: "❌ Error code: %d",
        .stylePlaceholder: "pop, electronic, jazz",

        // Generation stages
        .stageUnderstanding: "🎯 Understanding your vision...",
        .stageMelody: "🎹 Weaving melody...",
        .stageHarmony: "🎼 Building harmony layers...",
        .stageRhythm: "🥁 Crafting rhythm...",
        .stageMixing: "✨ Fine-tuning mix...",
        .today: "Today",
        .yesterday: "Yesterday",
        .generatingStatus: "Generating...",

        // Branding
        .appBranding: "ChiefMusic · by Chief Andy AI",

        // Network errors
        .errorTimeout: "Request timeout, please check your network",
        .errorNoConnection: "No internet connection",
        .errorCannotReach: "Cannot connect to server",
        .errorConnectionLost: "Network connection lost",
        .errorBadRequest: "Bad request (HTTP 400)",
        .errorUnauthorized: "API Key invalid or expired (HTTP 401)",
        .errorForbidden: "Access forbidden (HTTP 403)",
        .errorTooManyRequests: "Too many requests, please try again later (HTTP 429)",
        .errorServer: "Server error (HTTP %d), please try again later",
    ]
}
