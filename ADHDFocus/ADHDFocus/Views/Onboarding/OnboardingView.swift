import SwiftUI
import SwiftData
import AppKit
import UserNotifications
import ApplicationServices

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var selectedModeIndex: Int? = nil
    @State private var accessibilityGranted = false
    @State private var accessibilityTimer: Timer?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var extensionSectionExpanded = false

    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]

    var engine: FocusEngine?
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: accessibilityStep
                case 2: notificationStep
                case 3: extensionStep
                case 4: modeSelectionStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Step indicator dots
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i == currentStep ? Color.accentColor : Color.primary.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 480, height: 580)
        .background(Color(NSColor.windowBackgroundColor))
        .onDisappear {
            accessibilityTimer?.invalidate()
            accessibilityTimer = nil
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            }

            Spacer().frame(height: 20)

            Text("ADHD Focus")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Spacer().frame(height: 6)

            Text("专为 ADHD 打造的专注助手")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer().frame(height: 12)

            Text("接下来帮你做几个简单的设置~")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)

            Spacer()

            primaryButton(title: "开始设置 →") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = 1
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
    }

    // MARK: - Step 2: Accessibility

    private var accessibilityStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            catWithBubble(message: "帮我开一下权限吧~ 这样我才能帮你挡住分心的应用")

            Spacer().frame(height: 24)

            // What this enables
            VStack(alignment: .leading, spacing: 10) {
                Label("拦截分心应用 — 工作时自动遮挡微信、微博等", systemImage: "app.badge.checkmark")
                Label("窗口级遮罩 — 不杀进程，温和地帮你回到工作", systemImage: "rectangle.on.rectangle")
                Label("智能提醒 — 用设计工具时建议开启专注", systemImage: "sparkles")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 24)

            permissionCard(
                title: "辅助功能权限",
                description: "用于监控并拦截分心应用",
                isGranted: accessibilityGranted,
                actionLabel: "去授权"
            ) {
                openAccessibilitySettings()
            }

            if !accessibilityGranted {
                Text("跳过后应用拦截功能不可用")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange.opacity(0.8))
                    .padding(.top, 8)
            }

            Spacer().frame(height: 32)

            primaryButton(title: "下一步") {
                accessibilityTimer?.invalidate()
                accessibilityTimer = nil
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = 2
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
        .onAppear {
            checkAccessibility()
            startAccessibilityPolling()
        }
        .onDisappear {
            accessibilityTimer?.invalidate()
            accessibilityTimer = nil
        }
    }

    // MARK: - Step 3: Notifications

    private var notificationStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            catWithBubble(message: "允许我发通知~ 番茄钟结束时提醒你休息")

            Spacer().frame(height: 24)

            VStack(alignment: .leading, spacing: 10) {
                Label("番茄钟提醒 — 工作结束提醒休息，休息结束回来工作", systemImage: "timer")
                Label("拦截通知 — 有应用被拦截时告诉你", systemImage: "hand.raised")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 24)

            permissionCard(
                title: "通知权限",
                description: "番茄钟结束时发送休息提醒",
                isGranted: notificationStatus == .authorized,
                actionLabel: "去授权"
            ) {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
            }

            Spacer().frame(height: 32)

            primaryButton(title: "下一步") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = 3
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
        .onAppear {
            requestNotificationPermission()
        }
    }

    // MARK: - Step 4: Browser Extension

    private var extensionStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            catWithBubble(message: "安装浏览器扩展可以帮你拦截分心的网站哦~")

            Spacer().frame(height: 24)

            VStack(alignment: .leading, spacing: 10) {
                Label("URL 拦截 — 专注时自动屏蔽分心网站", systemImage: "safari")
                Label("自定义黑名单 — 按模式设置不同的屏蔽规则", systemImage: "list.bullet.clipboard")
                Label("无缝集成 — 和应用拦截一起联动工作", systemImage: "link")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 20)

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chrome 安装说明：")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                    Text("1. 打开 Chrome → 更多工具 → 扩展程序\n2. 开启右上角「开发者模式」\n3. 点击「加载已解压的扩展程序」\n4. 选择右侧按钮打开的文件夹")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button("在 Finder 中打开") {
                    revealExtensionInFinder()
                }
                .controlSize(.regular)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                    )
            )

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                primaryButton(title: "下一步") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = 4
                    }
                }

                Button("跳过") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = 4
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
    }

    // MARK: - Step 5: Mode Selection

    private var modeSelectionStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            catWithBubble(message: "选一个模式，开始第一次专注！")

            Spacer().frame(height: 20)

            // Mode grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(modes.indices, id: \.self) { index in
                    let mode = modes[index]
                    modeCard(mode: mode, isSelected: selectedModeIndex == index) {
                        selectedModeIndex = index
                    }
                }
            }

            Spacer().frame(height: 20)

            // Notch hint with mini illustration
            HStack(spacing: 10) {
                // Mini notch illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 60, height: 36)

                    // Notch shape
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 4,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 0
                    )
                    .fill(Color.primary.opacity(0.7))
                    .frame(width: 24, height: 10)
                    .offset(y: -13)

                    // Cat dot
                    Circle()
                        .fill(.orange)
                        .frame(width: 4, height: 4)
                        .offset(x: -8, y: -13)
                }

                Text("完成后，在屏幕顶部刘海区域找到我~ 点击即可展开控制面板")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                    )
            )

            Spacer().frame(height: 20)

            VStack(spacing: 10) {
                primaryButton(
                    title: "开始专注！",
                    isEnabled: selectedModeIndex != nil
                ) {
                    completedOnboarding()
                }

                Button("跳过，稍后再选") {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    onComplete()
                }
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 24)
    }

    // MARK: - Shared Components

    private func catWithBubble(message: String) -> some View {
        VStack(spacing: 0) {
            TimelineView(.animation(minimumInterval: 1.0 / 12)) { timeline in
                PixelCompanionView(
                    state: .idle,
                    time: timeline.date.timeIntervalSinceReferenceDate
                )
                .frame(width: 64, height: 64)
            }

            Spacer().frame(height: 8)

            // Speech bubble
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                )
                .overlay(alignment: .top) {
                    // Bubble tail pointing up toward cat
                    Triangle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(width: 12, height: 7)
                        .offset(y: -7)
                }
        }
    }

    private func permissionCard(title: String, description: String, isGranted: Bool, actionLabel: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(isGranted ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(isGranted ? "已授权" : actionLabel) {
                action()
            }
            .controlSize(.regular)
            .disabled(isGranted)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private func modeCard(mode: FocusMode, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mode.icon)
                    .font(.system(size: 28))
                Text(mode.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(modeDescription(for: mode))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.07),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var extensionSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    extensionSectionExpanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: extensionSectionExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("安装浏览器扩展（可选）")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if extensionSectionExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Chrome 安装说明：\n1. 打开 Chrome → 更多工具 → 扩展程序\n2. 开启右上角「开发者模式」\n3. 点击「加载已解压的扩展程序」\n4. 选择下方文件夹中的 ChromeExtension 目录")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("在 Finder 中打开") {
                        revealExtensionInFinder()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.top, 10)
                .padding(.leading, 4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func primaryButton(title: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isEnabled ? Color.accentColor : Color.secondary.opacity(0.3))
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Logic

    private func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    private func startAccessibilityPolling() {
        accessibilityTimer?.invalidate()
        accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                checkAccessibility()
            }
        }
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                notificationStatus = granted ? .authorized : .denied
            }
        }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                notificationStatus = settings.authorizationStatus
            }
        }
    }

    private func modeDescription(for mode: FocusMode) -> String {
        switch mode.statsTag {
        case "design": return "全力投入设计，屏蔽干扰"
        case "research": return "自由探索，保持好奇"
        case "communication": return "处理消息，团队协作"
        case "writing": return "安静写作，整理思路"
        default: return mode.name
        }
    }

    private func revealExtensionInFinder() {
        // Try common locations for ChromeExtension folder
        let candidates = [
            // Inside app bundle (production)
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/ChromeExtension"),
            // Next to app bundle (development - Xcode DerivedData)
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent("ChromeExtension"),
            // Project source directory (development)
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Projects/Mac/ADHD/ADHDFocus/ChromeExtension"),
        ]
        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
                return
            }
        }
        // Last fallback: open the app bundle
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    private func completedOnboarding() {
        guard let index = selectedModeIndex, index < modes.count else { return }
        let mode = modes[index]
        engine?.activate(mode: mode)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}

// MARK: - Supporting Shapes & Styles

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
