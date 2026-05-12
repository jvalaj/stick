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

## Requirements

- macOS 13 or later
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

To keep it running after closing the terminal, copy the binary somewhere on your `PATH` or wrap it in an `.app` bundle.

## Where notes are stored

Notes are saved as JSON in your Application Support folder. The path is shown at the bottom of the dashboard window — click it to reveal the file in Finder.
