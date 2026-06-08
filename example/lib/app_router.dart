import 'package:flutter_inertia/flutter_inertia.dart';
import 'counter_controller.dart';
import 'home_controller.dart';
import 'notes_controller.dart';
import 'notification_controller.dart';

class AppRouter extends InertiaRouter {
  @override
  void setupRoutes() {
    get('/', (req) => HomeController.index());

    get('/counter', (req) => CounterController.index());
    post('/increment', (req) => CounterController.increment());
    post('/decrement', (req) => CounterController.decrement());
    post('/reset', (req) => CounterController.reset());

    get('/notes', (req) => NotesController.index());
    get('/notes/create', (req) => NotesController.create());
    post('/notes', (req) => NotesController.store(req));
    get('/notes/:id', (req) => NotesController.show(req.param('id')!));
    get('/notes/:id/edit', (req) => NotesController.edit(req.param('id')!));
    patch('/notes/:id', (req) => NotesController.update(req.param('id')!, req));
    delete('/notes/:id', (req) => NotesController.destroy(req.param('id')!));

    get('/notification', (req) => NotificationController.index());
    post('/notification', (req) => NotificationController.send(req));
  }
}
