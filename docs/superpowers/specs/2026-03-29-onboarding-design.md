# Onboarding 引导流 — 设计文档

## 概述

首次启动应用时，通过独立窗口引导用户完成关键设置（权限授权、模式选择），由猫猫伴侣角色带领，降低 ADHD 用户的上手门槛。完成后关闭窗口，刘海面板成为主交互入口。

## 引导步骤（4 步）

### Step 1 — 欢迎

- 独立窗口，居中显示
- 猫猫像素形象（复用 PixelCompanionView，放大到 80x80）
- 气泡文字："嗨~ 我是你的专注伙伴！"
- 应用名称 "ADHD Focus" + 副标题 "为设计师打造的专注助手"
- 底部按钮："开始设置 →"

### Step 2 — 辅助功能权限

- 猫猫气泡："帮我开一下权限吧~ 这样我才能帮你挡住分心的应用哦"
- 权限状态指示器（绿色勾 / 橙色感叹号）
- 实时检测 `AXIsProcessTrusted()` 状态（每秒轮询）
- "去授权" 按钮 → 打开系统设置辅助功能页面
- 底部 "下一步" 按钮（未授权也可点击，显示灰色提示"跳过后应用拦截功能不可用"）

### Step 3 — 通知权限

- 猫猫气泡："允许我发通知，番茄钟结束时提醒你休息~"
- 触发 `UNUserNotificationCenter.requestAuthorization`
- 权限状态指示器
- 底部 "下一步" 按钮

### Step 4 — 选择模式 + 浏览器扩展

- 猫猫气泡："选一个你常用的模式，马上开始第一次专注！"
- 4 个预设模式卡片（图标 + 名称 + 简短描述），点击选中高亮
- 折叠区域 "安装浏览器扩展（可选）"：
  - 展开后显示 Chrome 安装说明
  - "在 Finder 中打开扩展文件夹" 按钮
  - 未来可加 Safari 等其他浏览器
- 底部 "开始专注！" 按钮：
  - 进入选中的模式（调用 engine.activate）
  - 关闭 Onboarding 窗口
  - 刘海面板自动显示专注状态

## 猫猫风格

每一步都有猫猫形象 + 对话气泡，语气温暖、可爱、不说教：
- Step 1: "嗨~ 我是你的专注伙伴！"
- Step 2: "帮我开一下权限吧~ 这样我才能帮你挡住分心的应用哦"
- Step 3: "允许我发通知，番茄钟结束时提醒你休息~"
- Step 4: "选一个你常用的模式，马上开始第一次专注！"

## 技术实现

### 文件结构

```
ADHDFocus/ADHDFocus/Views/Onboarding/
├── OnboardingView.swift      — 主视图，管理步骤切换
├── OnboardingStepView.swift  — 通用步骤布局（猫猫 + 气泡 + 内容 + 按钮）
└── OnboardingPermissionChecker.swift — 权限状态轮询
```

### 窗口创建

通过 `AppDelegate` 创建 `NSWindow`（和主窗口同样方式）：

```swift
func showOnboardingIfNeeded() {
    guard !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") else { return }
    // 创建 NSWindow，设置 contentView 为 OnboardingView
}
```

### 状态管理

- `@State currentStep: Int` — 当前步骤（0-3）
- `UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")` — 是否已完成
- 完成后写入 `true`，后续启动不再弹出

### 窗口样式

- 大小约 500x580
- 居中显示
- 无最小化按钮，有关闭按钮（关闭 = 跳过，下次启动再弹）
- 圆角，和系统风格一致

## 不做的事

- 不做刘海操作教学
- 不做动画/轮播过渡
- 不做"跳过全部"按钮
- 不做 onboarding 进度条（只有 4 步，不需要）
