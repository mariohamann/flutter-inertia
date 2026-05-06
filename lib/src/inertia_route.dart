import 'inertia_request.dart';

/// Callback type for route handlers.
/// Return the JS string produced by [Inertia.render] or a redirect JS string.
typedef InertiaRouteHandler = Future<String> Function(InertiaRequest request);

/// A single registered route: method + URI pattern → handler.
class InertiaRoute {
  final String method;
  final String pattern;
  final RegExp _regex;
  final List<String> _paramNames;
  final InertiaRouteHandler handler;

  InertiaRoute._({
    required this.method,
    required this.pattern,
    required RegExp regex,
    required List<String> paramNames,
    required this.handler,
  })  : _regex = regex,
        _paramNames = paramNames;

  factory InertiaRoute({
    required String method,
    required String pattern,
    required InertiaRouteHandler handler,
  }) {
    final paramNames = <String>[];
    // Convert :param segments to named regex groups.
    // e.g. /notes/:id/edit → ^/notes/(?<id>[^/]+)/edit$
    final regexStr = pattern
        .replaceAllMapped(RegExp(r':([a-zA-Z_][a-zA-Z0-9_]*)'), (m) {
          paramNames.add(m.group(1)!);
          return '(?<${m.group(1)}>[^/]+)';
        })
        .replaceAll('/', r'\/')
        // Remove the double-escape on \/ we just added for clarity
        .replaceAll(r'\/', '/');
    final regex = RegExp('^$regexStr\$');
    return InertiaRoute._(
      method: method.toUpperCase(),
      pattern: pattern,
      regex: regex,
      paramNames: paramNames,
      handler: handler,
    );
  }

  /// Try matching [method] and [path]. Returns an [InertiaRequest] if matched.
  InertiaRequest? tryMatch(
    String method,
    String path,
    Map<String, String> queryParams,
    Map<String, dynamic> body,
  ) {
    if (this.method != method.toUpperCase()) return null;
    final match = _regex.firstMatch(path);
    if (match == null) return null;
    final pathParams = <String, String>{};
    for (final name in _paramNames) {
      final val = match.namedGroup(name);
      if (val != null) pathParams[name] = val;
    }
    return InertiaRequest(
      method: method,
      url: path,
      pathParams: pathParams,
      queryParams: queryParams,
      body: body,
    );
  }
}
