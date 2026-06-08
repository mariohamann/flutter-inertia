# example

A counter app demonstrating `flutter_inertia` — a persistent counter backed by
`shared_preferences`, with increment / decrement / reset actions driven by Inertia.js.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- [Node.js](https://nodejs.org/) (18+) and [pnpm](https://pnpm.io/installation)

```bash
npm install -g pnpm
```

## Setup

From the **repo root** (not the `example/` directory):

```bash
pnpm install
```

This installs all JS dependencies for the web layer and the npm adapter package.

## Run

**Dev mode** — Vite HMR + Flutter side by side (from repo root):

```bash
pnpm dev          # macOS
pnpm dev:ios      # iOS simulator
```

**Production build** — compile web assets then run Flutter (from repo root):

```bash
pnpm build                               # builds example/assets/www/index.html
cd example && flutter run -d macos       # or -d ios / -d android
```

## Structure

| File | Role |
|------|------|
| `lib/main.dart` | Entry point — plain `MaterialApp` + `InertiaWebView` |
| `lib/app_router.dart` | Route table: `GET /`, `POST /increment`, `/decrement`, `/reset` |
| `lib/counter_controller.dart` | Reads/writes count via `shared_preferences` |
| `src/` | Web source (Vue 3 + Inertia.js) |
| `assets/www/index.html` | Built web app (generated — run `pnpm build`) |
