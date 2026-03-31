// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubjectNoteAdapter extends TypeAdapter<SubjectNote> {
  @override
  final int typeId = 21;

  @override
  SubjectNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectNote(
      id: fields[0] as String?,
      subjectName: fields[1] as String,
      title: fields[2] as String,
      content: fields[3] as String,
      createdAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SubjectNote obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectName)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
