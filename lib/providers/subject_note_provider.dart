import 'package:flutter/material.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:study_app/models/academic/subject_note.dart';

class SubjectNoteProvider with ChangeNotifier {
  List<SubjectNote> _notes = [];
  String? _currentSubject;

  List<SubjectNote> get notes => _notes;

  void loadNotes(String subjectName) {
    _currentSubject = subjectName;
    _notes = HiveService.subjectNotesBox.values
        .where((n) => n.subjectName == subjectName)
        .toList();
    notifyListeners();
  }

  Future<void> addNote(String subjectName, String title, {String content = ''}) async {
    final note = SubjectNote(
      subjectName: subjectName,
      title: title,
      content: content,
    );
    await HiveService.subjectNotesBox.add(note);
    if (_currentSubject == subjectName) {
      _notes.add(note);
      notifyListeners();
    }
  }

  Future<void> updateNote(SubjectNote note, {String? title, String? content}) async {
    if (title != null) note.title = title;
    if (content != null) note.content = content;
    await note.save();
    notifyListeners();
  }

  Future<void> deleteNote(SubjectNote note) async {
    await note.delete();
    _notes.remove(note);
    notifyListeners();
  }

  List<SubjectNote> getNotesForSubject(String subjectName) {
    return _notes.where((n) => n.subjectName == subjectName).toList();
  }
}
