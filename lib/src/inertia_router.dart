import 'dart:async';
import 'dart:convert';

import 'inertia_route.dart';

export 'inertia_request.dart';
export 'inertia_route.dart';

/// Base class for application routers.
///
/// Subclass this and override [setupRoutes] to register your routes:
///
/// ```dart
/// class AppRouter extends InertiaRouter {
///   @override
///   void setupRoutes() {
///     get('/', (req) async => NotesController.index());
///     get('/notes/:id/edit', (req) async => NotesController.edit(req.param('id')!));
///     post('/notes', (req) async => NotesController.store(req.body));
///   }
/// }
/// ```
abstract class InertiaRouter {
  final List<InertiaRoute> _routes = [];

  /// Called once before the first request is handled.
  void setupRoutes();

  void get(String pattern, InertiaRouteHandler handler) =>
      _addRoute('GET', pattern, handler);

  void post(String pattern, InertiaRouteHandler handler) =>
      _addRoute('POST', pattern, handler);

  void put(String pattern, InertiaRouteHandler handler) =>
      _addRoute('PUT', pattern, handler);

  void patch(String pattern, InertiaRouteHandler handler) =>
      _addRoute('PATCH', pattern, handler);

  void delete(String pattern, InertiaRouteHandler handler) =>
      _addRoute('DELETE', pattern, handler);

  void _addRoute(String method, String pattern, InertiaRouteHandler handler) {
    _routes
        .add(InertiaRoute(method: method, pattern: pattern, handler: handler));
  }

  /// Parse and dispatch a raw JSON message from the JavaScript bridge.
  ///
  /// Returns the JS string to evaluate in the WebView.
  Future<String> handleMessage(String rawJson) async {
    Map<String, dynamic> data;
    try {
      data = json.decode(rawJson) as Map<String, dynamic>;
    } catch (_) {
      return "console.warn('[flutter_inertia] Invalid message from JS bridge: ${rawJson.replaceAll("'", "\\'")}');";
    }

    final method = (data['method'] as String? ?? 'GET').toUpperCase();
    final rawUrl = data['url'] as String? ?? '/';
    final body = (data['data'] as Map<String, dynamic>?) ?? {};

    if (_routes.isEmpty) setupRoutes();

    return await _dispatchWithCycleGuard(method, rawUrl, body, {});
  }

  Future<String> _dispatchWithCycleGuard(
    String method,
    String rawUrl,
    Map<String, dynamic> body,
    Set<String> visited,
  ) async {
    final key = '${method.toUpperCase()} $rawUrl';
    if (visited.contains(key)) {
      return "console.warn('[flutter_inertia] Redirect loop detected: $key');";
    }

    final js = await _dispatch(method, rawUrl, body);

    final redirectTarget = _extractRedirectUrl(js);
    if (redirectTarget != null) {
      return await _dispatchWithCycleGuard(
          'GET', redirectTarget, {}, {...visited, key});
    }

    return js;
  }

  /// Override this method to provide props that are automatically merged into
  /// every [Inertia.render] response, before page-level props.
  ///
  /// Shared props are shallow-merged: page props take precedence over shared
  /// props when the same top-level key appears in both.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<Map<String, dynamic>> sharedProps() async {
  ///   return {
  ///     'auth': {'displayName': await AccountController.currentDisplayName()},
  ///   };
  /// }
  /// ```
  Future<Map<String, dynamic>> sharedProps() async => {};

  Future<String> _dispatch(
      String method, String rawUrl, Map<String, dynamic> body) async {
    final uri = Uri.tryParse(rawUrl) ?? Uri.parse('/');
    final path = uri.path.isEmpty ? '/' : uri.path;
    final queryParams = uri.queryParameters;

    for (final route in _routes) {
      final request = route.tryMatch(method, path, queryParams, body);
      if (request != null) {
        final js = await route.handler(request);
        return await _injectSharedProps(js);
      }
    }
    return _notFound(path);
  }

  /// Merges [sharedProps] into a `Inertia.render` JS response.
  /// Redirect and error responses are passed through unchanged.
  Future<String> _injectSharedProps(String js) async {
    // Only render responses carry a CustomEvent payload with a 'component' key.
    final match = RegExp(
      r"new CustomEvent\('nativeInertia',\s*\{\s*detail:\s*(\{.*\})\s*\}\)",
      dotAll: true,
    ).firstMatch(js);
    if (match == null) return js;

    Map<String, dynamic> payload;
    try {
      payload = json.decode(match.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      return js;
    }

    // Only render responses have a 'component' key; redirects only have 'redirect'.
    if (!payload.containsKey('component')) return js;

    final shared = await sharedProps();
    if (shared.isEmpty) return js;

    final pageProps = (payload['props'] as Map<String, dynamic>?) ?? {};
    // Page props override shared props at the top level.
    payload['props'] = {...shared, ...pageProps};

    return "window.dispatchEvent(new CustomEvent('nativeInertia', { detail: ${json.encode(payload)} }));";
  }

  /// Extracts the redirect URL from a `Inertia.redirect()` JS string, or null.
  String? _extractRedirectUrl(String js) {
    final match = RegExp(r'"redirect"\s*:\s*"([^"]+)"').firstMatch(js);
    return match?.group(1);
  }

  String _notFound(String path) {
    return "console.warn('[flutter_inertia] No route matched: $path');";
  }
}
