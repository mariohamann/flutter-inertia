import 'package:flutter_inertia/flutter_inertia.dart';
import 'counter_controller.dart';

class AppRouter extends InertiaRouter {
  @override
  void setupRoutes() {
    get('/', (req) => CounterController.index());
    post('/increment', (req) => CounterController.increment());
    post('/decrement', (req) => CounterController.decrement());
    post('/reset', (req) => CounterController.reset());
  }
}
