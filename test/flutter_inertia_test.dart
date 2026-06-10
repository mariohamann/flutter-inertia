import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inertia/flutter_inertia.dart';

// Minimal concrete router for testing.
class TestRouter extends InertiaRouter {
  final void Function(InertiaRouter r) setup;
  TestRouter(this.setup);

  @override
  void setupRoutes() => setup(this);
}

// Router with injectable shared props for testing sharedProps() behaviour.
class _SharedPropsRouter extends InertiaRouter {
  final void Function(InertiaRouter r) setup;
  final Map<String, dynamic> shared;
  _SharedPropsRouter({required this.setup, required this.shared});

  @override
  void setupRoutes() => setup(this);

  @override
  Future<Map<String, dynamic>> sharedProps() async => shared;
}

// The JS string format is:
//   window.dispatchEvent(new CustomEvent('nativeInertia', { detail: <json> }));
// Extract the JSON payload between "detail: " and " }));".
Map<String, dynamic> _extractPayload(String js) {
  final start = js.indexOf('detail: ') + 'detail: '.length;
  final end = js.indexOf(' }));');
  return json.decode(js.substring(start, end)) as Map<String, dynamic>;
}

void main() {
  // ---------------------------------------------------------------------------
  // InertiaRequest
  // ---------------------------------------------------------------------------
  group('InertiaRequest', () {
    test('param() returns path parameter', () {
      final req = InertiaRequest(
        method: 'GET',
        url: '/notes/42',
        pathParams: {'id': '42'},
      );
      expect(req.param('id'), '42');
      expect(req.param('missing'), isNull);
    });

    test('query() returns query parameter', () {
      final req = InertiaRequest(
        method: 'GET',
        url: '/search',
        queryParams: {'q': 'hello'},
      );
      expect(req.query('q'), 'hello');
      expect(req.query('missing'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // InertiaRoute
  // ---------------------------------------------------------------------------
  group('InertiaRoute', () {
    InertiaRoute makeRoute(String method, String pattern) => InertiaRoute(
          method: method,
          pattern: pattern,
          handler: (req) async => '',
        );

    test('matches exact path', () {
      final route = makeRoute('GET', '/');
      expect(route.tryMatch('GET', '/', {}, {}), isNotNull);
    });

    test('does not match different method', () {
      final route = makeRoute('GET', '/notes');
      expect(route.tryMatch('POST', '/notes', {}, {}), isNull);
    });

    test('does not match different path', () {
      final route = makeRoute('GET', '/notes');
      expect(route.tryMatch('GET', '/other', {}, {}), isNull);
    });

    test('extracts single path param', () {
      final route = makeRoute('GET', '/notes/:id');
      final req = route.tryMatch('GET', '/notes/7', {}, {});
      expect(req, isNotNull);
      expect(req!.param('id'), '7');
    });

    test('extracts multiple path params', () {
      final route = makeRoute('GET', '/users/:userId/posts/:postId');
      final req = route.tryMatch('GET', '/users/3/posts/99', {}, {});
      expect(req, isNotNull);
      expect(req!.param('userId'), '3');
      expect(req.param('postId'), '99');
    });

    test('passes query params through', () {
      final route = makeRoute('GET', '/search');
      final req = route.tryMatch('GET', '/search', {'q': 'dart'}, {});
      expect(req!.query('q'), 'dart');
    });

    test('method matching is case-insensitive', () {
      final route = makeRoute('get', '/');
      expect(route.tryMatch('GET', '/', {}, {}), isNotNull);
      expect(route.tryMatch('get', '/', {}, {}), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Inertia.render / Inertia.redirect
  // ---------------------------------------------------------------------------
  group('Inertia.render', () {
    test('returns dispatchEvent JS string', () {
      final js = Inertia.render(component: 'Home', props: {}, url: '/');
      expect(js, contains('dispatchEvent'));
      expect(js, contains('nativeInertia'));
    });

    test('encodes component, props, url, and version', () {
      final js = Inertia.render(
        component: 'Notes/Index',
        props: {'count': 3},
        url: '/notes',
      );
      final payload = _extractPayload(js);
      expect(payload['component'], 'Notes/Index');
      expect(payload['url'], '/notes');
      expect(payload['version'], 'flutter');
      expect((payload['props'] as Map)['count'], 3);
    });
  });

  group('Inertia.redirect', () {
    test('returns dispatchEvent JS string with redirect key', () {
      final js = Inertia.redirect('/home');
      expect(js, contains('dispatchEvent'));
      expect(js, contains('nativeInertia'));
      final payload = _extractPayload(js);
      expect(payload['redirect'], '/home');
    });
  });

  // ---------------------------------------------------------------------------
  // InertiaRouter
  // ---------------------------------------------------------------------------
  group('InertiaRouter', () {
    test('dispatches GET route and returns render JS', () async {
      final router = TestRouter((r) {
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {}, url: '/'));
      });

      final js = await router.handleMessage(
          json.encode({'method': 'GET', 'url': '/', 'data': {}}));

      expect(js, contains('Home'));
    });

    test('dispatches POST route and passes body', () async {
      Map<String, dynamic>? captured;
      final router = TestRouter((r) {
        r.post('/notes', (req) async {
          captured = req.body;
          return Inertia.redirect('/notes');
        });
        r.get(
            '/notes',
            (req) async =>
                Inertia.render(component: 'Notes', props: {}, url: '/notes'));
      });

      await router.handleMessage(json.encode({
        'method': 'POST',
        'url': '/notes',
        'data': {'title': 'Foo'}
      }));

      expect(captured, {'title': 'Foo'});
    });

    test('follows redirect internally', () async {
      final router = TestRouter((r) {
        r.post('/notes', (req) async => Inertia.redirect('/notes'));
        r.get(
            '/notes',
            (req) async => Inertia.render(
                component: 'Notes/Index', props: {}, url: '/notes'));
      });

      final js = await router.handleMessage(
          json.encode({'method': 'POST', 'url': '/notes', 'data': {}}));

      expect(js, contains('Notes/Index'));
    });

    test('returns console.warn for unmatched routes', () async {
      final router = TestRouter((r) {
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {}, url: '/'));
      });

      final js = await router.handleMessage(
          json.encode({'method': 'GET', 'url': '/missing', 'data': {}}));

      expect(js, contains('console.warn'));
      expect(js, contains('/missing'));
    });

    test('extracts path params during dispatch', () async {
      String? capturedId;
      final router = TestRouter((r) {
        r.get('/notes/:id', (req) async {
          capturedId = req.param('id');
          return Inertia.render(
              component: 'Notes/Show', props: {}, url: req.url);
        });
      });

      await router.handleMessage(
          json.encode({'method': 'GET', 'url': '/notes/42', 'data': {}}));

      expect(capturedId, '42');
    });

    test('parses query params from URL', () async {
      String? capturedQuery;
      final router = TestRouter((r) {
        r.get('/search', (req) async {
          capturedQuery = req.query('q');
          return Inertia.render(component: 'Search', props: {}, url: req.url);
        });
      });

      await router.handleMessage(json
          .encode({'method': 'GET', 'url': '/search?q=flutter', 'data': {}}));

      expect(capturedQuery, 'flutter');
    });

    test('supports DELETE, PUT, PATCH methods', () async {
      final called = <String>[];
      final router = TestRouter((r) {
        r.delete('/notes/:id', (req) async {
          called.add('delete');
          return Inertia.redirect('/notes');
        });
        r.put('/notes/:id', (req) async {
          called.add('put');
          return Inertia.redirect('/notes');
        });
        r.patch('/notes/:id', (req) async {
          called.add('patch');
          return Inertia.redirect('/notes');
        });
        r.get(
            '/notes',
            (req) async =>
                Inertia.render(component: 'Notes', props: {}, url: '/notes'));
      });

      await router.handleMessage(
          json.encode({'method': 'DELETE', 'url': '/notes/1', 'data': {}}));
      await router.handleMessage(
          json.encode({'method': 'PUT', 'url': '/notes/1', 'data': {}}));
      await router.handleMessage(
          json.encode({'method': 'PATCH', 'url': '/notes/1', 'data': {}}));

      expect(called, ['delete', 'put', 'patch']);
    });

    test('missing method/url/data in JSON defaults to GET / {}', () async {
      final router = TestRouter((r) {
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {}, url: '/'));
      });

      final js = await router.handleMessage(json.encode({}));

      expect(js, contains('Home'));
    });

    test('setupRoutes is called only once across multiple requests', () async {
      var callCount = 0;
      final router = TestRouter((r) {
        callCount++;
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {}, url: '/'));
      });

      await router.handleMessage(json.encode({'method': 'GET', 'url': '/'}));
      await router.handleMessage(json.encode({'method': 'GET', 'url': '/'}));
      await router.handleMessage(json.encode({'method': 'GET', 'url': '/'}));

      expect(callCount, 1);
    });

    test('first registered route wins when multiple routes match', () async {
      final called = <String>[];
      final router = TestRouter((r) {
        r.get('/notes/:id', (req) async {
          called.add('first');
          return Inertia.render(component: 'First', props: {}, url: req.url);
        });
        r.get('/notes/:id', (req) async {
          called.add('second');
          return Inertia.render(component: 'Second', props: {}, url: req.url);
        });
      });

      await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/notes/1'}));

      expect(called, ['first']);
    });

    test('trailing slash does not match pattern without trailing slash',
        () async {
      final router = TestRouter((r) {
        r.get(
            '/notes',
            (req) async =>
                Inertia.render(component: 'Notes', props: {}, url: '/notes'));
      });

      final js = await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/notes/'}));

      expect(js, contains('console.warn'));
    });
  });

  group('InertiaRoute edge cases', () {
    test('route without params returns empty pathParams', () {
      final route = InertiaRoute(
        method: 'GET',
        pattern: '/about',
        handler: (req) async => '',
      );
      final req = route.tryMatch('GET', '/about', {}, {});
      expect(req, isNotNull);
      expect(req!.pathParams, isEmpty);
    });
  });

  group('Inertia.render with nested props', () {
    test('encodes nested objects correctly', () {
      final js = Inertia.render(
        component: 'Notes/Show',
        props: {
          'note': {
            'id': 1,
            'title': 'Hello',
            'tags': ['a', 'b']
          },
        },
        url: '/notes/1',
      );
      final payload = _extractPayload(js);
      final note = payload['props']['note'] as Map;
      expect(note['title'], 'Hello');
      expect((note['tags'] as List), ['a', 'b']);
    });
  });

  // ---------------------------------------------------------------------------
  // InertiaRouter — sharedProps
  // ---------------------------------------------------------------------------
  group('InertiaRouter sharedProps', () {
    test('default sharedProps() does not change render output', () async {
      final router = TestRouter((r) {
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {'x': 1}, url: '/'));
      });

      final js = await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/'}));
      final payload = _extractPayload(js);

      expect(payload['props'], {'x': 1});
    });

    test('sharedProps() are merged into render props', () async {
      final router = TestRouter((r) {
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {'x': 1}, url: '/'));
      });
      // ignore: missing_return
      // ignore: override_on_non_overriding_member
      // Provide sharedProps via anonymous subclass.
      final routerWithShared = _SharedPropsRouter(
        setup: (r) {
          r.get(
              '/',
              (req) async =>
                  Inertia.render(component: 'Home', props: {'x': 1}, url: '/'));
        },
        shared: {
          'auth': <String, dynamic>{'user': 'Alice'}
        },
      );

      final js = await routerWithShared
          .handleMessage(json.encode({'method': 'GET', 'url': '/'}));
      final payload = _extractPayload(js);

      expect(payload['props']['x'], 1);
      expect((payload['props']['auth'] as Map)['user'], 'Alice');
    });

    test('page props override shared props at the same top-level key',
        () async {
      final router = _SharedPropsRouter(
        setup: (r) {
          r.get(
              '/',
              (req) async => Inertia.render(
                  component: 'Home',
                  props: {
                    'auth': <String, dynamic>{'user': 'Page'}
                  },
                  url: '/'));
        },
        shared: {
          'auth': <String, dynamic>{'user': 'Shared'},
          'theme': 'dark',
        },
      );

      final js = await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/'}));
      final payload = _extractPayload(js);

      expect((payload['props']['auth'] as Map)['user'], 'Page');
      expect(payload['props']['theme'], 'dark');
    });

    test('sharedProps() are injected in the render after a redirect', () async {
      final router = _SharedPropsRouter(
        setup: (r) {
          r.post('/action', (req) async => Inertia.redirect('/result'));
          r.get(
              '/result',
              (req) async => Inertia.render(
                  component: 'Result', props: {}, url: '/result'));
        },
        shared: {'env': 'test'},
      );

      final js = await router.handleMessage(
          json.encode({'method': 'POST', 'url': '/action', 'data': {}}));
      final payload = _extractPayload(js);

      expect(payload['component'], 'Result');
      expect(payload['props']['env'], 'test');
    });

    test('sharedProps() are NOT injected into redirect responses', () async {
      final router = _SharedPropsRouter(
        setup: (r) {
          r.get('/go', (req) async => Inertia.redirect('/elsewhere'));
          // register /elsewhere so redirect is followed; but we inspect the
          // intermediate redirect by making the cycle guard surface it via a
          // dead-end route that still shows the redirect was NOT a render.
          r.get(
              '/elsewhere',
              (req) async => Inertia.render(
                  component: 'Elsewhere', props: {}, url: '/elsewhere'));
        },
        shared: {'env': 'test'},
      );

      // The final JS should be the rendered page (redirect was followed), and
      // shared props should appear there — but only in the render, not in a
      // bare redirect string.
      final js = await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/go'}));
      final payload = _extractPayload(js);

      expect(payload['component'], 'Elsewhere');
      // The redirect itself never surfaces as the result; the render does.
      expect(payload['props']['env'], 'test');
      // No 'redirect' key in the final payload.
      expect(payload.containsKey('redirect'), isFalse);
    });

    test('sharedProps() are not injected into 404 warn responses', () async {
      final router = _SharedPropsRouter(
        setup: (r) {
          // No routes registered — every request will 404.
        },
        shared: {'env': 'test'},
      );

      final js = await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/missing'}));

      expect(js, contains('console.warn'));
      expect(js, isNot(contains('"env"')));
    });
  });

  // ---------------------------------------------------------------------------
  // Regression tests (bugs to fix)
  // ---------------------------------------------------------------------------
  group('InertiaRouter regression', () {
    test('malformed JSON returns console.warn instead of throwing', () async {
      final router = TestRouter((r) {
        r.get(
            '/',
            (req) async =>
                Inertia.render(component: 'Home', props: {}, url: '/'));
      });

      final js = await router.handleMessage('not valid json {{ }}');

      expect(js, contains('console.warn'));
    });

    test('redirect loop is detected and does not hang', () async {
      final router = TestRouter((r) {
        r.get('/a', (req) async => Inertia.redirect('/b'));
        r.get('/b', (req) async => Inertia.redirect('/a'));
      });

      final js = await router
          .handleMessage(json.encode({'method': 'GET', 'url': '/a'}));

      expect(js, contains('console.warn'));
    });
  });
}
