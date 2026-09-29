# Kanata Menubar

<img src="Resources/AppIcon.svg" width="96" alt="Kanata Menubar icon">

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

## Usage

**The icon** — a static "K" keycap. It dims when kanata isn't running.

**The menu**

| Item | What it does |
|---|---|
| Kanata — running / stopped | Current state, shown greyed out |
| **Restart Kanata** | `launchctl kickstart -k system/local.kanata`. Disabled while kanata is stopped |
| **Stop Kanata** / **Resume Kanata** | Unloads (`bootout`) or reloads (`bootstrap`) the LaunchDaemon |
| **Start at Login ▸ Kanata Menubar** | Whether this app starts at login. Off by default |
| **Start at Login ▸ kanata (at boot)** | Whether macOS starts kanata at boot: `launchctl enable` / `disable system/local.kanata` |
| **Quit Kanata Menubar** | Quits this app only — kanata keeps running, it's independent |

Everything that changes kanata's **system** daemon (restart, stop, resume, at boot) shows macOS's
standard administrator-password (or Touch ID) prompt. Reading its state never prompts.

**Start at Login ▸ Kanata Menubar** writes or deletes
`~/Library/LaunchAgents/io.github.zepocas.kanata-menubar.plist`. The agent starts the app at login,
restarts it if it crashes, and leaves it quit after **Quit**. Updating the app (`brew upgrade`,
`make install`) keeps it. It takes effect at your next login. It's a plain LaunchAgent plist rather
than `SMAppService`, on purpose: this app is ad-hoc signed, and `SMAppService` pins its registration
to the exact build, so launchd refuses to start the app again after any update.

**Start at Login ▸ kanata (at boot)** is on as long as the daemon isn't `launchctl disable`d, which
is the default: kanata's LaunchDaemon has `RunAtLoad` and `KeepAlive`, so macOS starts it at boot
and relaunches it if it crashes, with or without this app. Turning it off persists across reboots
but doesn't stop the running kanata. **Resume** and **Restart** still work while it's off: they
enable the daemon just long enough to start it, then disable it again.

**Does Stop Kanata survive a reboot?** Only with **kanata (at boot)** off. **Stop** runs `launchctl
bootout`, which only affects the current boot.

## Development

```
Sources/MenubarCore/     status parsing (unit tested)
Sources/KanataMenubar/   AppKit app: status item, menu, launchd control, login item
Tests/MenubarCoreTests/  Swift Testing suite
Resources/               Info.plist, AppIcon.svg, generated AppIcon.icns
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
