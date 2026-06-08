import 'package:flutter_inertia/flutter_inertia.dart';

class HomeController {
  static Future<String> index() async {
    return Inertia.render(
      component: 'Home/Index',
      props: {},
      url: '/',
    );
  }
}
