// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PantryItemModelAdapter extends TypeAdapter<PantryItemModel> {
  @override
  final int typeId = 2;

  @override
  PantryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PantryItemModel(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      quantity: fields[3] as double,
      unit: fields[4] as String,
      location: fields[5] as String,
      expirationDate: fields[6] as DateTime?,
      addedDate: fields[7] as DateTime,
      lowStockThreshold: fields[8] as double?,
      barcode: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PantryItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.expirationDate)
      ..writeByte(7)
      ..write(obj.addedDate)
      ..writeByte(8)
      ..write(obj.lowStockThreshold)
      ..writeByte(9)
      ..write(obj.barcode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PantryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
