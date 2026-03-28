import SwiftUI

enum MainTab: String, CaseIterable {
    case modes = "模式"
    case stats = "统计"
    case settings = "设置"

    var icon: String {
        switch self {
        case .modes: return "rectangle.stack"
        case .stats: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

struct MainWindowView: View {
    @State private var selectedTab: MainTab = .modes
    var engine: FocusEngine

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 4) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .frame(width: 20)
                            Text(tab.rawValue)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(12)
            .frame(width: 140)
            .background(.bar)

            Divider()

            // Content
            switch selectedTab {
            case .modes:
                ModeListView(engine: engine)
            case .stats:
                StatsView()
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 800, minHeight: 520)
    }
}
