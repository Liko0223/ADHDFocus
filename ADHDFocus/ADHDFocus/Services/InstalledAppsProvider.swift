import Foundation
import AppKit

struct InstalledApp: Identifiable, Hashable {
    let id: String  // Bundle ID
    let name: String
    let path: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.id == rhs.id
    }
}

final class InstalledAppsProvider {
    static let shared = InstalledAppsProvider()

    private var cachedApps: [InstalledApp]?

    func preload() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let apps = self?.loadApps() ?? []
            DispatchQueue.main.async {
                self?.cachedApps = apps
            }
        }
    }

    func getInstalledApps() -> [InstalledApp] {
        if let cached = cachedApps { return cached }
        let apps = loadApps()
        cachedApps = apps
        return apps
    }

    private func loadApps() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        var seenBundleIDs = Set<String>()

        let searchPaths = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for searchPath in searchPaths {
            scanDirectory(URL(fileURLWithPath: searchPath), into: &apps, seen: &seenBundleIDs, depth: 0)
        }

        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return apps
    }

    private func scanDirectory(_ url: URL, into apps: inout [InstalledApp], seen: inout Set<String>, depth: Int) {
        guard depth < 3 else { return }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else { return }

        for item in contents {
            if item.pathExtension == "app" {
                if let app = appInfo(from: item), !seen.contains(app.id) {
                    seen.insert(app.id)
                    apps.append(app)
                }
            } else if item.hasDirectoryPath && depth < 2 {
                scanDirectory(item, into: &apps, seen: &seen, depth: depth + 1)
            }
        }
    }

    private func appInfo(from appURL: URL) -> InstalledApp? {
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let plistData = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let bundleID = plist["CFBundleIdentifier"] as? String else {
            return nil
        }

        let name = (plist["CFBundleDisplayName"] as? String)
            ?? (plist["CFBundleName"] as? String)
            ?? appURL.deletingPathExtension().lastPathComponent

        return InstalledApp(id: bundleID, name: name, path: appURL.path)
    }
}
