# Murmurs

Murmurs is a voice journal: record audio memos, transcribe them, and summarize them with AI. It currently ships as an iOS and watchOS app. A web app and a Cloudflare backend are in development.

## Repository layout

| Directory | Contents |
|---|---|
| [`apple/`](./apple) | iOS and watchOS app (Swift, XcodeGen) |
| [`web/`](./web) | Web app and `/api/v1` API on one Cloudflare Worker |
| [`contract/`](./contract) | OpenAPI contract generated from the API |
| [`l10n/`](./l10n) | Localized strings for every platform |

## Requirements

- Apple app: Xcode 26 or later (the live transcriber uses the iOS 26 SDK), [XcodeGen](https://github.com/yonaskolb/XcodeGen); deployment targets iOS 18.0 and watchOS 11.0
- Web: Node.js 24 and pnpm 10
- Contract checks: Docker (for the Kotlin generator and, if `oasdiff` is not installed, the breaking-change check)

## Build the Apple app

```shell
git clone https://github.com/lixw1994/murmurs
cd murmurs/apple
brew install xcodegen
xcodegen
open Murmurs.xcodeproj
```

The first time Xcode builds the `MurmursAPI` package, approve its swift-openapi-generator build plugin ("Trust & Enable"). Command-line builds pass `-skipPackagePluginValidation` instead. Debug builds talk to the staging API at `https://murmurs-staging.denkit.app`.

## Run the web app locally

```shell
pnpm --dir web install
printf 'BETTER_AUTH_SECRET=%s\n' "$(openssl rand -hex 32)" > web/.dev.vars
pnpm --dir web db:migrate:local
pnpm --dir web dev
```

`web/.dev.vars` holds local secrets and is not committed; `web/.dev.vars.example` lists the keys. Only `/api/auth/*` needs `BETTER_AUTH_SECRET`.

Open http://localhost:3000. The health endpoint is at http://localhost:3000/api/v1/health:

```json
{ "status": "ok", "version": "0.1.0", "environment": "development" }
```

## Regenerate localized strings

Edit `l10n/Localizable.csv`, then run `rake l10n` from the repository root. It regenerates the Swift strings in `apple/` and the web locale files in `web/`.

If you encounter any issues, please open an issue in the repository.

## Project documentation

- [Architecture](./docs/architecture.md) — how the current system is structured
- [Roadmap](./docs/roadmap.md) — the plan for Android, web, desktop, and cloud sync
- [Architecture decisions](./adr/) — why the target architecture looks the way it does

## License

Distributed under the GNU General Public License v2.0. See [LICENSE](./LICENSE) for more information.

This project is a fork of [duxins/alog](https://github.com/duxins/alog).
