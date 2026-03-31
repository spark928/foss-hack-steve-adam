// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_annotation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PdfAnnotationAdapter extends TypeAdapter<PdfAnnotation> {
  @override
  final int typeId = 21;

  @override
  PdfAnnotation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfAnnotation(
      pdfPath: fields[0] as String,
      pageNumber: fields[1] as int,
      rects: (fields[2] as List?)?.cast<PdfAnnotationRect>(),
      points: (fields[3] as List?)?.cast<PdfAnnotationPoint>(),
      noteText: fields[4] as String?,
      colorValue: fields[5] as int,
      type: fields[6] as PdfAnnotationType,
      strokeWidth: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PdfAnnotation obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.pdfPath)
      ..writeByte(1)
      ..write(obj.pageNumber)
      ..writeByte(2)
      ..write(obj.rects)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.noteText)
      ..writeByte(5)
      ..write(obj.colorValue)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.strokeWidth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAnnotationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PdfAnnotationRectAdapter extends TypeAdapter<PdfAnnotationRect> {
  @override
  final int typeId = 22;

  @override
  PdfAnnotationRect read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfAnnotationRect(
      left: fields[0] as double,
      top: fields[1] as double,
      width: fields[2] as double,
      height: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PdfAnnotationRect obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.left)
      ..writeByte(1)
      ..write(obj.top)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAnnotationRectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PdfAnnotationPointAdapter extends TypeAdapter<PdfAnnotationPoint> {
  @override
  final int typeId = 24;

  @override
  PdfAnnotationPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PdfAnnotationPoint(
      x: fields[0] as double,
      y: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PdfAnnotationPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAnnotationPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PdfAnnotationTypeAdapter extends TypeAdapter<PdfAnnotationType> {
  @override
  final int typeId = 23;

  @override
  PdfAnnotationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PdfAnnotationType.highlight;
      case 1:
        return PdfAnnotationType.pen;
      default:
        return PdfAnnotationType.highlight;
    }
  }

  @override
  void write(BinaryWriter writer, PdfAnnotationType obj) {
    switch (obj) {
      case PdfAnnotationType.highlight:
        writer.writeByte(0);
        break;
      case PdfAnnotationType.pen:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfAnnotationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
