import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'enote.g.dart';

@HiveType(typeId: 16)
class ENote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String filePath;

  @HiveField(3)
  String fileType; // "pdf", "image", "other"

  @HiveField(4)
  String? subjectId;

  @HiveField(5)
  String? chapterId;

  @HiveField(6)
  DateTime importedAt;

  ENote({
    String? id,
    required this.title,
    required this.filePath,
    required this.fileType,
    this.subjectId,
    this.chapterId,
    DateTime? importedAt,
  })  : id = id ?? const Uuid().v4(),
        importedAt = importedAt ?? DateTime.now();
}
