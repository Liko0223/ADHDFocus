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
        NavigationSplitView {
            List(MainTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .navigationSplitViewColumnWidth(min: 130, ideal: 150, max: 180)
        } detail: {
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Color.clear.frame(width: 0, height: 0)
            }
        }
        .toolbarBackground(.visible, for: .windowToolbar)
    }
}
