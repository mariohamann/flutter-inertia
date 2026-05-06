import 'dart:convert';

/// Core Inertia helpers – mirrors Inertia.swift from the Swift boilerplate.
class Inertia {
  Inertia._();

  /// Build the JavaScript string that dispatches an Inertia page response
  /// as a CustomEvent. Evaluate this string in the WebView.
  ///
  /// Example:
  /// ```dart
  /// final js = Inertia.render(
  ///   component: 'Notes/Index',
  ///   props: {'notes': notes.map((n) => n.toJson()).toList()},
  ///   url: '/',
  /// );
  /// controller.runJavaScript(js);
  /// ```
  static String render({
    required String component,
    required Map<String, dynamic> props,
    required String url,
  }) {
    final payload = json.encode({
      'component': component,
      'props': props,
      'url': url,
      'version': 'flutter',
    });
    return "window.dispatchEvent(new CustomEvent('nativeInertia', { detail: $payload }));";
  }

  /// Build a redirect response that triggers the Inertia client to visit
  /// [url] after the current request completes.
  static String redirect(String url) {
    final payload = json.encode({'redirect': url});
    return "window.dispatchEvent(new CustomEvent('nativeInertia', { detail: $payload }));";
  }
}
