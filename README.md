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

## Install

```sh
brew install --cask zepocas/tap/kanata-menubar
```

This installs the prebuilt app straight into `/Applications` and opens it.

## Build from source

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

### Start at login

```sh
make agents
```

This installs `io.github.zepocas.kanata-menubar` into `~/Library/LaunchAgents` and loads it: the
app starts at login, restarts if it crashes, and stays quit if you quit it from the menu — the
same behavior as the `komorebi` and `skhd` agents in
[komorebi-menubar](https://github.com/zepocas/komorebi-menubar).

```sh
make uninstall-agents   # stop starting it at login
```

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

**Does this start kanata automatically?** Not by itself. kanata's own LaunchDaemon has
`RunAtLoad` and `KeepAlive` set, so macOS already starts it at boot and relaunches it on its own if
it crashes — with or without this app running. This app never resumes it on your behalf; it only
acts when *you* click something.

**Does Stop Kanata survive a reboot?** No. `launchctl bootout` (what **Stop** runs) only removes
kanata from the currently running launchd session. At the next boot or login, launchd reloads every
LaunchDaemon under `/Library/LaunchDaemons` from scratch, `RunAtLoad` fires, and kanata comes back
— regardless of whether you'd stopped it before. A `Stop` that survives reboots would need
`launchctl disable system/local.kanata` instead, which isn't what this app does today.

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
| `make agents` / `make uninstall-agents` | install / remove the login LaunchAgent |
| `make uninstall` | remove the agent and the app |
| `make icon` | regenerate `AppIcon.icns` |
| `make clean` | delete build output |

### Releasing

Pushing a `v*` tag (e.g. `v0.1.0`) makes CI build, zip and publish a GitHub Release with the app
attached — `bundle.sh` stamps `CFBundleShortVersionString` from the tag. Then, with a sibling
`../homebrew-tap` checkout:

```sh
scripts/bump-cask.sh          # downloads the latest release, updates Casks/kanata-menubar.rb
git -C ../homebrew-tap commit -am "kanata-menubar 0.1.0" && git -C ../homebrew-tap push
```

## License

[MIT](LICENSE)
