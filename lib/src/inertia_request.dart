/// Represents an incoming navigation request from the Inertia.js web layer.
class InertiaRequest {
  final String method;
  final String url;
  final Map<String, String> pathParams;
  final Map<String, String> queryParams;
  final Map<String, dynamic> body;

  const InertiaRequest({
    required this.method,
    required this.url,
    this.pathParams = const {},
    this.queryParams = const {},
    this.body = const {},
  });

  /// Convenience: get a path parameter by name.
  String? param(String name) => pathParams[name];

  /// Convenience: get a query parameter by name.
  String? query(String name) => queryParams[name];

  @override
  String toString() =>
      'InertiaRequest($method $url params=$pathParams query=$queryParams)';
}
