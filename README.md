# Murmurs

Murmurs is a voice journal: record audio memos, transcribe them, and summarize them with AI. It currently ships as an iOS and watchOS app.

## Requirements

- Xcode 26 or later (the live transcriber uses the iOS 26 SDK)
- Deployment targets: iOS 18.0, watchOS 11.0
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Building the project

Follow these steps to build the project:

#### 1. Clone the repo

```shell
git clone https://github.com/lixw1994/murmurs
```

#### 2. Install xcodegen

```shell
brew install xcodegen
```

#### 3. Generate the project

```shell
xcodegen
```

Once you've followed these steps, you should have a fully built project ready for development. If you encounter any issues, please open an issue in the repository.

## Project documentation

- [Architecture](./docs/architecture.md) — how the current app is structured
- [Roadmap](./docs/roadmap.md) — the plan for Android, web, desktop, and cloud sync
- [Architecture decisions](./adr/) — why the target architecture looks the way it does

## License

Distributed under the GNU General Public License v2.0. See [LICENSE](./LICENSE) for more information.

This project is a fork of [duxins/alog](https://github.com/duxins/alog).
