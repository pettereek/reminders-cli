import AppKit
import Rainbow

private let settingsFile = "default-list"
private let settingsDirectory = "Reminders CLI"

final class DefaultList {
    func getDefaultListIdentifier() -> String {
        do {
            let id = try String(contentsOfFile: settingsFileURL()!.path!, encoding: NSUTF8StringEncoding)
            return id
        } catch {
            print("error: \(error)")
        }
        return ""
    }

    func setDefaultList(withIdentifier id: String, listName name: String) {
        do {
            try id.writeToFile(settingsFileURL()!.path!, atomically: true, encoding: NSUTF8StringEncoding)
            print("Using \(name.cyan)")
        } catch {
            print("error: \(error)")
        }
    }

    private func settingsDirectoryURL() -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)

        guard let applicationSupportURL = urls.first else { return nil }
        return applicationSupportURL.URLByAppendingPathComponent(settingsDirectory)
    }

    private func settingsFileURL() -> NSURL? {
        guard let directoryURL = settingsDirectoryURL() else { return nil }
        return directoryURL.URLByAppendingPathComponent(settingsFile)
    }
}
