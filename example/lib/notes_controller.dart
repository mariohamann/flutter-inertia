import 'package:flutter_inertia/flutter_inertia.dart';

class Note {
  final String id;
  String title;
  String body;

  Note({required this.id, required this.title, required this.body});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'body': body};
}

/// Simple in-memory notes store with CRUD operations.
class NotesController {
  static final List<Note> _notes = [];
  static int _counter = 0;

  static String _nextId() => (++_counter).toString();

  // GET /
  static Future<String> index() async {
    return Inertia.render(
      component: 'Notes/Index',
      props: {'notes': _notes.map((n) => n.toJson()).toList()},
      url: '/',
    );
  }

  // GET /notes/create
  static Future<String> create() async {
    return Inertia.render(
      component: 'Notes/Create',
      props: {},
      url: '/notes/create',
    );
  }

  // POST /notes
  static Future<String> store(Map<String, dynamic> body) async {
    final note = Note(
      id: _nextId(),
      title: body['title'] as String? ?? '',
      body: body['body'] as String? ?? '',
    );
    _notes.add(note);
    return Inertia.redirect('/');
  }

  // GET /notes/:id/edit
  static Future<String> edit(String id) async {
    final note = _notes.firstWhere(
      (n) => n.id == id,
      orElse: () => Note(id: id, title: '', body: ''),
    );
    return Inertia.render(
      component: 'Notes/Edit',
      props: {'note': note.toJson()},
      url: '/notes/$id/edit',
    );
  }

  // PATCH /notes/:id
  static Future<String> update(String id, Map<String, dynamic> body) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx].title = body['title'] as String? ?? _notes[idx].title;
      _notes[idx].body = body['body'] as String? ?? _notes[idx].body;
    }
    return Inertia.redirect('/');
  }

  // DELETE /notes/:id
  static Future<String> destroy(String id) async {
    _notes.removeWhere((n) => n.id == id);
    return Inertia.redirect('/');
  }
}
