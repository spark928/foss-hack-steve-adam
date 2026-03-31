// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ENoteAdapter extends TypeAdapter<ENote> {
  @override
  final int typeId = 16;

  @override
  ENote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ENote(
      id: fields[0] as String?,
      title: fields[1] as String,
      filePath: fields[2] as String,
      fileType: fields[3] as String,
      subjectId: fields[4] as String?,
      chapterId: fields[5] as String?,
      importedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ENote obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.fileType)
      ..writeByte(4)
      ..write(obj.subjectId)
      ..writeByte(5)
      ..write(obj.chapterId)
      ..writeByte(6)
      ..write(obj.importedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ENoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
