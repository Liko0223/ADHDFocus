import Foundation

struct DefaultModes {
    static func createAll() -> [FocusMode] {
        [deepDesign(), researchInspiration(), communication(), writing()]
    }

    static func deepDesign() -> FocusMode {
        FocusMode(
            name: "深度设计",
            icon: "🎨",
            statsTag: "design",
            allowedApps: [
                "com.figma.Desktop",
                "com.bohemiancoding.sketch3",
                "com.adobe.Photoshop",
                "com.adobe.illustrator",
                "com.google.Chrome",
                "com.anthropic.claudefordesktop",
                "com.apple.Terminal",
                "com.googlecode.iterm2",
                "dev.warp.Warp-Stable",
                "com.microsoft.VSCode",
                "com.todesktop.230313mzl4w4u92"
            ],
            blockedApps: [
                "com.tencent.xinWeChat",
                "com.electron.lark",
                "com.tinyspeck.slackmacgap"
            ],
            defaultAppPolicy: .block,
            allowedURLs: [
                "dribbble.com", "behance.net", "figma.com", "pinterest.com",
                "awwwards.com", "siteinspire.com", "fonts.google.com", "coolors.co", "unsplash.com"
            ],
            blockedURLs: [
                "weibo.com", "xiaohongshu.com", "bilibili.com", "douyin.com",
                "twitter.com", "x.com", "facebook.com", "instagram.com", "youtube.com"
            ],
            defaultURLPolicy: .remind,
            strictness: .delayAllow,
            enableDND: true,
            hideDock: false,
            isPreset: true,
            sortOrder: 0
        )
    }

    static func researchInspiration() -> FocusMode {
        FocusMode(
            name: "调研灵感",
            icon: "🔬",
            statsTag: "research",
            allowedApps: [
                "com.figma.Desktop", "com.bohemiancoding.sketch3",
                "com.google.Chrome", "com.apple.Notes", "com.apple.Preview"
            ],
            blockedApps: ["com.tencent.xinWeChat", "com.electron.lark"],
            defaultAppPolicy: .remind,
            allowedURLs: [
                "dribbble.com", "behance.net", "figma.com", "pinterest.com",
                "awwwards.com", "siteinspire.com", "medium.com", "github.com", "stackoverflow.com"
            ],
            blockedURLs: ["weibo.com", "bilibili.com", "douyin.com"],
            defaultURLPolicy: .remind,
            strictness: .overlay,
            enableDND: true,
            hideDock: false,
            isPreset: true,
            sortOrder: 1
        )
    }

    static func communication() -> FocusMode {
        FocusMode(
            name: "沟通协作",
            icon: "💬",
            statsTag: "communication",
            allowedApps: [
                "com.tencent.xinWeChat", "com.electron.lark", "com.tinyspeck.slackmacgap",
                "com.google.Chrome", "com.figma.Desktop", "com.apple.mail"
            ],
            blockedApps: [],
            defaultAppPolicy: .allow,
            allowedURLs: [],
            blockedURLs: ["weibo.com", "bilibili.com", "douyin.com"],
            defaultURLPolicy: .allow,
            strictness: .overlay,
            workDuration: 0,
            enableDND: false,
            hideDock: false,
            isPreset: true,
            sortOrder: 2
        )
    }

    static func writing() -> FocusMode {
        FocusMode(
            name: "写作整理",
            icon: "✍️",
            statsTag: "writing",
            allowedApps: [
                "md.obsidian", "com.apple.Notes", "com.apple.TextEdit",
                "notion.id", "com.google.Chrome"
            ],
            blockedApps: [
                "com.tencent.xinWeChat", "com.electron.lark",
                "com.tinyspeck.slackmacgap", "com.figma.Desktop"
            ],
            defaultAppPolicy: .block,
            allowedURLs: ["notion.so", "docs.google.com", "github.com"],
            blockedURLs: [
                "weibo.com", "xiaohongshu.com", "bilibili.com", "douyin.com", "youtube.com"
            ],
            defaultURLPolicy: .block,
            strictness: .delayAllow,
            enableDND: true,
            hideDock: true,
            isPreset: true,
            sortOrder: 3
        )
    }
}
