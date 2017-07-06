# reminders-cli

A simple CLI for interacting with OS X reminders.

## Usage:

#### Show reminders

```
$ reminders ls
Eventually
  0 Run a marathon
  1 Skydive
```

#### Show all lists

```
$ reminders lists
Lists:
  Soon
  Eventually ✔︎
```

#### Set your active list

```
$ reminders use Soon
Using Soon
  0 Write README
  1 Ship reminders-cli
```

#### Complete an item

```
$ reminders done 0
  ✔ ︎Write README
Soon
  0 ship reminders-cli
$ reminders ls --completed
Completed in Soon
  0 Write README
```

#### Add a reminder

```
$ reminders add Pack for big trip
Soon
  0 ship reminders-cli
  + Pack for big trip
$ reminders remove 1
  ✗ Pack for big trip
Soon
  0 ship reminders-cli
```

## Installation:

#### With [Homebrew](http://brew.sh/)

```
$ brew install keith/formulae/reminders-cli
```

**NOTE** You must have Xcode 7.3.1 installed at
`/Applications/Xcode.app` for this to work correctly. If this isn't the
case you should build manually as described below.

#### Manually

Download the latest release from
[here](https://github.com/keith/reminders-cli/releases)

```
$ tar -zxvf reminders.tar.gz
$ mv reminders /usr/local/bin
$ rm reminders.tar.gz
```

#### Building manually

Install [swiftenv](https://github.com/kylef/swiftenv/)

```
$ cd reminders-cli
$ swiftenv install
$ swift build --configuration release
$ cp .build/release/reminders /usr/local/bin/reminders
```
