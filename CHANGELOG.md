## 0.2.0

- Add `sharedProps()` to `InertiaRouter` — override to provide props automatically merged into every `Inertia.render()` response. Page-level props take precedence on key collision (shallow merge).

## 0.1.1

- Improve example

## 0.1.0

- Initial release
- `InertiaRouter` — abstract base class for defining routes
- `InertiaRequest` — value object for incoming navigation requests
- `InertiaRoute` — route pattern matching with `:param` segments
- `InertiaWebView` — Flutter widget hosting the Inertia.js web app
- `Inertia.render()` / `Inertia.redirect()` — response helpers
