import SwiftUI
import SwiftData

struct ModeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]
    @State private var selectedMode: FocusMode?
    var engine: FocusEngine

    var body: some View {
        HSplitView {
            // Mode list
            VStack(spacing: 0) {
                List(modes, selection: $selectedMode) { mode in
                    HStack(spacing: 10) {
                        Text(mode.icon)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.name)
                                .font(.body.weight(.medium))
                            Text("\(mode.allowedApps.count) 个允许应用")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if engine.activeMode?.id == mode.id {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 4)
                    .tag(mode)
                }
                .frame(minWidth: 200)

                Divider()

                HStack {
                    Button(action: addMode) {
                        Image(systemName: "plus")
                    }
                    Button(action: deleteSelectedMode) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedMode == nil)
                    Spacer()
                }
                .padding(8)
            }

            // Editor
            if let mode = selectedMode {
                ModeEditorView(mode: mode)
            } else {
                ContentUnavailableView("选择一个模式", systemImage: "rectangle.stack", description: Text("从左侧列表中选择模式进行编辑"))
            }
        }
    }

    private func addMode() {
        let mode = FocusMode(
            name: "新模式",
            icon: "⭐",
            statsTag: "custom",
            sortOrder: modes.count
        )
        modelContext.insert(mode)
        selectedMode = mode
    }

    private func deleteSelectedMode() {
        guard let mode = selectedMode else { return }
        if engine.activeMode?.id == mode.id {
            engine.deactivate()
        }
        modelContext.delete(mode)
        selectedMode = nil
    }
}
