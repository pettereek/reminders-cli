import EventKit
import Rainbow

private let Store = EKEventStore()
private let indent = " "

final class Reminders {
    func requestAccess(completion: @escaping (_ granted: Bool) -> Void) {
        Store.requestAccess(to: .reminder) { granted, _ in
            DispatchQueue.main.async {
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

    func showListItems(withIdentifier id: String) {
        let calendar = self.calendar(withIdentifier: id)
        let semaphore = dispatch_semaphore_create(0)

        self.reminders(onCalendar: calendar) { reminders in
            print(calendar.title + ":")
            for (i, reminder) in reminders.enumerate() {
                print(indent, "\(i)".green, reminder.title)
            }

            semaphore.signal()
        }

        semaphore.wait()
    }

    func complete(itemAtIndex index: Int, onList id: String) {
        let calendar = self.calendar(withIdentifier: id)
        let semaphore = dispatch_semaphore_create(0)

        self.reminders(onCalendar: calendar) { reminders in
            guard let reminder = reminders[safe: index] else {
                print("No reminder at index \(index) on \(calendar.title)")
                exit(1)
            }

            do {
                reminder.completed = true
                try Store.saveReminder(reminder, commit: true)
                print(indent, "✔︎".green, reminder.title)
            } catch let error {
                print("Failed to save reminder with error: \(error)")
                exit(1)
            }

            semaphore.signal()
        }

        semaphore.wait()
    }

    func addReminder(string string: String, toList id: String) {
        let trimmed = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

        if trimmed == "" {
            print("Cannot add empty reminder")
            exit(1)
        }

        let calendar = self.calendar(withIdentifier: id)
        let reminder = EKReminder(eventStore: Store)
        reminder.calendar = calendar
        reminder.title = trimmed

        do {
            try Store.saveReminder(reminder, commit: true)
            print(indent, "\"\(reminder.title)\" added to \(calendar.title)")
        } catch let error {
            print("Failed to save reminder with error: \(error)")
            exit(1)
        }
    }

    // MARK: - Private functions

    private func reminders(onCalendar calendar: EKCalendar, completion: (reminders: [EKReminder]) -> Void) {
        let predicate = Store.predicateForRemindersInCalendars([calendar])
        Store.fetchRemindersMatchingPredicate(predicate) { reminders in
            let reminders = reminders?.filter { !$0.completed }
                                      .sort { $0.creationDate < $1.creationDate }
            completion(reminders: reminders ?? [])
        }
    }

    private func calendar(withIdentifier id: String) -> EKCalendar {
        if let calendar = self.getCalendars().find({ $0.calendarIdentifier == id }) {
            return calendar
        } else {
            print("No list with identifier \(id)")
            exit(1)
        }
    }

    private func calendar(withName name: String) -> EKCalendar {
        if let calendar = self.getCalendars().find({ $0.title.lowercaseString == name.lowercaseString }) {
            return calendar
        } else {
            print("No reminders list matching \(name)")
            exit(1)
        }
    }

    private func getCalendars() -> [EKCalendar] {
        return Store.calendarsForEntityType(.Reminder).filter { $0.allowsContentModifications }
    }
}
