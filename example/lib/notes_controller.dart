import 'dart:convert';
import 'package:flutter_inertia/flutter_inertia.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesController {
  static Future<List<Map<String, dynamic>>> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notes') ?? '[]';
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> _saveNotes(List<Map<String, dynamic>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', jsonEncode(notes));
  }

  static Future<String> index() async {
    final notes = await _loadNotes();
    return Inertia.render(
      component: 'Notes/Index',
      props: {'notes': notes},
      url: '/notes',
    );
  }

  static Future<String> create() async {
    return Inertia.render(
      component: 'Notes/Create',
      props: {'errors': <String, String>{}},
      url: '/notes/create',
    );
  }

  static Future<String> store(dynamic req) async {
    final body = req.body as Map<String, dynamic>;
    final title = (body['title'] as String? ?? '').trim();
    final content = (body['content'] as String? ?? '').trim();

    if (title.isEmpty) {
      return Inertia.render(
        component: 'Notes/Create',
        props: {
          'errors': {'title': 'Title is required'},
          'values': body,
        },
        url: '/notes/create',
      );
    }

    final notes = await _loadNotes();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    notes.add({'id': id, 'title': title, 'content': content});
    await _saveNotes(notes);
    return Inertia.redirect('/notes');
  }

  static Future<String> show(String id) async {
    final notes = await _loadNotes();
    final note = notes.firstWhere(
      (n) => n['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    return Inertia.render(
      component: 'Notes/Show',
      props: {'note': note},
      url: '/notes/$id',
    );
  }

  static Future<String> edit(String id) async {
    final notes = await _loadNotes();
    final note = notes.firstWhere(
      (n) => n['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    return Inertia.render(
      component: 'Notes/Edit',
      props: {
        'note': note,
        'errors': <String, String>{},
      },
      url: '/notes/$id/edit',
    );
  }

  static Future<String> update(String id, dynamic req) async {
    final body = req.body as Map<String, dynamic>;
    final title = (body['title'] as String? ?? '').trim();
    final content = (body['content'] as String? ?? '').trim();

    if (title.isEmpty) {
      final notes = await _loadNotes();
      final note = notes.firstWhere(
        (n) => n['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      return Inertia.render(
        component: 'Notes/Edit',
        props: {
          'note': {...note, ...body},
          'errors': {'title': 'Title is required'},
        },
        url: '/notes/$id/edit',
      );
    }

    final notes = await _loadNotes();
    final idx = notes.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      notes[idx] = {'id': id, 'title': title, 'content': content};
      await _saveNotes(notes);
    }
    return Inertia.redirect('/notes/$id');
  }

  static Future<String> destroy(String id) async {
    final notes = await _loadNotes();
    notes.removeWhere((n) => n['id'] == id);
    await _saveNotes(notes);
    return Inertia.redirect('/notes');
  }
}
