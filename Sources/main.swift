import AppKit
import Commander

private let reminders = Reminders()
private let defaultList = DefaultList()

private func createCLI() -> Group {
    let id = defaultList.getDefaultListIdentifier()

    return Group {
        $0.command("use") { (listName: String) in
            let id = reminders.idForList(withName: listName)
            defaultList.setDefaultList(withIdentifier: id, listName: listName)
        }
        $0.command(
            "lists",
            Flag("verbose", description: "show more information")
        ) { (verbose) in
            reminders.showLists(withActiveList: id, verbose: verbose)
        }
        $0.command("show") {
            reminders.showListItems(withIdentifier: id)
        }
        $0.command("complete") { (index: Int) in
            reminders.complete(itemAtIndex: index, onList: id)
        }
        $0.command("add") { (parser: ArgumentParser) in
            let string = parser.remainder.joinWithSeparator(" ")
            reminders.addReminder(string: string, toList: id)
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
