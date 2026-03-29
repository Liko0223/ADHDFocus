<p align="center">
  <img src="ADHDFocus/ADHDICON.png" width="128" height="128" alt="ADHD Focus Icon">
</p>

<h1 align="center">ADHD Focus</h1>

<p align="center">
  <strong>A macOS focus assistant designed for ADHD users</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

<p align="center">
  <a href="#-english">English</a> · <a href="#-中文">中文</a>
</p>

---

## 🇺🇸 English

### Features

**🐱 Pixel Cat Companion**
- A cute pixel orange tabby cat accompanies your work
- Unique pixel art scenes per focus mode (art studio, library, café, writing desk)
- Cat reacts to your state (working, resting, blocked)

**📱 Notch Interaction**
- All controls live in the MacBook notch area
- Click the notch to expand the control panel
- Collapsed view shows cat + Pomodoro countdown

**🚫 Smart App Blocking**
- Window-level overlay blocks distracting apps (without killing processes)
- One-click whitelist from the overlay
- 5-minute temporary allow

**🌐 Chrome URL Blocking**
- Chrome extension blocks distracting websites
- Custom URL black/white lists per mode
- Block page suggests alternative sites

**⏱ Pomodoro Timer**
- Customizable work/break/long-break durations
- Pause/resume by clicking the notch countdown
- Auto-unblock apps during breaks

**📊 Focus Statistics**
- Daily focus time, completed Pomodoros
- Block event details with app icons
- Focus streak tracking

**🤖 Auto-Trigger**
- Detects prolonged use of specific apps and suggests entering focus mode
- Configurable trigger delay (10s/30s/1min/5min)

**🎯 4 Preset Modes**
- Deep Design — Figma/Sketch/PS + design websites
- Research — Browser + reference sites
- Communication — WeChat/Lark/Slack
- Writing — Notion/Notes

### Installation

1. Clone the repository
```bash
git clone https://github.com/Liko0223/ADHDFocus.git
```

2. Install xcodegen (if not installed)
```bash
brew install xcodegen
```

3. Generate Xcode project and open
```bash
cd ADHDFocus/ADHDFocus
xcodegen generate
open ADHDFocus.xcodeproj
```

4. Press `Cmd+R` to run

### Chrome Extension Setup

1. Open Chrome → `chrome://extensions`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `ADHDFocus/ChromeExtension` folder

### System Requirements

- macOS 14.0+
- MacBook with notch (MacBook Pro/Air M-series)
- Accessibility permission (for app blocking)

---

## 🇨🇳 中文

### 功能特性

**🐱 像素猫猫伴侣**
- 可爱的像素橘猫陪你一起工作
- 不同专注模式有独特的像素场景（画室、图书馆、咖啡厅、书桌）
- 猫猫会根据你的状态做出反应（工作、休息、被拦截）

**📱 刘海屏交互**
- 所有操作都在 MacBook 刘海区域完成
- 点击刘海展开控制面板，选择模式、查看状态
- 收起时显示猫猫 + 番茄钟倒计时

**🚫 智能应用拦截**
- 窗口级遮罩拦截分心应用（不杀进程）
- 一键加入白名单
- 允许 5 分钟临时放行

**🌐 Chrome URL 拦截**
- 配套 Chrome 扩展拦截分心网站
- 自定义 URL 黑/白名单
- 拦截页面推荐替代网站

**⏱ 番茄钟**
- 可自定义工作/休息/长休息时长
- 暂停/继续（点击刘海倒计时）
- 休息时自动解除应用拦截

**📊 专注统计**
- 今日专注时长、番茄钟完成数
- 拦截记录详情（应用图标+时间）
- 连续专注天数

**🤖 自动化触发**
- 检测到持续使用某应用时自动建议进入专注模式
- 可配置触发延迟（10秒/30秒/1分钟/5分钟）

**🎯 4 个预设模式**
- 深度设计 — Figma/Sketch/PS + 设计网站
- 调研灵感 — 浏览器 + 参考网站
- 沟通协作 — 微信/飞书/Slack
- 写作整理 — Notion/备忘录

### 安装

1. 克隆仓库
```bash
git clone https://github.com/Liko0223/ADHDFocus.git
```

2. 安装 xcodegen（如未安装）
```bash
brew install xcodegen
```

3. 生成 Xcode 项目并打开
```bash
cd ADHDFocus/ADHDFocus
xcodegen generate
open ADHDFocus.xcodeproj
```

4. `Cmd+R` 运行

### Chrome 扩展安装

1. 打开 Chrome → `chrome://extensions`
2. 开启「开发者模式」
3. 点击「加载已解压的扩展」
4. 选择 `ADHDFocus/ChromeExtension` 文件夹

### 系统要求

- macOS 14.0+
- 有刘海的 MacBook（MacBook Pro/Air M 系列）
- 辅助功能权限（用于应用拦截）

---

## Tech Stack

- **UI**: SwiftUI + AppKit (NSPanel, NSWindow)
- **Data**: SwiftData
- **Notch**: NSScreen.safeAreaInsets + custom NSPanel
- **Animation**: Canvas pixel art + TimelineView
- **Chrome**: Manifest V3 Extension + local HTTP server
- **Build**: xcodegen

## License

MIT
