import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'inertia_router.dart';

export 'inertia.dart';
export 'inertia_router.dart';

/// A Flutter widget that hosts an Inertia.js web app inside a [WebView].
///
/// Subclass [InertiaRouter] to define your routes, then pass an instance
/// to this widget:
///
/// ```dart
/// InertiaWebView(router: AppRouter())
/// ```
///
/// By default the widget loads the bundled `assets/www/index.html`.
/// In debug mode, point [devServerUrl] at your Vite dev server for HMR:
///
/// ```dart
/// InertiaWebView(
///   router: AppRouter(),
///   devServerUrl: 'http://localhost:5173',
/// )
/// ```
class InertiaWebView extends StatefulWidget {
  final InertiaRouter router;

  /// When set (and in debug mode) the WebView loads from this URL instead
  /// of the bundled asset – enabling Vite HMR.
  final String? devServerUrl;

  /// The Flutter asset path for the bundled single-file HTML.
  /// Defaults to `assets/www/index.html`.
  final String assetPath;

  const InertiaWebView({
    super.key,
    required this.router,
    this.devServerUrl,
    this.assetPath = 'assets/www/index.html',
  });

  @override
  State<InertiaWebView> createState() => _InertiaWebViewState();
}

class _InertiaWebViewState extends State<InertiaWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // On iOS/macOS enable the Safari Web Inspector in debug builds.
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => debugPrint('[InertiaWebView] loading: $url'),
        onPageFinished: (url) {
          debugPrint('[InertiaWebView] loaded: $url');
          if (kDebugMode) _controller.runJavaScript(_consoleShim);
        },
        onWebResourceError: (err) =>
            debugPrint('[InertiaWebView] ERROR ${err.errorCode}: ${err.description} (${err.url})'),
      ))
      ..addJavaScriptChannel(
        'nativeInertia',
        onMessageReceived: _onMessage,
      )
      ..addJavaScriptChannel(
        'FlutterConsole',
        onMessageReceived: (msg) => debugPrint('[JS] ${msg.message}'),
      );

    // Enable Safari Web Inspector on iOS/macOS (iOS 16.4+, macOS 13.3+)
    if (kDebugMode && _controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController).setInspectable(true);
    }

    _load();
  }

  void _load() {
    final devUrl = widget.devServerUrl;
    if (kDebugMode && devUrl != null) {
      _controller.loadRequest(Uri.parse(devUrl));
    } else {
      _controller.loadFlutterAsset(widget.assetPath);
    }
  }

  /// Forwards JS console.log/warn/error to Flutter's debugPrint in debug mode.
  static const _consoleShim = '''
    (function() {
      const _c = window.FlutterConsole;
      if (!_c) return;
      ['log','warn','error'].forEach(function(level) {
        const orig = console[level].bind(console);
        console[level] = function() {
          const msg = Array.from(arguments).map(String).join(' ');
          _c.postMessage('[' + level.toUpperCase() + '] ' + msg);
          orig.apply(console, arguments);
        };
      });
      window.addEventListener('error', function(e) {
        _c.postMessage('[UNCAUGHT] ' + e.message + ' @ ' + e.filename + ':' + e.lineno);
      });
      window.addEventListener('unhandledrejection', function(e) {
        _c.postMessage('[PROMISE] ' + String(e.reason));
      });
    })();
  ''';

  Future<void> _onMessage(JavaScriptMessage message) async {
    try {
      final js = await widget.router.handleMessage(message.message);
      await _controller.runJavaScript(js);
    } catch (e, st) {
      debugPrint('[flutter_inertia] Error handling message: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
      gestureRecognizers: {
        Factory<VerticalDragGestureRecognizer>(
            VerticalDragGestureRecognizer.new),
      },
    );
  }
}
