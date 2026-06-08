# flutter-inertia-adapter

Framework-agnostic [Inertia.js](https://inertiajs.com) HTTP adapter for Flutter WebViews.
Intercepts Inertia navigation requests and routes them through a `JavaScriptChannel` to Dart
instead of making real network requests — no HTTP server needed.

Works with any Inertia frontend adapter: Vue, React, Svelte, etc.

## Usage

```ts
import { setupNativeAdapter } from 'flutter-inertia-adapter'
import { createInertiaApp } from '@inertiajs/vue3'

setupNativeAdapter() // must be called before createInertiaApp
createInertiaApp({ /* ... */ })
```

## Documentation

See [github.com/mariohamann/flutter-inertia](https://github.com/mariohamann/flutter-inertia) for
full setup instructions, routing guide, and a copy-paste `AGENTS.md` for AI assistants.
