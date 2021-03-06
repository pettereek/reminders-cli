import AppKit
import Rainbow

private let settingsFile = "default-list"
private let settingsDirectory = "Reminders CLI"

final class DefaultList {
    func getDefaultListIdentifier() -> String {
        assertFile()
        do {
            let id = try String(contentsOfFile: settingsFileURL()!.path, encoding: String.Encoding.utf8)
            return id
        } catch {
            print("error: \(error)")
        }
        return ""
    }

    func setDefaultList(withIdentifier id: String, listName name: String) {
        assertFile()
        do {
            try id.write(toFile: settingsFileURL()!.path, atomically: true, encoding: String.Encoding.utf8)
            print("Using \(name.cyan)")
        } catch {
            print("error: \(error)")
        }
    }

    private func assertFile() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: settingsDirectoryURL()!.path) {
            do {
                try fm.createDirectory(atPath: settingsDirectoryURL()!.path, withIntermediateDirectories: true)
            } catch {
                print("error creating settings directory: \(error)")
            }
        }
    }

    private func settingsDirectoryURL() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let applicationSupportURL = urls.first else { return nil }
        return applicationSupportURL.appendingPathComponent(settingsDirectory)
    }

    private func settingsFileURL() -> URL? {
        guard let directoryURL = settingsDirectoryURL() else { return nil }
        return directoryURL.appendingPathComponent(settingsFile)
    }
}
