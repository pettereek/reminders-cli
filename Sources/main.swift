import AppKit
import Commander

private let reminders = Reminders()
private let defaultList = DefaultList()

private let completedFlag = Flag("completed", description: "In completed reminders")
private let verboseFlag = Flag("verbose", description: "Verbose output")

private func createCLI() -> Group {
    let id = defaultList.getDefaultListIdentifier()

    func showReminders(completed: Bool) {
        reminders.showListItems(withIdentifier: id, completed: completed)
    }

    return Group {
        $0.command("ls", completedFlag, showReminders)

        $0.command(
            "done",
            Argument<Int>("at index", description: "(zero based) Index of the reminder to complete")
        ) { (index: Int) in
            reminders.complete(itemAtIndex: index, onList: id)
            reminders.showListItems(withIdentifier: id)
        }
        $0.command("add") { (parser: ArgumentParser) in
            let string = parser.remainder.joined(separator: " ")
            let count = reminders.addReminder(string: string, toList: id)
            reminders.showListItems(withIdentifier: id, highlighted: count-1)
        }
        $0.command(
            "rm",
            completedFlag,
            Argument<Int>("at index", description: "(zero based) Index of the remider to remove")
        ) { (completed: Bool, index: Int) in
            reminders.removeReminder(atIndex: index, onList: id, completed: completed)
            reminders.showListItems(withIdentifier: id, completed: completed)
        }

        $0.command(
            "use",
            Argument<String>("name", description: "Name or id of list to use (see: `lists --verbose`)")
        ) { (listName: String) in
            let (id, name) = reminders.idForList(withName: listName)
            defaultList.setDefaultList(withIdentifier: id, listName: name)
            reminders.showListItems(withIdentifier: id, withHeader: false)
        }

        $0.command(
            "lists",
            verboseFlag
        ) { (verbose: Bool) in
            reminders.showLists(withActiveList: id, verbose: verbose)
        }
    }
}

reminders.requestAccess { granted in
    if granted {
        createCLI().run()
    } else {
        print("You need to grant reminders access")
        exit(1)
    }
}

NSApplication.shared().run()
