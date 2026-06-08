import 'package:flutter_inertia/flutter_inertia.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  static Future<String> index() async {
    final prefs = await SharedPreferences.getInstance();
    return Inertia.render(
      component: 'Counter/Index',
      props: {'count': prefs.getInt('count') ?? 0},
      url: '/',
    );
  }

  static Future<String> increment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', (prefs.getInt('count') ?? 0) + 1);
    return Inertia.redirect('/');
  }

  static Future<String> decrement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', (prefs.getInt('count') ?? 0) - 1);
    return Inertia.redirect('/');
  }

  static Future<String> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('count', 0);
    return Inertia.redirect('/');
  }
}
