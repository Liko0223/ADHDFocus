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
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: accessibilityStep
                case 2: notificationStep
                case 3: modeSelectionStep
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480, height: 560)
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

            catWithBubble(message: "嗨~ 我是你的专注伙伴！")

            Spacer().frame(height: 36)

            Text("ADHD Focus")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer().frame(height: 8)

            Text("为设计师打造的专注助手")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            primaryButton(title: "开始设置 →") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = 1
                }
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 2: Accessibility

    private var accessibilityStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            catWithBubble(message: "帮我开一下权限吧~")

            Spacer().frame(height: 20)

            // Explain what this permission enables
            VStack(alignment: .leading, spacing: 8) {
                Label("拦截分心应用 — 工作时自动遮挡微信、微博等", systemImage: "app.badge.checkmark")
                Label("窗口级遮罩 — 不杀进程，温和地帮你回到工作", systemImage: "rectangle.on.rectangle")
                Label("智能提醒 — 检测到你在用设计工具时建议开启专注", systemImage: "sparkles")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)

            Spacer().frame(height: 20)

            permissionCard(
                title: "辅助功能权限",
                description: "用于监控并拦截分心应用",
                isGranted: accessibilityGranted
            )

            Spacer().frame(height: 16)

            if !accessibilityGranted {
                Button("去授权") {
                    openAccessibilitySettings()
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            Spacer()

            VStack(spacing: 8) {
                if !accessibilityGranted {
                    Text("跳过后应用拦截功能不可用")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                primaryButton(title: "下一步") {
                    accessibilityTimer?.invalidate()
                    accessibilityTimer = nil
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentStep = 2
                    }
                }
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 40)
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
            Spacer().frame(height: 32)

            catWithBubble(message: "允许我发通知~")

            Spacer().frame(height: 20)

            VStack(alignment: .leading, spacing: 8) {
                Label("番茄钟提醒 — 工作结束提醒你休息，休息结束回来工作", systemImage: "timer")
                Label("拦截通知 — 有应用被拦截时告诉你", systemImage: "hand.raised")
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)

            Spacer().frame(height: 20)

            permissionCard(
                title: "通知权限",
                description: "番茄钟结束时发送休息提醒",
                isGranted: notificationStatus == .authorized
            )

            Spacer().frame(height: 16)

            Button(notificationStatus == .authorized ? "查看通知设置" : "去授权") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            primaryButton(title: "下一步") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentStep = 3
                }
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 40)
        .onAppear {
            requestNotificationPermission()
        }
    }

    // MARK: - Step 4: Mode Selection

    private var modeSelectionStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            catWithBubble(message: "选一个你常用的模式，马上开始第一次专注！")

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

            Spacer().frame(height: 16)

            // Browser extension collapsible section
            extensionSection

            Spacer()

            primaryButton(
                title: "开始专注！",
                isEnabled: selectedModeIndex != nil
            ) {
                completedOnboarding()
            }

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 40)
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

    private func permissionCard(title: String, description: String, isGranted: Bool) -> some View {
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
        }
        .padding(16)
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
        if let bundleURL = Bundle.main.bundleURL.deletingLastPathComponent() as URL? {
            let extensionURL = bundleURL.appendingPathComponent("ChromeExtension")
            if FileManager.default.fileExists(atPath: extensionURL.path) {
                NSWorkspace.shared.activateFileViewerSelecting([extensionURL])
                return
            }
        }
        // Fallback: reveal the app's Resources folder
        if let resourceURL = Bundle.main.resourceURL {
            NSWorkspace.shared.activateFileViewerSelecting([resourceURL])
        }
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
