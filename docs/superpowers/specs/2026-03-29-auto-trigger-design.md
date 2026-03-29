# 自动化触发专注模式 — 设计文档

## 概述

当用户未开启专注模式时，检测到持续使用某个应用超过设定时间，通过刘海面板"半展开"状态提示用户是否进入对应的专注模式。一键点击即可开启，降低 ADHD 用户启动专注的决策成本。

## 核心流程

1. 用户未开启任何专注模式
2. 切换到某个应用（如 Figma）并持续使用超过阈值时间（默认 60 秒，可配置）
3. 系统匹配该应用属于哪个模式（优先查 triggerApps，否则查白名单反推）
4. 刘海面板进入"半展开"状态 — 下探约 40px
5. 显示猫猫气泡 + 一键开启按钮 + 忽略按钮
6. 用户点击模式按钮 → 直接进入该模式，面板收回
7. 用户点击忽略 → 面板收回，该应用本次不再提醒（切走再切回来才会重新计时）
8. 5 秒无操作 → 自动收回，同样不再重复提醒

## 不触发的条件

- 已在任何专注模式中 → 不触发
- 应用不在任何模式的白名单/触发列表中 → 不触发
- 该应用已被忽略过（本次会话内）→ 不触发
- 系统应用（Finder、系统设置等）→ 不触发

## 数据模型变更

### FocusMode 新增字段

```swift
var triggerApps: [String]   // 触发应用 Bundle ID 列表（空 = 用 allowedApps 推断）
var triggerDelay: Int        // 触发等待秒数，默认 60
```

## 新增服务：AutoTriggerService

```swift
final class AutoTriggerService {
    // 监听前台应用切换
    // 记录当前前台应用的持续使用时间
    // 切换应用时重置计时
    // 超过阈值时匹配模式并通知 NotchManager

    private var currentApp: String?          // 当前前台应用 bundleID
    private var appStartTime: Date?          // 开始使用时间
    private var checkTimer: Timer?           // 定时检查（每秒）
    private var ignoredApps: Set<String>     // 本次已忽略的应用
    private var activationObserver: NSObjectProtocol?

    func startWatching()   // 开始监听（应用启动时调用）
    func stopWatching()    // 停止监听

    // 匹配逻辑：
    // 1. 遍历所有 FocusMode，检查 triggerApps 是否包含该 bundleID
    // 2. 如果 triggerApps 为空，检查 allowedApps 是否包含
    // 3. 返回第一个匹配的模式（按 sortOrder）
    func matchMode(for bundleID: String) -> FocusMode?
}
```

## NotchManager 半展开状态

### 新增状态

```swift
var isSuggesting: Bool = false
var suggestedMode: FocusMode?
var suggestedAppName: String?
```

### 半展开 UI

高度 = notchHeight + 40px

布局：
```
┌──────────────────────────────────────┐
│  🐱  "在用 Figma~ 要专注吗？"         │  ← 原刘海栏（猫猫 + 气泡替换 idle 文字）
│  [🎨 深度设计 ▶️]          [✕ 忽略]   │  ← 半展开按钮行
└──────────────────────────────────────┘
```

- 左侧：模式图标 + 名称 + 箭头，胶囊按钮，点击直接 activateMode
- 右侧：忽略按钮，点击收回并加入 ignoredApps
- 弹出/收回用 spring 动画

### 与现有状态的关系

- `isSuggesting` 是独立于 `isExpanded` 的状态
- 半展开时点击刘海区域不触发完全展开
- 半展开时如果用户手动点刘海展开，半展开自动关闭
- 已在专注模式时 `isSuggesting` 始终为 false

## 模式编辑器变更

在 ModeEditorView 的"环境与策略"区域下方新增"自动化"配置：

```
GroupBox("自动化") {
    // 触发应用选择（复用 AppPickerView）
    // 触发延迟时间选择：10秒 / 30秒 / 1分钟 / 5分钟
}
```

触发延迟用 Picker，选项：
- 10 秒
- 30 秒
- 1 分钟（默认）
- 5 分钟

## 生命周期集成

```
AppDelegate.setupEngine()
  → autoTriggerService = AutoTriggerService(engine, modelContainer, notchManager)
  → autoTriggerService.startWatching()

engine.onModeActivated
  → autoTriggerService 暂停监听（已在专注模式）

engine.onModeDeactivated
  → autoTriggerService 恢复监听
  → 清空 ignoredApps
```

## 猫猫气泡文案

根据匹配的模式随机选择：
- "在用 {appName} 呢~ 要进入{modeName}吗？"
- "看你在 {appName}，开启{modeName}？"
- "{appName} 打开啦~ 要专注吗？"
