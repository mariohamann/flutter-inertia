# flutter_inertia

Use [Inertia.js](https://inertiajs.com) with Flutter — route Inertia navigation requests to Dart
handlers instead of an HTTP server.

## How it works

A Flutter `WebView` loads your Inertia.js web app (Vue, React, Svelte…). When Inertia makes a
navigation request, the `flutter-inertia-adapter` npm package intercepts it and passes it through
a JavaScript channel to Dart. Your router matches the request, runs a handler, and returns a
rendered page or redirect back to the web layer — all without a network server.

```
JS router.get('/notes') → nativeInertia channel → InertiaRouter.handleMessage()
    → handler returns Inertia.render(...) → WebView.runJavaScript() → page updates
```

## Installation

### Dart/Flutter

```yaml
# pubspec.yaml
dependencies:
  flutter_inertia: ^0.1.0
```

### JavaScript (any Inertia adapter)

```bash
npm install flutter-inertia-adapter
```

## Usage

### 1. Define your router

```dart
import 'package:flutter_inertia/flutter_inertia.dart';

class AppRouter extends InertiaRouter {
  @override
  void setupRoutes() {
    get('/', (req) async => Inertia.render(
      component: 'Home',
      props: {'message': 'Hello from Dart!'},
      url: '/',
    ));

    get('/notes/:id', (req) async {
      final id = req.param('id')!;
      return Inertia.render(component: 'Notes/Show', props: {'id': id}, url: req.url);
    });

    post('/notes', (req) async {
      // req.body contains the POST data
      return Inertia.redirect('/');
    });
  }
}
```

### 2. Add the widget

```dart
InertiaWebView(
  router: AppRouter(),
  // In debug mode, load from Vite dev server for HMR:
  devServerUrl: 'http://localhost:5173',
  // In production, loads assets/www/index.html by default
)
```

### 3. Set up the web side

```ts
// main.ts
import { setupNativeAdapter } from 'flutter-inertia-adapter';
import { createInertiaApp } from '@inertiajs/vue3'; // or react/svelte

setupNativeAdapter(); // must be called before createInertiaApp

createInertiaApp({ /* ... */ });
```

## API

### `InertiaRouter`

Subclass and implement `setupRoutes()`. Available methods: `get`, `post`, `put`, `patch`, `delete`.

### `InertiaRequest`

| Property | Type | Description |
|----------|------|-------------|
| `method` | `String` | HTTP method |
| `url` | `String` | Request path |
| `pathParams` | `Map<String, String>` | Extracted `:param` values |
| `queryParams` | `Map<String, String>` | Query string values |
| `body` | `Map<String, dynamic>` | POST/PATCH body |

`req.param('id')` and `req.query('q')` are convenience accessors.

### `Inertia.render({component, props, url})`

Returns a JS string that dispatches the Inertia page response into the WebView.

### `Inertia.redirect(url)`

Returns a JS string that triggers a client-side Inertia redirect.

### `InertiaWebView`

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `router` | `InertiaRouter` | required | Your router instance |
| `devServerUrl` | `String?` | `null` | Vite dev server URL (debug only) |
| `assetPath` | `String` | `'assets/www/index.html'` | Bundled HTML asset path |

## Example

See the [`example/`](example/) directory for a full macOS menu-bar app with Notes, System stats,
and Volume control pages.
