# flutter_inertia example

Demonstrates `flutter_inertia` with multiple examples: a counter, a notes CRUD app, and a local notification trigger.

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

Run these two commands in separate terminals:

```bash
# Terminal 1 — Vite dev server with HMR
pnpm dev

# Terminal 2 — Flutter
flutter run
```

> `devServerUrl: 'http://localhost:5173'` in `lib/main.dart` makes Flutter load the app live
> from Vite instead of the bundled asset.

## Production build

```bash
# 1. Build the web app into assets/www/index.html
pnpm build

# 2. Run Flutter in release mode — it will load the bundled asset automatically
flutter run --release
```

## Structure

| Path | Role |
|------|------|
| `lib/main.dart` | Entry point — `MaterialApp` + `InertiaWebView` |
| `lib/app_router.dart` | All route registrations |
| `lib/home_controller.dart` | Renders the home screen |
| `lib/counter_controller.dart` | Reads/writes count via `shared_preferences` |
| `lib/notes_controller.dart` | Full notes CRUD via `shared_preferences` |
| `lib/notification_controller.dart` | Triggers local notifications |
| `src/pages/Home/Index.vue` | Home screen linking to all examples |
| `src/pages/Counter/Index.vue` | Counter UI |
| `src/pages/Notes/` | Notes list, create, show, and edit pages |
| `src/pages/Notification/Index.vue` | Notification trigger UI |
| `src/main.ts` | Calls `setupNativeAdapter()` then `createInertiaApp()` |
| `vite.config.ts` | Builds to `assets/www/index.html` via `vite-plugin-singlefile` |
| `assets/www/index.html` | Built web app (gitignored — generate with `pnpm build`) |
