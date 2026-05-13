<img width="1512" height="982" alt="Stick screenshot" src="https://github.com/user-attachments/assets/47965465-ce0d-4156-b629-11b0723ce8c5" />

# Stick

**Sticky notes for macOS. Native, minimal, and always in view.**

Stick puts lightweight notes directly on your desktop. Jot down a thought, paste a link, keep a reminder visible, then get back to work. It is built with SwiftUI, has no Electron shell, no subscriptions, and stores your notes locally.

Stick uses Apple's Liquid Glass design, so it is made for **macOS 26 and newer**.

## Install

### Easiest: ask your AI assistant

Paste this into Codex, Cursor, Claude Code, ChatGPT, or another coding assistant:

```text
Install Stick from https://github.com/jvalaj/stick on my Mac. Clone the repo, run ./scripts/build-app.sh, move dist/Stick.app to my Applications folder, and explain how to open it if macOS blocks the unsigned app.
```

### One-command install

If you have Xcode Command Line Tools installed:

```bash
curl -fsSL https://raw.githubusercontent.com/jvalaj/stick/main/install.sh | bash
```

This builds Stick locally and installs it to:

```text
~/Applications/Stick.app
```

### Open the app

Stick is currently unsigned so it can stay free to publish. The first time you open it, macOS may block it.

Use:

```text
Right-click Stick.app -> Open -> Open
```

After that, it opens normally.

## Requirements

- macOS 26 or later
- Xcode Command Line Tools for source installs

Install the tools with:

```bash
xcode-select --install
```

## Build Manually

```bash
git clone https://github.com/jvalaj/stick.git
cd stick
./scripts/build-app.sh
```

The app and release zip are created at:

```text
dist/Stick.app
dist/Stick.zip
```

## Notes Storage

Stick saves notes as JSON in your Application Support folder. The dashboard shows the exact path and can reveal it in Finder.

## Contributing

Stick is open source. Bug reports, UI polish, accessibility improvements, and small focused features are welcome.

Please keep the spirit of the app: native, minimal, local-first, and lightweight.

## License

Stick is released under the [MIT License](LICENSE).
