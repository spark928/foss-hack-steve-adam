import 'package:flutter/foundation.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:study_app/models/academic/pdf_annotation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' as pdfrx;

class PdfAnnotationProvider with ChangeNotifier {
  List<PdfAnnotation> _annotations = [];
  String? _currentPdfPath;

  List<PdfAnnotation> get annotations => _annotations;

  void loadAnnotations(String pdfPath) {
    _currentPdfPath = pdfPath;
    _annotations = HiveService.pdfAnnotationsBox.values
        .where((a) => a.pdfPath == pdfPath)
        .toList();
    notifyListeners();
  }

  Future<void> addAnnotation({
    required String pdfPath,
    required int pageNumber,
    required List<dynamic> rects,
    String? noteText,
    required Color color,
  }) async {
    final annotation = PdfAnnotation(
      pdfPath: pdfPath,
      pageNumber: pageNumber,
      rects: rects.map((r) {
        if (r is Rect) {
          return PdfAnnotationRect(
            left: r.left,
            top: r.top,
            width: r.width,
            height: r.height,
          );
        } else if (r is pdfrx.PdfRect) {
          return PdfAnnotationRect(
            left: r.left,
            top: r.top,
            width: r.right - r.left,
            height: r.top - r.bottom,
          );
        }
        throw ArgumentError('Unsupported rect type: ${r.runtimeType}');
      }).toList(),
      noteText: noteText,
      colorValue: color.value,
      type: PdfAnnotationType.highlight,
    );

    await HiveService.pdfAnnotationsBox.add(annotation);
    
    if (_currentPdfPath == pdfPath) {
      _annotations.add(annotation);
      notifyListeners();
    }
  }

  Future<void> addDrawingAnnotation({
    required String pdfPath,
    required int pageNumber,
    required List<Offset> points,
    required Color color,
    required PdfAnnotationType type,
    double strokeWidth = 2.0,
  }) async {
    final annotation = PdfAnnotation(
      pdfPath: pdfPath,
      pageNumber: pageNumber,
      points: points.map((p) => PdfAnnotationPoint(x: p.dx, y: p.dy)).toList(),
      colorValue: color.value,
      type: type,
      strokeWidth: strokeWidth,
    );

    await HiveService.pdfAnnotationsBox.add(annotation);

    if (_currentPdfPath == pdfPath) {
      _annotations.add(annotation);
      notifyListeners();
    }
  }

  void eraseAt(int pageNumber, Offset pdfPoint) {
    final toDelete = <PdfAnnotation>[];
    
    for (final annot in _annotations.where((a) => a.pageNumber == pageNumber)) {
      bool hit = false;
      
      if (annot.type == PdfAnnotationType.highlight && annot.rects != null) {
        for (final rect in annot.rects!) {
          if (Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height).contains(pdfPoint)) {
            hit = true;
            break;
          }
        }
      } else if (annot.points != null) {
        for (final point in annot.points!) {
          final distSq = (point.x - pdfPoint.dx) * (point.x - pdfPoint.dx) + 
                         (point.y - pdfPoint.dy) * (point.y - pdfPoint.dy);
          if (distSq < 100) { // 10px radius
            hit = true;
            break;
          }
        }
      }

      if (hit) toDelete.add(annot);
    }

    for (final annot in toDelete) {
      deleteAnnotation(annot);
    }
  }

  Future<void> deleteAnnotation(PdfAnnotation annotation) async {
    await annotation.delete();
    _annotations.remove(annotation);
    notifyListeners();
  }

  Future<void> deleteAnnotationsForFile(String pdfPath) async {
    final toDelete = HiveService.pdfAnnotationsBox.values
        .where((a) => a.pdfPath == pdfPath)
        .toList();
    
    for (final annot in toDelete) {
      await annot.delete();
    }
    
    if (_currentPdfPath == pdfPath) {
      _annotations.clear();
      notifyListeners();
    }
  }

  List<PdfAnnotation> getAnnotationsForPage(int pageNumber) {
    return _annotations.where((a) => a.pageNumber == pageNumber).toList();
  }
}
