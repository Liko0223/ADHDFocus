import SwiftUI
import AppKit

struct AppPickerView: View {
    let title: String
    @Binding var selectedBundleIDs: [String]
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var installedApps: [InstalledApp] = []

    private var filteredApps: [InstalledApp] {
        if searchText.isEmpty { return installedApps }
        let query = searchText.lowercased()
        return installedApps.filter {
            $0.name.lowercased().contains(query) || $0.id.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(selectedBundleIDs.count) 个已选")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索应用...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            Divider()

            // App list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredApps) { app in
                        let isSelected = selectedBundleIDs.contains(app.id)
                        Button {
                            if isSelected {
                                selectedBundleIDs.removeAll { $0 == app.id }
                            } else {
                                selectedBundleIDs.append(app.id)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                AppIconView(path: app.path)
                                    .frame(width: 28, height: 28)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(app.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text(app.id)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? .purple : .secondary.opacity(0.3))
                                    .font(.title3)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .background(isSelected ? Color.purple.opacity(0.08) : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
        }
        .frame(width: 420, height: 500)
        .onAppear {
            installedApps = InstalledAppsProvider.shared.getInstalledApps()
        }
    }
}

struct AppIconView: View {
    let path: String

    var body: some View {
        let icon = NSWorkspace.shared.icon(forFile: path)
        Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
