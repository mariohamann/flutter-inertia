import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inertia/flutter_inertia.dart';
import 'app_router.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: InertiaWebView(
          router: AppRouter(),
          devServerUrl: kDebugMode ? 'http://localhost:5173' : null,
        ),
      ),
    );
  }
}
