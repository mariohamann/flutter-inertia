import 'package:flutter_inertia/flutter_inertia.dart';
import 'notes_controller.dart';

class AppRouter extends InertiaRouter {
  @override
  void setupRoutes() {
    get('/', (req) => NotesController.index());
    get('/notes/create', (req) => NotesController.create());
    post('/notes', (req) => NotesController.store(req.body));
    get('/notes/:id/edit', (req) => NotesController.edit(req.param('id')!));
    patch('/notes/:id', (req) => NotesController.update(req.param('id')!, req.body));
    delete('/notes/:id', (req) => NotesController.destroy(req.param('id')!));
  }
}
