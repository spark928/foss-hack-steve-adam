import 'package:hive/hive.dart';

part 'pdf_annotation.g.dart';

@HiveType(typeId: 23)
enum PdfAnnotationType {
  @HiveField(0)
  highlight,
  @HiveField(1)
  pen,
}

@HiveType(typeId: 21)
class PdfAnnotation extends HiveObject {
  @HiveField(0)
  final String pdfPath;

  @HiveField(1)
  final int pageNumber;

  @HiveField(2)
  final List<PdfAnnotationRect>? rects;

  @HiveField(3)
  final List<PdfAnnotationPoint>? points;

  @HiveField(4)
  final String? noteText;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final PdfAnnotationType type;

  @HiveField(7)
  final double strokeWidth;

  PdfAnnotation({
    required this.pdfPath,
    required this.pageNumber,
    this.rects,
    this.points,
    this.noteText,
    required this.colorValue,
    required this.type,
    this.strokeWidth = 2.0,
  });
}

@HiveType(typeId: 22)
class PdfAnnotationRect {
  @HiveField(0)
  final double left;
  @HiveField(1)
  final double top;
  @HiveField(2)
  final double width;
  @HiveField(3)
  final double height;

  PdfAnnotationRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

@HiveType(typeId: 24)
class PdfAnnotationPoint {
  @HiveField(0)
  final double x;
  @HiveField(1)
  final double y;

  PdfAnnotationPoint({
    required this.x,
    required this.y,
  });
}
