<img width="1512" height="982" alt="Screenshot 2026-05-12 at 3 59 42 PM" src="https://github.com/user-attachments/assets/47965465-ce0d-4156-b629-11b0723ce8c5" />

# Stick — Sticky Notes for macOS

**Your thoughts, always in view. Never in the way.**

Stick is a free, open-source sticky notes app built natively for macOS. No Electron. No bloat. No subscriptions. Just beautifully minimal notes that live right on your desktop — always there when you need them, invisible when you don't.

Designed to feel like a first-party Apple app. Crafted to stay out of your way.

---

## Why Stick?

Most note apps live in a tab. Stick lives on your desktop — pinned, present, and pixel-perfect. Write a thought, paste a link, jot a reminder. It's there when you glance up. Gone when you need focus.

- ✦ Native macOS app — built in SwiftUI, zero dependencies
- ✦ Always-on-desktop — floats beneath your windows, never lost
- ✦ Gorgeous minimal design — looks like it shipped with your Mac
- ✦ Lightweight — launches instantly, uses almost no memory
- ✦ Fully open source — read it, fork it, make it yours

---

## Install

### Download the app

Download `Stick.zip` from the latest [GitHub Release](https://github.com/jvalaj/stick/releases), unzip it, and drag `Stick.app` to Applications.

Stick is currently distributed unsigned so it can stay free to publish. On first launch, macOS may block it. Use:

```text
Right-click Stick.app -> Open -> Open
```

After the first launch, it opens normally.

### Install from source

If you have Xcode Command Line Tools installed:

```bash
curl -fsSL https://raw.githubusercontent.com/jvalaj/stick/main/install.sh | bash
```

This builds Stick locally and installs it to `~/Applications/Stick.app`.

### Homebrew

Homebrew distribution is supported once a release ZIP is published and a tap is created. The cask template lives at `packaging/homebrew/stick.rb`.

## Requirements

- macOS 26 or later
- Xcode Command Line Tools (for `swift`) — install with `xcode-select --install`

## Run

```bash
git clone https://github.com/jvalaj/stick.git
cd stick
swift run
```

The app launches as a menu-bar item with a dashboard. Click **+ New** to create a sticky note.

## Build a release binary

```bash
swift build -c release
.build/release/StickyNotes
```

## Build a release app

```bash
./scripts/build-app.sh
```

This creates:

```text
dist/Stick.app
dist/Stick.zip
```

Upload `dist/Stick.zip` to a GitHub Release. Without a paid Apple Developer account, the app will be unsigned, so first-time users need to right-click and choose Open.

## Where notes are stored

Notes are saved as JSON in your Application Support folder. The path is shown at the bottom of the dashboard window — click it to reveal the file in Finder.

---

## Contributing

Stick is open source and contributions are very welcome. Whether it's a bug fix, a new feature, a design tweak, or just an idea — jump in.

**How to contribute:**

1. Fork the repo and create a branch: `git checkout -b my-feature`
2. Make your changes — keep them focused and minimal
3. Test the app: `swift run`
4. Commit with a clear message and open a pull request

**Good first contributions:**

- Bug reports (open an [Issue](https://github.com/jvalaj/stick/issues))
- UI polish, animations, accessibility improvements
- New features that fit Stick's minimal philosophy (less is more)
- Documentation improvements

Please keep the spirit of Stick: native, minimal, beautiful. No new dependencies unless absolutely necessary.

## License

Stick is released under the [MIT License](LICENSE). You're free to use, modify, distribute, and even sell it. Just keep the copyright notice in your copies.
