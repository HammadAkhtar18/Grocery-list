// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_list_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroceryListModelAdapter extends TypeAdapter<GroceryListModel> {
  @override
  final int typeId = 0;

  @override
  GroceryListModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroceryListModel(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      items: (fields[3] as List).cast<GroceryItemModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, GroceryListModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroceryListModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
