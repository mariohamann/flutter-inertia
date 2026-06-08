# example

A counter app demonstrating `flutter_inertia` — a persistent counter backed by
`shared_preferences`, with increment / decrement / reset actions driven by Inertia.js.

## Run

```bash
# Dev (HMR web + Flutter side by side, from repo root)
pnpm dev

# Or run Flutter alone (production asset)
pnpm --filter ./www build:example
cd example && flutter run -d macos   # or -d ios / -d android
```

## Structure

| File | Role |
|------|------|
| `lib/main.dart` | Entry point — plain `MaterialApp` + `InertiaWebView` |
| `lib/app_router.dart` | Route table: `GET /`, `POST /increment`, `/decrement`, `/reset` |
| `lib/counter_controller.dart` | Reads/writes count via `shared_preferences` |
| `assets/www/index.html` | Built web app (generated — run `pnpm build:example`) |
