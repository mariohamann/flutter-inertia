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

**3. Create the page in `www/src/pages/Items/Index.vue`:**
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
- **Build**: `pnpm --filter ./www build:example` compiles the web app and copies it to
  `example/assets/www/index.html` for Flutter to bundle.

## Request shape (JS → Dart)
```json
{ "method": "GET", "url": "/items/42", "data": {}, "headers": {} }
```

## Response shape (Dart → JS, via CustomEvent detail)
```json
{ "component": "Items/Show", "props": { "id": "42" }, "url": "/items/42", "version": "flutter" }
```
