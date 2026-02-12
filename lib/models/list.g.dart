// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppListAdapter extends TypeAdapter<AppList> {
  @override
  final int typeId = 0;

  @override
  AppList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppList(
      id: fields[5] as String?,
      name: fields[0] as String,
      createdAt: fields[1] as DateTime,
      archivedAt: fields[2] as DateTime?,
      isPinned: fields[3] as bool,
      items: (fields[4] as List?)?.cast<AppListItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, AppList obj) {
    writer
      ..writeByte(6)
      ..writeByte(5)
      ..write(obj.id)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.archivedAt)
      ..writeByte(3)
      ..write(obj.isPinned)
      ..writeByte(4)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppListItemAdapter extends TypeAdapter<AppListItem> {
  @override
  final int typeId = 1;

  @override
  AppListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppListItem(
      name: fields[0] as String,
      isChecked: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppListItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.isChecked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
