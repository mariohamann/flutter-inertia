import 'package:flutter/material.dart';
import 'package:flutter_inertia/flutter_inertia.dart';
import 'app_router.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InertiaWebView(
          router: AppRouter(),
          // Uncomment for Vite HMR during development:
          // devServerUrl: 'http://localhost:5173',
        ),
      ),
    );
  }
}
