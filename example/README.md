# flutter_inertia example

A persistent counter app demonstrating `flutter_inertia` — increment, decrement, and reset actions
driven by Inertia.js, state stored via `shared_preferences`.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- [Node.js](https://nodejs.org/) (18+)
- [pnpm](https://pnpm.io/installation): `npm install -g pnpm`

## Setup

```bash
cd example
pnpm install        # JS dependencies
flutter pub get     # Dart dependencies
```

## Dev mode

Starts Vite (HMR) and Flutter side by side:

```bash
pnpm dev          # macOS desktop
pnpm dev:ios      # iOS simulator
```

> `devServerUrl: 'http://localhost:5173'` in `lib/main.dart` makes Flutter load the app live
> from Vite instead of the bundled asset.

## Production build

```bash
# 1. Build the web app into assets/www/index.html
pnpm build

# 2. Comment out devServerUrl in lib/main.dart, then run Flutter
flutter run -d macos   # or -d ios / -d android
```

## Structure

| Path | Role |
|------|------|
| `lib/main.dart` | Entry point — `MaterialApp` + `InertiaWebView` |
| `lib/app_router.dart` | Routes: `GET /`, `POST /increment`, `/decrement`, `/reset` |
| `lib/counter_controller.dart` | Reads/writes count via `shared_preferences` |
| `src/pages/Counter/Index.vue` | Counter UI — buttons call `router.post(...)` |
| `src/main.ts` | Calls `setupNativeAdapter()` then `createInertiaApp()` |
| `vite.config.ts` | Builds to `assets/www/index.html` via `vite-plugin-singlefile` |
| `assets/www/index.html` | Built web app (gitignored — generate with `pnpm build`) |
