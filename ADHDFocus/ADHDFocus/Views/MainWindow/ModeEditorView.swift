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
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    Text(mode.icon)
                        .font(.largeTitle)
                    VStack(alignment: .leading, spacing: 2) {
                        TextField("模式名称", text: $mode.name)
                            .font(.title2.weight(.semibold))
                            .textFieldStyle(.plain)
                        TextField("统计标签", text: $mode.statsTag)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textFieldStyle(.plain)
                    }
                }
                .padding(.bottom, 24)

                // Sections
                editorSection("应用规则") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Allowed apps
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("允许的应用", systemImage: "checkmark.circle")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.green)
                                Spacer()
                                Button {
                                    showAllowedAppPicker = true
                                } label: {
                                    Label("选择", systemImage: "plus.circle")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                            appChipList(items: $mode.allowedApps)
                        }

                        Divider()

                        // Blocked apps
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("禁止的应用", systemImage: "xmark.circle")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.red)
                                Spacer()
                                Button {
                                    showBlockedAppPicker = true
                                } label: {
                                    Label("选择", systemImage: "plus.circle")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                            appChipList(items: $mode.blockedApps)
                        }

                        Divider()

                        HStack {
                            Text("未列出的应用")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $mode.defaultAppPolicy) {
                                Text("允许").tag(AppPolicy.allow)
                                Text("提醒").tag(AppPolicy.remind)
                                Text("禁止").tag(AppPolicy.block)
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }
                    }
                }

                editorSection("浏览器规则") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("允许的网站", systemImage: "checkmark.circle")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.green)
                            urlListEditor(
                                items: $mode.allowedURLs,
                                newItem: $newAllowedURL,
                                placeholder: "dribbble.com"
                            )
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("禁止的网站", systemImage: "xmark.circle")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.red)
                            urlListEditor(
                                items: $mode.blockedURLs,
                                newItem: $newBlockedURL,
                                placeholder: "weibo.com"
                            )
                        }

                        Divider()

                        HStack {
                            Text("未列出的网站")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $mode.defaultURLPolicy) {
                                Text("允许").tag(AppPolicy.allow)
                                Text("提醒").tag(AppPolicy.remind)
                                Text("禁止").tag(AppPolicy.block)
                            }
                            .labelsHidden()
                            .frame(width: 100)
                        }
                    }
                }

                // Pomodoro + Strategy side by side
                HStack(alignment: .top, spacing: 16) {
                    editorSection("番茄钟") {
                        VStack(spacing: 10) {
                            formRow("工作", minutes: Binding(
                                get: { mode.workDuration / 60 },
                                set: { mode.workDuration = $0 * 60 }
                            ))
                            formRow("休息", minutes: Binding(
                                get: { mode.breakDuration / 60 },
                                set: { mode.breakDuration = $0 * 60 }
                            ))
                            formRow("长休息", minutes: Binding(
                                get: { mode.longBreakDuration / 60 },
                                set: { mode.longBreakDuration = $0 * 60 }
                            ))
                            HStack {
                                Text("轮数")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("4", value: $mode.longBreakInterval, format: .number)
                                    .frame(width: 50)
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.center)
                            }
                            if mode.workDuration == 0 {
                                Label("番茄钟已禁用", systemImage: "pause.circle")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    editorSection("环境与策略") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("勿扰模式", isOn: $mode.enableDND)
                                .font(.subheadline)
                            Toggle("隐藏 Dock", isOn: $mode.hideDock)
                                .font(.subheadline)

                            Divider()

                            HStack {
                                Text("拦截方式")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $mode.strictness) {
                                    Text("提醒").tag(Strictness.remind)
                                    Text("强制退出").tag(Strictness.forceQuit)
                                    Text("延迟允许").tag(Strictness.delayAllow)
                                }
                                .labelsHidden()
                                .frame(width: 100)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(.background)
        .sheet(isPresented: $showAllowedAppPicker) {
            AppPickerView(title: "选择允许的应用", selectedBundleIDs: $mode.allowedApps)
        }
        .sheet(isPresented: $showBlockedAppPicker) {
            AppPickerView(title: "选择禁止的应用", selectedBundleIDs: $mode.blockedApps)
        }
    }

    // MARK: - Section wrapper

    @ViewBuilder
    private func editorSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            content()
                .padding(16)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .padding(.bottom, 20)
    }

    // MARK: - Form row for time

    private func formRow(_ label: String, minutes: Binding<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            TextField("", value: minutes, format: .number)
                .frame(width: 50)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
            Text("分钟")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - App chips

    @ViewBuilder
    private func appChipList(items: Binding<[String]>) -> some View {
        if items.wrappedValue.isEmpty {
            Text("未选择")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.vertical, 4)
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

    // MARK: - URL list

    @ViewBuilder
    private func urlListEditor(items: Binding<[String]>, newItem: Binding<String>, placeholder: String) -> some View {
        if !items.wrappedValue.isEmpty {
            FlowLayout(spacing: 6) {
                ForEach(items.wrappedValue, id: \.self) { item in
                    HStack(spacing: 4) {
                        Text(item)
                            .font(.caption)
                        Button {
                            items.wrappedValue.removeAll { $0 == item }
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
            }
        }
        HStack(spacing: 8) {
            TextField(placeholder, text: newItem)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .onSubmit {
                    addURL(items: items, newItem: newItem)
                }
            Button("添加") {
                addURL(items: items, newItem: newItem)
            }
            .controlSize(.small)
            .disabled(newItem.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addURL(items: Binding<[String]>, newItem: Binding<String>) {
        let value = newItem.wrappedValue.trimmingCharacters(in: .whitespaces)
        if !value.isEmpty && !items.wrappedValue.contains(value) {
            items.wrappedValue.append(value)
            newItem.wrappedValue = ""
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
