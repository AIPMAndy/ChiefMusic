# ChiefMusic 国际化审计报告 v3.0

## 审计目标
确保切换语言后，**所有用户可见界面**都完整切换，不留任何中文硬编码。

## 发现的问题（按优先级）

### 🔴 高优先级 - 用户直接可见

#### 1. ChiefMusicApp.swift - 菜单栏
- [ ] Line 72: "视图" → View  
- [ ] Line 73: "迷你播放器" → Mini Player
- [ ] Line 80: "播放" → Playback
- [ ] Line 86: "上一首" → Previous
- [ ] Line 91: "下一首" → Next
- [ ] Line 110: "音量增加" → Volume Up
- [ ] Line 115: "音量减少" → Volume Down
- [ ] Line 122: "播放速度增加" → Speed Up
- [ ] Line 127: "播放速度减少" → Speed Down
- [ ] Line 132: "重置播放速度" → Reset Speed
- [ ] Line 139: "收藏当前歌曲" → Favorite
- [ ] Line 155: "快捷键说明" → Keyboard Shortcuts
- [ ] Line 263: alert.messageText = "快捷键说明"
- [ ] Line 264-289: 快捷键说明的完整内容
- [ ] Line 291: "确定" → OK
- [ ] Line 297: "检查更新" → Check for Updates

#### 2. PlayerView.swift - Tooltip和按钮
- [ ] Line 331: .help("收藏") → Favorite
- [ ] Line 390: .help("播放速度") → Playback Speed
- [ ] Line 415: panelToggle("历史", ...) → History

#### 3. ContentView.swift - 设置界面
- [ ] Line 344: Text("中文").tag("zh"); Text("English").tag("en")
- [ ] Line 529-530: 内置/自定义主题显示

#### 4. LicenseView.swift - 按钮文本
- [ ] Line 496-497: "关闭"/"退出" → Close/Exit
- [ ] Line 579: "确定" → OK

#### 5. GeneratorView.swift
- [ ] Line 599: Button("保存") → Save

### 🟡 中优先级 - 枚举和错误消息

#### 6. Theme.swift - 主题名称
```swift
enum AppTheme: String, CaseIterable {
    case glass = "流光玻璃"  // → 需要改成 displayName()
    case classic = "经典"    // → 需要改成 displayName()
}
```

#### 7. 错误消息（LicenseService.swift、AIMusicService.swift）
- 大量错误提示需要国际化
- "激活失败"、"网络错误"、"API错误"等

### ⚪ 低优先级 - 日志和注释

#### 8. NSLog和print - 仅开发者可见
- LicenseService.swift 中的大量 NSLog
- 这些是调试日志，不影响用户体验

#### 9. 代码注释
- 所有中文注释（如 `// 新增`、`// 配置`等）
- 不影响用户，可保留

## 修复策略

### Phase 1: 菜单和按钮（30分钟）
1. 在 Localization.swift 添加所有菜单相关的 LangKey
2. 修复 ChiefMusicApp.swift 菜单栏
3. 修复 PlayerView、ContentView、LicenseView 的按钮

### Phase 2: 枚举国际化（20分钟）
4. Theme 枚举添加 displayName() 方法
5. 更新所有使用 rawValue 的地方

### Phase 3: 错误消息（20分钟）  
6. LicenseService 错误消息国际化
7. AIMusicService 错误消息国际化

### Phase 4: 验证（10分钟）
8. 切换语言测试所有界面
9. 确认无遗漏

## 预计新增 LangKey 数量
约 35-40 个新的翻译键

## 当前状态
- ✅ 已完成：LibraryView, GeneratorView, PlayerView 的主要UI
- ✅ 已完成：Toast消息、播放模式、EQ模式枚举
- ⏳ 进行中：菜单栏和系统级UI
- ⏳ 待处理：枚举和错误消息
