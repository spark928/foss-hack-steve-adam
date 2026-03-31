import 'package:hive/hive.dart';
import 'package:study_app/models/block.dart';

/// A hand-written, fully defensive replacement for the generated BlockAdapter.
///
/// Guards against ALL legacy data corruption scenarios:
///   - [BlockType] stored as a raw String (e.g. "text", "BlockType.heading")
///   - [String] fields that contain a DateTime or other unexpected type
///   - Missing / null fields from older schema versions
class SafeBlockAdapter extends TypeAdapter<Block> {
  @override
  final int typeId = 7;

  // ── BlockType ──────────────────────────────────────────────────────────────

  static BlockType _parseBlockType(dynamic raw) {
    if (raw is BlockType) return raw;

    if (raw is String) {
      final normalized = raw.split('.').last.toLowerCase().trim();
      switch (normalized) {
        case 'heading':   return BlockType.heading;
        case 'text':      return BlockType.text;
        case 'bullet':    return BlockType.bullet;
        case 'checkbox':  return BlockType.checkbox;
        case 'link':      return BlockType.link;
        case 'subbullet': return BlockType.subBullet;
        default:          return BlockType.text;
      }
    }

    // int index stored by a properly-functioning BlockTypeAdapter
    if (raw is int) {
      switch (raw) {
        case 0: return BlockType.heading;
        case 1: return BlockType.text;
        case 2: return BlockType.bullet;
        case 3: return BlockType.checkbox;
        case 4: return BlockType.link;
        case 5: return BlockType.subBullet;
        default: return BlockType.text;
      }
    }

    return BlockType.text; // safe fallback for any other type
  }

  // ── String (handles DateTime / int / anything else gracefully) ────────────

  static String _safeString(dynamic raw, String fallback) {
    if (raw == null) return fallback;
    if (raw is String) return raw;
    // DateTime, int, double, bool – just stringify them rather than crashing
    return raw.toString();
  }

  // ── int ───────────────────────────────────────────────────────────────────

  static int _safeInt(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }

  // ── bool ──────────────────────────────────────────────────────────────────

  static bool _safeBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is int) return raw != 0;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  // ── TypeAdapter implementation ────────────────────────────────────────────

  @override
  Block read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return Block(
      id:        _safeString(fields[0], ''),
      type:      _parseBlockType(fields[1]),
      content:   _safeString(fields[2], ''),
      order:     _safeInt(fields[3], 0),
      isChecked: _safeBool(fields[4]),
    );
  }

  @override
  void write(BinaryWriter writer, Block obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)       // BlockTypeAdapter encodes this as its int index
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.order)
      ..writeByte(4)
      ..write(obj.isChecked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
