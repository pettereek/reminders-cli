import AppKit
import Commander

private let reminders = Reminders()
private let defaultList = DefaultList()

private func createCLI() -> Group {
    let id = defaultList.getDefaultListIdentifier()

    return Group {
        $0.command("use") { (listName: String) in
            let (id, name) = reminders.idForList(withName: listName)
            defaultList.setDefaultList(withIdentifier: id, listName: name)
        }
        $0.command("lists", Flag("verbose", description: "Show more information")) { (verbose) in
            reminders.showLists(withActiveList: id, verbose: verbose)
        }
        $0.command("show", Flag("completed", description: "Show completed reminders")) { completed in
            reminders.showListItems(withIdentifier: id, completed: completed)
        }
        $0.command("complete") { (index: Int) in
            reminders.complete(itemAtIndex: index, onList: id)
        }
        $0.command("add") { (parser: ArgumentParser) in
            let string = parser.remainder.joined(separator: " ")
            reminders.addReminder(string: string, toList: id)
        }
        $0.command("remove",
            Flag("completed", description: "Remove from completed reminders"),
            Argument<Int>("index")
        ) { completed, index in
            reminders.removeReminder(atIndex: index, onList: id, completed: completed)
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
