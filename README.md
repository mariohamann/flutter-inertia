# Solid Inertia Flutter

Flutter serves as the backend — platform events are the communication channel. This project integrates Inertia.js into a Flutter WebView so that any Inertia-compatible frontend framework (Vue, Svelte, React) can be driven by Dart/Flutter logic without a real HTTP server.

---

## Concept

[Inertia.js](https://inertiajs.com/) normally sits between a server-side framework (Laravel, Rails) and a frontend SPA. The "server" responds to XHR requests with JSON payloads describing which component to render and what props to pass.

This project replaces the HTTP server with **Flutter**. The WebView's JavaScript layer intercepts every Inertia navigation, tunnels it to Dart via a platform bridge, Dart matches the request against a route table and executes a controller, and the response fires back as a custom DOM event. Inertia.js receives a well-formed response and re-renders the component — never knowing there was no network involved.

```
┌─ Inertia.js (Web) ──────────────────────────────────┐
│  Link.visit() / router.get("/foo/1")                │
│       ↓                                              │
│  Axios request interceptor                          │
│  → sends to native via JS channel                   │
│  → awaits 'native-inertia' CustomEvent             │
└──────┬──────────────────────────────────────────────┘
       │ JavaScriptChannel.postMessage(JSON)
       ↓
┌─ Flutter / Dart ────────────────────────────────────┐
│  InertiaRouter receives message                     │
│  → matches method + URL pattern                     │
│  → extracts URL params                              │
│  → calls controller                                 │
│  → controller accesses platform services            │
│    (sensors, storage, BLE, camera, …)               │
│  → Inertia.render(component, props, url)            │
│  → evaluates JS: dispatchEvent('native-inertia')   │
└──────┬──────────────────────────────────────────────┘
       │ CustomEvent { component, props, url }
       ↓
┌─ Inertia.js (Web) ──────────────────────────────────┐
│  Promise resolves → Inertia response structure      │
│  → component re-renders with new props              │
└─────────────────────────────────────────────────────┘
```

---

## Inspiration: Chronological Journey

The `inspiration/` folder contains three projects that informed this architecture, built from simplest to most complete.

### 1. `ransominder-flutter` — Foundation

The earliest experiment. A plain Flutter `webview_flutter` wrapper that establishes the **bidirectional communication primitive**:

- **Dart → JS:** `controller.runJavaScript('window.dispatchEvent(new CustomEvent(...))')`
- **JS → Dart:** `window.webkit.messageHandlers['Channel'].postMessage(msg)` mapped to `JavaScriptChannel` callbacks in Dart

There is no Inertia.js here yet. Two channels (`Counter`, `Toaster`) show the raw mechanics: JavaScript notifies Dart, Dart mutates state, Dart fires a custom event back. This is the exact same primitive the full Inertia adapter is built on.

**Key takeaway:** `JavaScriptChannel` + `runJavaScript` is sufficient for full duplex communication.

### 2. `swift-native-inertia-boilerplate-main` — The Full Adapter

A complete, generic Inertia.js adapter written in Swift for iOS (WKWebView). This is the reference architecture — directly translatable to Dart/Flutter.

#### Swift layer

| File | Role |
|------|------|
| `Inertia/Inertia.swift` | Static helpers: `setup()` configures the WebView; `render()` builds the JS `CustomEvent` dispatcher |
| `Inertia/InertiaRouter.swift` | `WKScriptMessageHandler` that receives JSON from JS, matches the URL against registered routes using `NSRegularExpression`, extracts `:param` values, calls route callbacks |
| `AppRouter.swift` | Concrete route table — registers GET/POST/… routes as closures |
| `RootController.swift` | Business logic — calls `Inertia.render(component:props:url:)` and returns the JS string |

**`Inertia.render` output:**
```swift
static func render(component: String, props: [String: Any], url: String) -> String {
  let response = JSON(["component": component, "props": props, "url": url])
  return "window.dispatchEvent(new CustomEvent('native-inertia', { detail: \(response.rawString()!) }));"
}
```

The router calls `webView.evaluateJavaScript(response)` to fire the event.

#### Web layer (`www/src/js/native-inertia.mjs`)

An **Axios interceptor** plugged into Inertia.js:

1. **Request phase** — every outgoing Axios request is converted to a deliberately thrown error (nothing reaches the network).
2. **Response phase** — the error handler extracts the original request config, posts it to the native bridge, then awaits a `Promise` that resolves on the next `native-inertia` `CustomEvent`.
3. The resolved value is shaped into an Inertia-compatible response and returned through the Axios pipeline.

```js
// Request interceptor: block all real requests
axios.interceptors.request.use(config => {
  const mockError = new Error();
  mockError.response = { data: {}, status: 200 };
  mockError.config = config;
  return Promise.reject(mockError);
});

// Response interceptor: route through native
axios.interceptors.response.use(null, async (mockError) => {
  window.webkit?.messageHandlers['native-inertia']
    ?.postMessage(JSON.stringify(mockError.config));

  const response = await new Promise(resolve => {
    window.addEventListener('native-inertia', e => resolve(e.detail), { once: true });
  });

  mockError.config.data = { ...response, version: 'current' };
  return mockError.config;
});
```

This pattern is **framework-agnostic** — Vue 3 is used here but any Inertia adapter (Svelte, React) works unchanged.

**Dev vs. production:** The Swift layer loads `http://localhost:5173` in dev mode and a bundled `index.html` from the app package in production.

### 3. `swift-native-inertia-feat_compass` — Real-World Example

Extends the boilerplate with a live sensor integration to prove the architecture works with real platform data.

#### What's new

**`CompassHeading.swift`** — A `CLLocationManager` delegate wrapped as a Combine `@Published` observable:
```swift
func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
  self.degrees = newHeading.magneticHeading
}
```

**`RootController.swift`** — reads the current heading on every request:
```swift
static let manager = CompassHeading()

static func index() -> String {
  return Inertia.render(
    component: "Root/Index",
    props: ["degree": manager.degrees],
    url: "/"
  )
}
```

**`www-svelte/`** — demonstrates a Svelte frontend consuming the props:
```svelte
<script lang="ts">
  export let degree: string;   // injected by Inertia from native props

  router.on("success", () => {
    document.getElementById("compass").style.transform = `rotate(${degree * -1}deg)`;
  });
</script>
```

The Svelte component polls the native layer by calling `router.get("/")`. Each response carries the latest compass heading as a prop. No WebSocket, no polling timer on the web side — the web only gets data when it asks for it.

**`ContentView.swift`** also adds a `TabView` with both a WebView tab (Inertia-powered) and a pure SwiftUI tab — showing that native UI and the web layer can coexist and share the same data layer.

**Key takeaway:** Controllers are stateful — they can call any platform service and serialize the result into Inertia props on every navigation. This turns Inertia's request/response cycle into a general-purpose native data pipe.

---

## Architecture Summary

### Communication primitives

| Direction | Mechanism |
|-----------|-----------|
| JS → Flutter | `JavaScriptChannel` (Flutter) / `WKScriptMessageHandler` (iOS) |
| Flutter → JS | `WebViewController.runJavaScript()` + `CustomEvent` |

### Request payload (JS → native)
```json
{
  "method": "GET",
  "url": "/posts/42",
  "data": {}
}
```

### Response payload (native → JS, via CustomEvent detail)
```json
{
  "component": "Posts/Show",
  "props": { "title": "Hello", "body": "..." },
  "url": "/posts/42",
  "version": "current"
}
```

### Route matching

Routes are registered as `METHOD /path/:param` patterns. The router converts them to regular expressions, matches incoming URLs, extracts named parameters, and invokes the registered callback with an `InertiaRequest` object.

### Controllers

Controllers are plain functions/classes that have access to the full Flutter platform. They receive the parsed request and return an Inertia render call. They can read sensors, query local databases, call platform plugins, or perform any async Dart operation before responding.

### Web asset loading

| Mode | Source |
|------|--------|
| Development | Dev server (`http://localhost:5173`) with hot-module replacement |
| Production | Bundled `index.html` loaded via `loadFlutterAsset` / file URL |

---

## Flutter Implementation Plan

Porting the Swift adapter to Dart requires the following components:

1. **`InertiaRouter` (Dart)** — registers `JavaScriptChannel('native-inertia', ...)`, receives JSON messages, delegates to route matching
2. **Route registry** — stores `(method, pattern)` → callback mappings; converts `:param` paths to named-group regexes
3. **`InertiaRequest`** — value object carrying method, url, query params, body, and extracted path params
4. **`Inertia.render()`** — serializes `{component, props, url}` to JSON, wraps in `dispatchEvent` JS, calls `controller.runJavaScript()`
5. **`native-inertia.mjs`** (web) — the same Axios interceptor from the Swift boilerplate, unchanged (it is already framework-agnostic)
6. **`WebViewWidget` wrapper** — Flutter widget that creates a `WebViewController`, injects the JS channel, and loads the asset or dev server URL
7. **Platform service access** — controllers import Flutter plugins (sensors, SQLite, BLE, etc.) and return their output as props

---

## Folder Structure

```
inspiration/
  ransominder-flutter/          # Flutter WebView + JS channel primitive
  swift-native-inertia-boilerplate-main/  # Full Inertia adapter in Swift (reference)
  swift-native-inertia-feat_compass/      # Real-world sensor integration + Svelte
lib/                            # Flutter Inertia adapter (to be built)
```
