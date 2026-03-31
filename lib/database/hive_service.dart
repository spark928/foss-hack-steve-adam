import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:study_app/models/subject.dart';
import 'package:study_app/models/chapter.dart';
import 'package:study_app/models/note.dart';
import 'package:study_app/models/block.dart';
import 'package:study_app/models/study_session.dart';
import 'package:study_app/models/todo.dart';
import 'package:study_app/models/todo_subtask.dart';
import 'package:study_app/models/flashcard.dart';
import 'package:study_app/models/mind_map.dart';
import 'package:study_app/models/drawing.dart';
import 'package:study_app/models/academic/subject_attendance.dart';
import 'package:study_app/models/academic/attendance_record.dart';
import 'package:study_app/models/academic/class_schedule.dart';
import 'package:study_app/models/timestamp.dart';
import 'package:study_app/models/event.dart';
import 'package:study_app/models/enote.dart';
import 'package:study_app/models/academic/pdf_annotation.dart';
import 'package:study_app/models/academic/subject_note.dart';
import 'package:study_app/models/safe_block_adapter.dart';

class HiveService {
  static const String subjectsBoxName = 'subjectsBox';
  static const String chaptersBoxName = 'chaptersBox';
  static const String notesBoxName = 'notesBox';
  static const String studyTimeBoxName = 'studyTimeBox';
  static const String settingsBoxName = 'settingsBox';
  static const String todosBoxName = 'todosBox';
  static const String flashcardsBoxName = 'flashcardsBox';
  static const String mindMapsBoxName = 'mindMapsBox';
  static const String drawingsBoxName = 'drawingsBox';
  static const String academicSubjectsBoxName = 'academicSubjectsBox';
  static const String attendanceRecordsBoxName = 'attendanceRecordsBox';
  static const String classSchedulesBoxName = 'classSchedulesBox';
  static const String timestampsBoxName = 'timestampsBox';
  static const String eventsBoxName = 'eventsBox';
  static const String enotesBoxName = 'enotesBox';
  static const String pdfAnnotationsBoxName = 'pdfAnnotationsBox';
  static const String subjectNotesBoxName = 'subjectNotesBox';
  static const String vaultNotesBoxName = 'vaultNotesBox';

