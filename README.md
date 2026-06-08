# flutter_inertia

[Inertia.js](https://inertiajs.com) for Flutter. Flutter acts as the backend — Dart handlers
respond to navigation requests instead of an HTTP server.

## How it works

Inertia.js normally sits between a server framework and a frontend SPA, exchanging JSON over XHR.
This package replaces the server with Flutter: a `WebView` runs your Inertia app, the
`flutter-inertia-adapter` intercepts every navigation and tunnels it through a
`JavaScriptChannel` to Dart, your router dispatches it to a handler, and the response fires back
as a `CustomEvent` — Inertia never knows there was no network.

```
router.get('/') ──► nativeInertia.postMessage(JSON)
                         │
                    InertiaRouter.handleMessage()
                         │
                    handler ──► Inertia.render(component, props, url)
                         │
                    controller.runJavaScript(js)
                         │
                    CustomEvent('nativeInertia') ──► Inertia re-renders
```

## Installation

```yaml
# pubspec.yaml
dependencies:
  flutter_inertia: ^0.1.0
```

```bash
npm install flutter-inertia-adapter
```

## Setup

**Flutter** — drop `InertiaWebView` anywhere in your widget tree:

```dart
InertiaWebView(
  router: AppRouter(),
  devServerUrl: 'http://localhost:5173', // omit in production
)
```

**Web** — call `setupNativeAdapter()` before `createInertiaApp()`:

```ts
import { setupNativeAdapter } from 'flutter-inertia-adapter'
import { createInertiaApp } from '@inertiajs/vue3'

setupNativeAdapter()
createInertiaApp({ /* ... */ })
```

## Routing

Subclass `InertiaRouter` and register routes in `setupRoutes()`:

```dart
class AppRouter extends InertiaRouter {
  @override
  void setupRoutes() {
    get('/', (req) => CounterController.index());
    post('/increment', (req) => CounterController.increment());
    get('/items/:id', (req) => ItemController.show(req.param('id')!));
    post('/search', (req) => SearchController.query(req.query('q') ?? ''));
  }
}
```

Routes support `:param` segments. `req.param('name')` reads path params, `req.query('name')`
reads query params, `req.body` is the POST/PATCH payload.

## Handlers

A handler is any `async` function that returns a JS string from `Inertia.render()` or
`Inertia.redirect()`:

```dart
// Render a page
return Inertia.render(
  component: 'Counter/Index',   // maps to src/pages/Counter/Index.vue
  props: {'count': 42},
  url: '/',
);

// Redirect after a mutation
return Inertia.redirect('/');
```

The redirects are followed transparently — the adapter makes the follow-up GET automatically,
so the web layer always receives a rendered page, never a bare redirect.

## Pages

A page is a plain component that receives props injected by Inertia:

```vue
<script setup lang="ts">
import { router } from '@inertiajs/vue3'
defineProps<{ count: number }>()
</script>

<template>
  <button @click="router.post('/increment')">+</button>
  <span>{{ count }}</span>
</template>
```

`router.get/post/patch/delete` trigger a new Inertia request, which flows back through Flutter.
The component name passed to `Inertia.render()` maps directly to `src/pages/<name>.vue`.

## API

**`InertiaRequest`**

| Property | Type | Description |
|---|---|---|
| `method` | `String` | HTTP method (uppercased) |
| `url` | `String` | Request path |
| `pathParams` | `Map<String, String>` | `:param` values |
| `queryParams` | `Map<String, String>` | Query string values |
| `body` | `Map<String, dynamic>` | POST/PATCH body |

**`Inertia.render({component, props, url})`** — renders a page into the WebView.  
**`Inertia.redirect(url)`** — triggers a follow-up GET to `url`.  
**`InertiaWebView({router, devServerUrl?, assetPath?})`** — the Flutter widget.

## Example

See [`example/`](example/) — a persistent counter backed by `shared_preferences`.

---

## AGENTS.md

Copy this into your project's `AGENTS.md` to give AI assistants full context.

````markdown
# flutter_inertia

This project uses `flutter_inertia` — Flutter acts as the Inertia.js backend.
Navigation requests from the web layer are handled by Dart instead of an HTTP server.

## Mental model

Inertia.js intercepts every navigation (link clicks, `router.get/post/…`) and makes an XHR
request. Normally a Laravel/Rails server responds. Here, `flutter-inertia-adapter` intercepts
that request, posts it through `window.nativeInertia.postMessage(JSON)` to Flutter, waits for
a `CustomEvent('nativeInertia')`, and returns the payload as an Inertia response.

On the Flutter side, `InertiaRouter.handleMessage()` receives the JSON, matches the route,
calls the handler, and evaluates the returned JS string in the WebView via `runJavaScript()`.

## Adding a route

**1. Register it in `lib/app_router.dart`:**
```dart
get('/items', (req) => ItemController.index());
post('/items', (req) => ItemController.store(req.body));
get('/items/:id', (req) => ItemController.show(req.param('id')!));
patch('/items/:id', (req) => ItemController.update(req.param('id')!, req.body));
delete('/items/:id', (req) => ItemController.destroy(req.param('id')!));
```

**2. Write the handler in `lib/item_controller.dart`:**
```dart
import 'package:flutter_inertia/flutter_inertia.dart';

class ItemController {
  static Future<String> index() async {
    // access any Flutter plugin, local storage, sensors, etc.
    return Inertia.render(
      component: 'Items/Index',
      props: {'items': []},
      url: '/',
    );
  }

  static Future<String> store(Map<String, dynamic> body) async {
    // mutate, then redirect — the adapter follows it automatically
    return Inertia.redirect('/items');
  }
}
```

**3. Create the page in `example/src/pages/Items/Index.vue`:**
```vue
<script setup lang="ts">
import { router } from '@inertiajs/vue3'
defineProps<{ items: { id: string; name: string }[] }>()
</script>

<template>
  <ul>
    <li v-for="item in items" :key="item.id">
      {{ item.name }}
      <button @click="router.delete(`/items/${item.id}`)">Delete</button>
    </li>
  </ul>
  <button @click="router.post('/items', { name: 'New' })">Add</button>
</template>
```

## Rules

- **After mutations, always return `Inertia.redirect()`**, not a render. The adapter follows the
  redirect with a GET and returns the rendered page to Inertia automatically.
- **Never use `window.alert/confirm/prompt()`** — silently blocked in WKWebView.
- **`history.pushState/replaceState` are no-ops** — patched out by `setupNativeAdapter()`.
  Do not rely on browser history; use Inertia's router for all navigation.
- **Methods arrive lowercase** (`'get'`, `'post'`). The router normalises them — don't change this.
- **Inertia v3 uses `HttpClient`, not Axios interceptors.** The adapter calls `http.setClient()`
  from `@inertiajs/core` — there is no Axios in this stack.
- **Dev**: `devServerUrl: 'http://localhost:5173'` enables HMR. Remove or leave `null` for
  production; the widget then loads `assets/www/index.html`.
- **Build**: `pnpm --filter ./example build:example` compiles the web app and copies it to
  `example/assets/www/index.html` for Flutter to bundle.

## Request shape (JS → Dart)
```json
{ "method": "GET", "url": "/items/42", "data": {}, "headers": {} }
```

## Response shape (Dart → JS, via CustomEvent detail)
```json
{ "component": "Items/Show", "props": { "id": "42" }, "url": "/items/42", "version": "flutter" }
```
````
