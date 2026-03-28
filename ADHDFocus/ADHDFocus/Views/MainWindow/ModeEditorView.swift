import SwiftUI

struct ModeEditorView: View {
    @Bindable var mode: FocusMode
    @State private var newAllowedApp = ""
    @State private var newBlockedApp = ""
    @State private var newAllowedURL = ""
    @State private var newBlockedURL = ""

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
                        Text("允许的应用 (Bundle ID)")
                            .font(.caption.weight(.medium))
                        appListEditor(
                            items: $mode.allowedApps,
                            newItem: $newAllowedApp,
                            placeholder: "com.figma.Desktop"
                        )

                        Divider()

                        Text("禁止的应用 (Bundle ID)")
                            .font(.caption.weight(.medium))
                        appListEditor(
                            items: $mode.blockedApps,
                            newItem: $newBlockedApp,
                            placeholder: "com.tencent.xinWeChat"
                        )

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
                        appListEditor(
                            items: $mode.allowedURLs,
                            newItem: $newAllowedURL,
                            placeholder: "dribbble.com"
                        )

                        Divider()

                        Text("禁止的网站")
                            .font(.caption.weight(.medium))
                        appListEditor(
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
    }

    @ViewBuilder
    private func appListEditor(items: Binding<[String]>, newItem: Binding<String>, placeholder: String) -> some View {
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
