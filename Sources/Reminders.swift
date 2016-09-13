import EventKit
import Rainbow

private let Store = EKEventStore()

final class Reminders {
    func requestAccess(completion: @escaping (_ granted: Bool) -> Void) {
        Store.requestAccess(to: .reminder) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func showLists() {
        let calendars = self.getCalendars()
        print("Lists:")
        for calendar in calendars {
            print("  -".green, calendar.title)
        }
    }

    func showListItems(withName name: String) {
        let calendar = self.calendar(withName: name)
        let semaphore = DispatchSemaphore(value: 0)

        self.reminders(onCalendar: calendar) { reminders in
            print("Items in \(name.green):")
            for (i, reminder) in reminders.enumerate() {
                print("  \(i)".green, reminder.title)
            }

            semaphore.signal()
        }

        semaphore.wait()
    }

    func complete(itemAtIndex index: Int, onListNamed name: String) {
        let calendar = self.calendar(withName: name)
        let semaphore = DispatchSemaphore(value: 0)

        self.reminders(onCalendar: calendar) { reminders in
            guard let reminder = reminders[safe: index] else {
                print("No reminder at index \(index) on \(name)")
                exit(1)
            }

            do {
                reminder.completed = true
                try Store.saveReminder(reminder, commit: true)
                let done = "✔︎".green
                print("  \(done) \(reminder.title)")
            } catch let error {
                print("Failed to save reminder with error: \(error)")
                exit(1)
            }

            semaphore.signal()
        }

        semaphore.wait()
    }

    func addReminder(string: String, toListNamed name: String) {
        let calendar = self.calendar(withName: name)
        let reminder = EKReminder(eventStore: Store)
        reminder.calendar = calendar
        reminder.title = string

        do {
            try Store.saveReminder(reminder, commit: true)
            let added = "✗".green
            print("  \(added) \(reminder.title) added to \(calendar.title)")
        } catch let error {
            print("Failed to save reminder with error: \(error)")
            exit(1)
        }
    }

    // MARK: - Private functions

    private func reminders(onCalendar calendar: EKCalendar,
                                      completion: @escaping (_ reminders: [EKReminder]) -> Void)
    {
        let predicate = Store.predicateForReminders(in: [calendar])
        Store.fetchReminders(matching: predicate) { reminders in
            let reminders = reminders?
                .filter { !$0.isCompleted }
                .sorted { ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast) }
            completion(reminders ?? [])
        }
    }

    private func calendar(withName name: String) -> EKCalendar {
        if let calendar = self.getCalendars().find(where: { $0.title.lowercased() == name.lowercased() }) {
            return calendar
        } else {
            print("No reminders list matching \(name)")
            exit(1)
        }
    }

    private func getCalendars() -> [EKCalendar] {
        return Store.calendars(for: .reminder)
                    .filter { $0.allowsContentModifications }
    }
}
