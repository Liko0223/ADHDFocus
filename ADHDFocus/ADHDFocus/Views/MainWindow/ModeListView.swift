import SwiftUI
import SwiftData

struct ModeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]
    @State private var selectedMode: FocusMode?
    var engine: FocusEngine

    var body: some View {
        HStack(spacing: 0) {
            // Mode list
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(modes) { mode in
                            ModeRowView(
                                mode: mode,
                                isSelected: selectedMode?.id == mode.id,
                                isActive: engine.activeMode?.id == mode.id
                            )
                            .onTapGesture {
                                selectedMode = mode
                            }
                        }
                    }
                    .padding(8)
                }

                Divider()

                HStack(spacing: 8) {
                    Button(action: addMode) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    Button(action: deleteSelectedMode) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedMode == nil)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(width: 200)
            .background(.background)

            Divider()

            // Editor
            if let mode = selectedMode {
                ModeEditorView(mode: mode)
                    .id(mode.id)
            } else {
                ContentUnavailableView(
                    "选择一个模式",
                    systemImage: "rectangle.stack",
                    description: Text("从左侧列表中选择模式进行编辑")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct ModeRowView: View {
    let mode: FocusMode
    let isSelected: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 10) {
            Text(mode.icon)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(mode.name)
                    .font(.body.weight(.medium))
                Text("\(mode.allowedApps.count) 个允许应用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isActive {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
