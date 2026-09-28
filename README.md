# Kanata Menubar

[![CI](https://github.com/zepocas/kanata-menubar/actions/workflows/ci.yml/badge.svg)](https://github.com/zepocas/kanata-menubar/actions/workflows/ci.yml)

A tiny native menubar app to track, stop and restart [kanata](https://github.com/jtroo/kanata) on
macOS. Click the "K" keycap icon for kanata's status and to restart or stop/resume it.

It's plain Swift and AppKit with no dependencies. It uses almost no CPU while idle.

## Requirements

- macOS 14 or later.
- kanata already installed and running as a **system LaunchDaemon** named `local.kanata`, defined
  at `/Library/LaunchDaemons/local.kanata.plist`. This app doesn't install or configure kanata
  itself — it only talks to that daemon through `launchctl`. If your daemon has a different label
  or path, update the constants at the top of `Sources/KanataMenubar/ServiceController.swift`.
- Swift 6 toolchain: either Xcode or just the Command Line Tools (`xcode-select --install`).

## Setup

```sh
git clone git@github.com:zepocas/kanata-menubar.git
cd kanata-menubar
make test      # optional: run the unit tests
make run       # builds KanataMenubar.app, installs it to /Applications and opens it
```

The keycap icon should now appear in the menubar. The app must live in `/Applications` for
its autosaved menubar position to stick.

**Using Thaw, Ice or Bartender?** New items can land in the hidden section. Drag **Kanata
Menubar** into the visible section, using the manager's layout settings or ⌘-drag in the menubar.

## Usage

**The icon** — a static "K" keycap. It dims when kanata isn't running.

**The menu**

| Item | What it does |
|---|---|
| Kanata — running / stopped | Current state, shown greyed out |
| **Restart Kanata** | `launchctl kickstart -k system/local.kanata`. Disabled while kanata is stopped |
| **Stop Kanata** / **Resume Kanata** | Unloads (`bootout`) or reloads (`bootstrap`) the LaunchDaemon |
| **Quit Kanata Menubar** | Quits this app only — kanata keeps running, it's independent |

Stopping, resuming and restarting change a **system** daemon, so macOS shows its standard
administrator-password (or Touch ID) prompt each time. Reading status never prompts.

## Development

```
Sources/MenubarCore/     status parsing (unit tested)
Sources/KanataMenubar/   AppKit app: status item, menu, launchd control
Tests/MenubarCoreTests/  Swift Testing suite
Resources/               Info.plist, generated AppIcon.icns
scripts/                 bundle.sh (builds the .app), make-icon.sh (regenerates the app icon)
```

| Command | Does |
|---|---|
| `make build` | debug build |
| `make test` | unit tests |
| `make install` | release build, installed to `/Applications` |
| `make run` | install and open |
| `make uninstall` | remove the app |
| `make icon` | regenerate `AppIcon.icns` |
| `make clean` | delete build output |

## License

[MIT](LICENSE)
