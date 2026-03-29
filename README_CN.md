<p align="center">
  <img src="ADHDFocus/ADHDICON.png" width="128" height="128" alt="ADHD Focus Icon">
</p>

<h1 align="center">ADHD Focus</h1>

<p align="center">
  <strong>专为 ADHD 打造的 macOS 专注助手</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>中文</strong>
</p>

---

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

**🎉 庆祝效果**
- 完成番茄钟工作周期时屏幕四周亮起渐变光晕

**🎯 4 个预设模式**
- 深度设计 — Figma/Sketch/PS + 设计网站
- 调研灵感 — 浏览器 + 参考网站
- 沟通协作 — 微信/飞书/Slack
- 写作整理 — Notion/备忘录

### 安装

**下载安装（推荐）**

1. 从 [GitHub Releases](https://github.com/Liko0223/ADHDFocus/releases) 下载 `ADHDFocus.dmg`
2. 打开 DMG，将 `ADHDFocus` 拖入 `Applications` 文件夹
3. 首次启动：**右键 → 打开**（仅首次需要，绕过 Gatekeeper）
4. 在系统设置 → 隐私与安全性中授权辅助功能权限

**从源码编译**

```bash
git clone https://github.com/Liko0223/ADHDFocus.git
cd ADHDFocus/ADHDFocus
brew install xcodegen  # 如未安装
xcodegen generate
open ADHDFocus.xcodeproj
# Cmd+R 运行
```

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

## 技术栈

- **UI**: SwiftUI + AppKit (NSPanel, NSWindow)
- **数据**: SwiftData
- **刘海**: NSScreen.safeAreaInsets + 自定义 NSPanel
- **动画**: Canvas 像素画 + TimelineView
- **Chrome**: Manifest V3 扩展 + 本地 HTTP 服务器
- **构建**: xcodegen

## 许可证

MIT