  static void _registerSafely<T>(TypeAdapter<T> adapter) {
    try {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter(adapter);
      }
    } catch (e) {
      debugPrint('Error registering adapter for typeId ${adapter.typeId}: $e');
    }
  }

  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Register Adapters
      _registerSafely(SubjectAdapter());
      _registerSafely(ChapterAdapter());
      _registerSafely(NoteAdapter());
      _registerSafely(SubjectAttendanceAdapter());
      _registerSafely(TodoAdapter());
      _registerSafely(StudySessionAdapter());
      _registerSafely(BlockTypeAdapter());
      _registerSafely(SafeBlockAdapter()); // replaces generated BlockAdapter — handles legacy String fields
      _registerSafely(TodoSubTaskAdapter());
      _registerSafely(FlashcardAdapter());
      _registerSafely(MindMapNodeAdapter());
      _registerSafely(MindMapAdapter());
      _registerSafely(DrawingAdapter());
      _registerSafely(AttendanceRecordAdapter());
      _registerSafely(ClassScheduleAdapter());
      _registerSafely(EventAdapter());
      _registerSafely(ENoteAdapter());
      _registerSafely(TimestampAdapter());
      _registerSafely(PdfAnnotationAdapter());
      _registerSafely(PdfAnnotationRectAdapter());
      _registerSafely(PdfAnnotationTypeAdapter());
      _registerSafely(PdfAnnotationPointAdapter());
      _registerSafely(SubjectNoteAdapter());

      // Open Boxes simultaneously to prevent race conditions
      await Future.wait([
        Hive.openBox<Subject>(subjectsBoxName),
        Hive.openBox<Chapter>(chaptersBoxName),
        Hive.openBox<Note>(notesBoxName),
        Hive.openBox<StudySession>(studyTimeBoxName),
        Hive.openBox(settingsBoxName),
        Hive.openBox<Todo>(todosBoxName),
        Hive.openBox<Flashcard>(flashcardsBoxName),
        Hive.openBox<MindMap>(mindMapsBoxName),
        Hive.openBox<Drawing>(drawingsBoxName),
        Hive.openBox<SubjectAttendance>(academicSubjectsBoxName),
        Hive.openBox<AttendanceRecord>(attendanceRecordsBoxName),
        Hive.openBox<ClassSchedule>(classSchedulesBoxName),
        Hive.openBox<Timestamp>(timestampsBoxName),
        Hive.openBox<Event>(eventsBoxName),
        Hive.openBox<ENote>(enotesBoxName),
        Hive.openBox<PdfAnnotation>(pdfAnnotationsBoxName),
        Hive.openBox<SubjectNote>(subjectNotesBoxName),
        Hive.openBox(vaultNotesBoxName),
      ]);
      // Safety: one-time clear after resolving typeId conflict (2026-03-31)
      // You can comment this out after the first run if you want to keep events.
      // await Hive.box<Event>(eventsBoxName).clear(); 
      debugPrint('Hive initialization completed successfully.');
    } catch (e, stackTrace) {
      debugPrint('Critical Hive initialization failure: $e\n$stackTrace');
      rethrow; // Rethrow to let the app handle the critical failure
    }
  }

  static Future<void> clearAllData() async {
    await subjectsBox.clear();
    await chaptersBox.clear();
    await notesBox.clear();
    await studyTimeBox.clear();
    await (Hive.box(settingsBoxName)).clear();
    await todosBox.clear();
    await flashcardsBox.clear();
    await mindMapsBox.clear();
    await drawingsBox.clear();
    await academicSubjectsBox.clear();
    await attendanceRecordsBox.clear();
    await classSchedulesBox.clear();
    await timestampsBox.clear();
    await eventsBox.clear();
    await enotesBox.clear();
    await pdfAnnotationsBox.clear();
    await subjectNotesBox.clear();
  }

  static Box<Subject> get subjectsBox => Hive.box<Subject>(subjectsBoxName);
  static Box<Chapter> get chaptersBox => Hive.box<Chapter>(chaptersBoxName);
  static Box<Note> get notesBox => Hive.box<Note>(notesBoxName);
  static Box<StudySession> get studyTimeBox => Hive.box<StudySession>(studyTimeBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box<Todo> get todosBox => Hive.box<Todo>(todosBoxName);
  static Box<Flashcard> get flashcardsBox => Hive.box<Flashcard>(flashcardsBoxName);
  static Box<MindMap> get mindMapsBox => Hive.box<MindMap>(mindMapsBoxName);
  static Box<Drawing> get drawingsBox => Hive.box<Drawing>(drawingsBoxName);
  static Box<SubjectAttendance> get academicSubjectsBox => Hive.box<SubjectAttendance>(academicSubjectsBoxName);
  static Box<AttendanceRecord> get attendanceRecordsBox => Hive.box<AttendanceRecord>(attendanceRecordsBoxName);
  static Box<ClassSchedule> get classSchedulesBox => Hive.box<ClassSchedule>(classSchedulesBoxName);
  static Box<Timestamp> get timestampsBox => Hive.box<Timestamp>(timestampsBoxName);
  static Box<Event> get eventsBox => Hive.box<Event>(eventsBoxName);
  static Box<ENote> get enotesBox => Hive.box<ENote>(enotesBoxName);
  static Box<PdfAnnotation> get pdfAnnotationsBox => Hive.box<PdfAnnotation>(pdfAnnotationsBoxName);
  static Box<SubjectNote> get subjectNotesBox => Hive.box<SubjectNote>(subjectNotesBoxName);
  static Box get vaultNotesBox => Hive.box(vaultNotesBoxName);
}
