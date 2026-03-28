import SwiftUI
import AppKit

struct ModeEditorView: View {
    @Bindable var mode: FocusMode
    @State private var newAllowedURL = ""
    @State private var newBlockedURL = ""
    @State private var showAllowedAppPicker = false
    @State private var showBlockedAppPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Basic info
                GroupBox("基本信息") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("图标", text: $mode.icon)
                                .frame(width: 50)
                            TextField("名称", text: $mode.name)
                        }
                        TextField("统计标签", text: $mode.statsTag)
                    }
                    .padding(8)
                }

                // App rules
                GroupBox("应用规则") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("允许的应用")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Button("选择应用") {
                                showAllowedAppPicker = true
                            }
                            .controlSize(.small)
                        }
                        appChipList(items: $mode.allowedApps)

                        Divider()

                        HStack {
                            Text("禁止的应用")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Button("选择应用") {
                                showBlockedAppPicker = true
                            }
                            .controlSize(.small)
                        }
                        appChipList(items: $mode.blockedApps)

                        Divider()

                        Picker("未列出的应用", selection: $mode.defaultAppPolicy) {
                            Text("允许").tag(AppPolicy.allow)
                            Text("提醒").tag(AppPolicy.remind)
                            Text("禁止").tag(AppPolicy.block)
                        }
                    }
                    .padding(8)
                }

                // URL rules
                GroupBox("浏览器规则") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("允许的网站")
                            .font(.caption.weight(.medium))
                        urlListEditor(
                            items: $mode.allowedURLs,
                            newItem: $newAllowedURL,
                            placeholder: "dribbble.com"
                        )

                        Divider()

                        Text("禁止的网站")
                            .font(.caption.weight(.medium))
                        urlListEditor(
                            items: $mode.blockedURLs,
                            newItem: $newBlockedURL,
                            placeholder: "weibo.com"
                        )

                        Divider()

                        Picker("未列出的网站", selection: $mode.defaultURLPolicy) {
                            Text("允许").tag(AppPolicy.allow)
                            Text("提醒").tag(AppPolicy.remind)
                            Text("禁止").tag(AppPolicy.block)
                        }
                    }
                    .padding(8)
                }

                // Restriction strategy
                GroupBox("限制策略") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("严格程度", selection: $mode.strictness) {
                            Text("温和提醒").tag(Strictness.remind)
                            Text("强制退出").tag(Strictness.forceQuit)
                            Text("延迟允许").tag(Strictness.delayAllow)
                        }
                        HStack {
                            Text("冷却期（分钟）")
                            TextField("0", value: $mode.cooldownMinutes, format: .number)
                                .frame(width: 60)
                        }
                    }
                    .padding(8)
                }

                // Pomodoro config
                GroupBox("番茄钟") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("工作时长（分钟）")
                            TextField("25", value: Binding(
                                get: { mode.workDuration / 60 },
                                set: { mode.workDuration = $0 * 60 }
                            ), format: .number)
                            .frame(width: 60)
                        }
                        HStack {
                            Text("休息时长（分钟）")
                            TextField("5", value: Binding(
                                get: { mode.breakDuration / 60 },
                                set: { mode.breakDuration = $0 * 60 }
                            ), format: .number)
                            .frame(width: 60)
                        }
                        HStack {
                            Text("长休息时长（分钟）")
                            TextField("15", value: Binding(
                                get: { mode.longBreakDuration / 60 },
                                set: { mode.longBreakDuration = $0 * 60 }
                            ), format: .number)
                            .frame(width: 60)
                        }
                        HStack {
                            Text("每几轮后长休息")
                            TextField("4", value: $mode.longBreakInterval, format: .number)
                                .frame(width: 60)
                        }
                        if mode.workDuration == 0 {
                            Text("番茄钟已禁用（工作时长为 0）")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(8)
                }

                // Environment
                GroupBox("环境配置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("自动开启勿扰模式", isOn: $mode.enableDND)
                        Toggle("自动隐藏 Dock", isOn: $mode.hideDock)
                    }
                    .padding(8)
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showAllowedAppPicker) {
            AppPickerView(title: "选择允许的应用", selectedBundleIDs: $mode.allowedApps)
        }
        .sheet(isPresented: $showBlockedAppPicker) {
            AppPickerView(title: "选择禁止的应用", selectedBundleIDs: $mode.blockedApps)
        }
    }

    @ViewBuilder
    private func appChipList(items: Binding<[String]>) -> some View {
        if items.wrappedValue.isEmpty {
            Text("未选择任何应用")
                .font(.caption)
                .foregroundStyle(.tertiary)
        } else {
            FlowLayout(spacing: 6) {
                ForEach(items.wrappedValue, id: \.self) { bundleID in
                    AppChipView(bundleID: bundleID) {
                        items.wrappedValue.removeAll { $0 == bundleID }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func urlListEditor(items: Binding<[String]>, newItem: Binding<String>, placeholder: String) -> some View {
        ForEach(items.wrappedValue, id: \.self) { item in
            HStack {
                Text(item)
                    .font(.caption.monospaced())
                Spacer()
                Button {
                    items.wrappedValue.removeAll { $0 == item }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        HStack {
            TextField(placeholder, text: newItem)
                .font(.caption.monospaced())
                .onSubmit {
                    let value = newItem.wrappedValue.trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty && !items.wrappedValue.contains(value) {
                        items.wrappedValue.append(value)
                        newItem.wrappedValue = ""
                    }
                }
            Button("添加") {
                let value = newItem.wrappedValue.trimmingCharacters(in: .whitespaces)
                if !value.isEmpty && !items.wrappedValue.contains(value) {
                    items.wrappedValue.append(value)
                    newItem.wrappedValue = ""
                }
            }
            .disabled(newItem.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}

// MARK: - App Chip

struct AppChipView: View {
    let bundleID: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appPath))
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(appName(for: appPath))
                    .font(.caption)
            } else {
                Text(bundleID)
                    .font(.caption.monospaced())
            }
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.5))
        .clipShape(Capsule())
    }

    private func appName(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let plistURL = url.appendingPathComponent("Contents/Info.plist")
        if let data = try? Data(contentsOf: plistURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
            return (plist["CFBundleDisplayName"] as? String)
                ?? (plist["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
        }
        return url.deletingPathExtension().lastPathComponent
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
