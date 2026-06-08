# www

The web frontend for the `flutter_inertia` example. Vue 3 + Inertia.js, built to a single
`index.html` via `vite-plugin-singlefile` and loaded as a Flutter asset.

## Dev

```bash
pnpm dev          # Vite dev server at http://localhost:5173 (HMR)
pnpm build        # Build to ../assets/www/index.html
pnpm build:example  # Build + copy to ../example/assets/www/index.html
```

## Structure

| Path | Role |
|------|------|
| `src/main.ts` | Bootstrap — calls `setupNativeAdapter()` then `createInertiaApp()` |
| `src/pages/Counter/Index.vue` | Counter page — props: `{ count: number }` |
| `src/style.css` | Minimal base styles (no framework) |
| `vite.config.ts` | Vite config — singlefile build, alias for `flutter-inertia-adapter` |

The `flutter-inertia-adapter` package (`packages/flutter-inertia-adapter/`) is resolved
directly from source via the Vite alias — no pre-build needed in development.
