import PackageDescription

let package = Package(
    name: "reminders",
    dependencies: [
        .Package(url: "https://github.com/kylef/Commander", majorVersion: 0),
        .Package(url: "https://github.com/onevcat/Rainbow", majorVersion: 2, minor: 0),
    ]
)
