import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:study_app/providers/pdf_annotation_provider.dart';

class FileService {
  static const String rootFolder = 'subjects';

  static Future<Directory> getSubjectDirectory(String subjectName, {List<String>? subPath}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    String path = '${docsDir.path}/$rootFolder/$subjectName';
    
    if (subPath != null && subPath.isNotEmpty) {
      path += '/${subPath.join('/')}';
    }
    
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return dir;
  }

  static Future<List<FileSystemEntity>> getSubjectContents(String subjectName, {List<String>? subPath}) async {
    try {
      final dir = await getSubjectDirectory(subjectName, subPath: subPath);
      return await dir.list().toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Directory> createChapter(String subjectName, String chapterName, {List<String>? currentPath}) async {
    final List<String> fullPath = [...(currentPath ?? []), chapterName];
    return await getSubjectDirectory(subjectName, subPath: fullPath);
  }

  static Future<File?> importPDF(File sourceFile, String subjectName, {List<String>? subPath}) async {
    try {
      final dir = await getSubjectDirectory(subjectName, subPath: subPath);
      final fileName = sourceFile.path.split(Platform.pathSeparator).last;
      final targetPath = '${dir.path}/$fileName';
      
      return await sourceFile.copy(targetPath);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteEntity(FileSystemEntity entity, PdfAnnotationProvider provider) async {
    try {
      if (entity is File) {
        if (entity.path.toLowerCase().endsWith('.pdf')) {
          await provider.deleteAnnotationsForFile(entity.path);
        }
        await entity.delete();
      } else if (entity is Directory) {
        final files = entity.listSync(recursive: true);
        for (final file in files) {
          if (file is File && file.path.toLowerCase().endsWith('.pdf')) {
            await provider.deleteAnnotationsForFile(file.path);
          }
        }
        await entity.delete(recursive: true);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
