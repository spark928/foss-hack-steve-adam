import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:study_app/models/enote.dart';

class ENoteProvider extends ChangeNotifier {
  Box<ENote> get _enotesBox => HiveService.enotesBox;

  List<ENote> get enotes => _enotesBox.values.toList();

  List<ENote> getENotes({String? subjectId, String? chapterId}) {
    return _enotesBox.values.where((e) {
      if (chapterId != null) return e.chapterId == chapterId;
      if (subjectId != null) return e.subjectId == subjectId && e.chapterId == null;
      return true;
    }).toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  Future<ENote?> importFile({required String subjectId, String? chapterId}) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.first;
    if (picked.path == null) return null;

    final sourceFile = File(picked.path!);
    final appDir = await getApplicationDocumentsDirectory();
    final enotesDir = Directory('${appDir.path}/enotes');
    if (!enotesDir.existsSync()) enotesDir.createSync(recursive: true);

    final ext = picked.extension?.toLowerCase() ?? '';
    final destPath = '${enotesDir.path}/${picked.name}';
    await sourceFile.copy(destPath);

    String fileType;
    if (ext == 'pdf') {
      fileType = 'pdf';
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
      fileType = 'image';
    } else {
      fileType = 'other';
    }

    final enote = ENote(
      title: picked.name,
      filePath: destPath,
      fileType: fileType,
      subjectId: subjectId,
      chapterId: chapterId,
    );
    await _enotesBox.put(enote.id, enote);
    notifyListeners();
    return enote;
  }

  Future<void> deleteENote(String id) async {
    final enote = _enotesBox.get(id);
    if (enote == null) return;
    try {
      final f = File(enote.filePath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    await _enotesBox.delete(id);
    notifyListeners();
  }
}
