import EventKit
import Rainbow

private let Store = EKEventStore()
private let indent = " "

final class Reminders {
    func requestAccess(completion: @escaping (_: Bool) -> Void) {
        Store.requestAccess(to: .reminder) { granted, _ in
            executeOnMainQueue {
                completion(granted)
            }
        }
    }

    func idForList(withName name: String) -> String {
        let calendar = self.calendar(withName: name)
        return calendar.calendarIdentifier
    }

    func nameForList(withIdentifier id: String) -> String {
        let calendar = self.calendar(withIdentifier: id)
        return calendar.title
    }

    func showLists(withActiveList id: String, verbose: Bool) {
        let calendars = self.getCalendars()
        print("Lists:")
        for calendar in calendars {
            let active = calendar.calendarIdentifier == id ? "✔︎".green : ""
            let verboseId = verbose ? calendar.calendarIdentifier.lightBlack : ""
            print(indent, calendar.title, active, verboseId)
        }
    }

    func showListItems(withIdentifier id: String, completed: Bool) {
        let calendar = self.calendar(withIdentifier: id)
        let semaphore = DispatchSemaphore.init(value:0)

        self.reminders(onCalendar: calendar, completed: completed) { reminders in
            let completedIn = completed ? "Completed in " : ""
            print(completedIn + calendar.title + ":")
            for (i, reminder) in reminders.enumerated() {
                print(indent, "\(i)".green, reminder.title)
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func complete(itemAtIndex index: Int, onList id: String) {
        let calendar = self.calendar(withIdentifier: id)
        let semaphore = DispatchSemaphore.init(value:0)

        self.reminders(onCalendar: calendar, completed: false) { reminders in
            guard let reminder = reminders[safe: index] else {
                print("No reminder at index \(index) on \(calendar.title)")
                exit(1)
            }

            do {
                reminder.isCompleted = true
                try Store.save(reminder, commit: true)
                print(indent, "✔︎".green, reminder.title)
            } catch let error {
                print("Failed to save reminder with error: \(error)")
                exit(1)
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    func addReminder(string: String, toList id: String) {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        if trimmed == "" {
            print("Cannot add empty reminder")
            exit(1)
        }

        let calendar = self.calendar(withIdentifier: id)
        let reminder = EKReminder(eventStore: Store)
        reminder.calendar = calendar
        reminder.title = trimmed

        do {
            try Store.save(reminder, commit: true)
            print(indent, "\"\(reminder.title)\" added to \(calendar.title)")
        } catch let error {
            print("Failed to save reminder with error: \(error)")
            exit(1)
        }
    }

    func removeReminder(atIndex index: Int, onList id: String, completed: Bool) {
        let calendar = self.calendar(withIdentifier: id)
        let semaphore = DispatchSemaphore.init(value:0)

        self.reminders(onCalendar: calendar, completed: completed) { reminders in
            guard let reminder = reminders[index] as EKReminder? else {
                print("No reminder at index \(index) on \(calendar.title)")
                exit(1)
            }

            do {
                try Store.remove(reminder, commit: true)
                print(indent, "✗".red, reminder.title)
            } catch let error {
                print("Failed to remove reminder with error: \(error)")
                exit(1)
            }

            semaphore.signal()
        }

        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }

    // MARK: - Private functions

    private func reminders(onCalendar calendar: EKCalendar, completed: Bool, completion: @escaping (_: [EKReminder]) -> Void) {
        let predicate = Store.predicateForReminders(in: [calendar])
        Store.fetchReminders(matching: predicate) { reminders in
            let reminders = reminders?.filter { completed ? $0.isCompleted : !$0.isCompleted }
                                      .sorted { $0.creationDate! < $1.creationDate! }
            completion(reminders ?? [])
        }
    }

    private func calendar(withIdentifier id: String) -> EKCalendar {
        if let calendar = self.getCalendars().find(predicate: { $0.calendarIdentifier == id }) {
            return calendar
        } else {
            print("No list with identifier \(id)")
            exit(1)
        }
    }

    private func calendar(withName name: String) -> EKCalendar {
        if let calendar = self.getCalendars().find(predicate: { $0.title.lowercased() == name.lowercased() }) {
            return calendar
        } else {
            print("No reminders list matching \(name)")
            exit(1)
        }
    }

    private func getCalendars() -> [EKCalendar] {
        return Store.calendars(for: .reminder).filter { $0.allowsContentModifications }
    }
}
