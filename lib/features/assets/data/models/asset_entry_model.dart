import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/asset_entry.dart';

class AssetEntryModel {
  const AssetEntryModel({
    required this.id,
    required this.assetId,
    required this.value,
    this.note,
    required this.recordedAt,
    required this.createdAt,
  });

  final String id;
  final String assetId;
  final double value;
  final String? note;
  final DateTime recordedAt;
  final DateTime createdAt;

  factory AssetEntryModel.fromFirestore(DocumentSnapshot doc, String assetId) {
    final data = doc.data() as Map<String, dynamic>;
    return AssetEntryModel(
      id: doc.id,
      assetId: assetId,
      value: (data['value'] as num).toDouble(),
      note: data['note'] as String?,
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'value': value,
    if (note != null && note!.isNotEmpty) 'note': note,
    'recordedAt': Timestamp.fromDate(recordedAt),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  AssetEntry toDomain() => AssetEntry(
    id: id,
    assetId: assetId,
    value: value,
    note: note,
    recordedAt: recordedAt,
    createdAt: createdAt,
  );
}
