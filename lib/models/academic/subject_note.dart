import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'subject_note.g.dart';

@HiveType(typeId: 21) // Using 21 to avoid conflicts with previous adapters
class SubjectNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectName;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  final DateTime createdAt;

  SubjectNote({
    String? id,
    required this.subjectName,
    required this.title,
    this.content = '',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();
}
