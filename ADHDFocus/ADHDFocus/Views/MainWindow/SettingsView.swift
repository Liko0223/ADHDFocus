import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var launchAtLogin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("设置")
                    .font(.title2.weight(.semibold))

                GroupBox("通用") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("登录时自动启动", isOn: $launchAtLogin)
                    }
                    .padding(8)
                }

                GroupBox("权限状态") {
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionRow(
                            name: "辅助功能",
                            description: "监听和控制其他应用",
                            isGranted: AXIsProcessTrusted()
                        )
                        PermissionRow(
                            name: "通知",
                            description: "番茄钟提醒和拦截通知",
                            isGranted: true
                        )
                    }
                    .padding(8)
                }

                GroupBox("勿扰模式设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("需要在 macOS 快捷指令 App 中创建两个快捷指令：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("1. \"Enable DND\" — 设置专注模式为勿扰，开启")
                            .font(.caption.monospaced())
                        Text("2. \"Disable DND\" — 设置专注模式为勿扰，关闭")
                            .font(.caption.monospaced())

                        Button("打开快捷指令") {
                            NSWorkspace.shared.open(URL(string: "shortcuts://")!)
                        }
                        .padding(.top, 4)
                    }
                    .padding(8)
                }

                GroupBox("Chrome 扩展") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("安装 Chrome 扩展以拦截被禁网站：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("1. 打开 Chrome，进入 chrome://extensions")
                            .font(.caption)
                        Text("2. 开启「开发者模式」")
                            .font(.caption)
                        Text("3. 点击「加载已解压的扩展」")
                            .font(.caption)
                        Text("4. 选择 ADHDFocus 应用包内的 ChromeExtension 文件夹")
                            .font(.caption)
                        Text("扩展通过本地 HTTP 服务器（端口 52836）与 ADHD Focus 通信，请确保 ADHD Focus 在后台运行。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(8)
                }

                GroupBox("关于") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ADHD Focus v1.0.0")
                            .font(.caption)
                        Text("专为 ADHD 打造的专注助手")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Button("重新体验引导流程") {
                            if let appDelegate = NSApp.delegate as? AppDelegate {
                                appDelegate.showOnboarding()
                            }
                        }
                        .controlSize(.small)
                    }
                    .padding(8)
                }
            }
            .padding(24)
        }
    }
}

struct PermissionRow: View {
    let name: String
    let description: String
    let isGranted: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.body)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isGranted ? .green : .orange)
            if !isGranted {
                Button("授权") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                .controlSize(.small)
            }
        }
    }
}
