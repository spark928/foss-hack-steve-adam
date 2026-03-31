import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'event.g.dart';

@HiveType(typeId: 20)
class Event extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String type; // "test", "exam", "programme", "other"

  @HiveField(4)
  String? subjectId;

  @HiveField(5)
  bool isCompleted;

  Event({
    String? id,
    required this.title,
    required this.date,
    required this.type,
    this.subjectId,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();
}
