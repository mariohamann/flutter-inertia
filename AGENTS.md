# Flutter Inertia – Agent Knowledge Base

Lessons learned building and debugging this project. Read this before making changes.

---

## Architecture

```
Flutter (Dart)  ←→  JavaScriptChannel('nativeInertia')  ←→  Inertia.js v3 (Vue 3)
```

- **JS → Dart:** `nativeInertia.postMessage(JSON)` — method, url, data
- **Dart → JS:** `controller.runJavaScript(js)` — fires `CustomEvent('nativeInertia', { detail })`
- **Web adapter:** `www/src/inertia-native-adapter.ts` implements Inertia v3's `HttpClient` interface via `http.setClient()`
- **Dart router:** regex-based URI matching, `:param` style routes, no external package needed
- **Web build:** `vite-plugin-singlefile` → single `index.html` asset, loaded via `loadFlutterAsset()`

---

## Rules

### Redirects after mutations (store/update/destroy)
The adapter follows redirects internally — when `detail.redirect` is set, it sends a second `postToFlutter()` with `method: 'get'` and awaits another response. Never return a redirect payload directly to Inertia.

### Never use `window.confirm()` / `window.alert()` / `window.prompt()`
Silently blocked in WKWebView on macOS and iOS. Build Vue overlay components instead.

### Inertia v3 — implement `HttpClient`, not Axios interceptors
Use `http.setClient()` from `@inertiajs/core`. Axios is not present by default in v3.

### history API must be disabled in `setupNativeAdapter()`
`pushState` / `replaceState` are broken in `file://` WebViews. They are no-op'd in `setupNativeAdapter()` — do not remove this.

### Route method casing
Inertia v3 sends methods lowercase (`'get'`, `'delete'`, `'patch'`). The Dart router normalises with `.toUpperCase()` — keep this.

### macOS entitlements
`com.apple.security.network.client` must be in both `DebugProfile.entitlements` and `Release.entitlements` for any network access.

### Ruby for CocoaPods
Use Homebrew Ruby, not system Ruby (macOS 2.6.x is too old):
```bash
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
```

---

## Dev Workflow

```bash
# Build web → assets/www/index.html → copy to example/assets/www/
cd www && pnpm build:example

# Dev with HMR (set devServerUrl in example/lib/main.dart)
cd www && pnpm dev
# In main.dart: InertiaWebView(router: AppRouter(), devServerUrl: 'http://localhost:5173')

# Dart analysis
flutter analyze lib/ example/lib/

# Run on macOS
cd example && flutter run -d macos
```
