import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_type.dart';

class AssetModel {
  const AssetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.color,
    this.description,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.latestSnapshot,
    this.previousSnapshot,
  });

  final String id;
  final String name;
  final String type;
  final String currency;
  final String color;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LatestSnapshotModel? latestSnapshot;
  final LatestSnapshotModel? previousSnapshot;

  factory AssetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssetModel(
      id: doc.id,
      name: data['name'] as String,
      type: data['type'] as String,
      currency: data['currency'] as String,
      color: data['color'] as String? ?? '#4F6EF7',
      description: data['description'] as String?,
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      latestSnapshot: data['latestSnapshot'] != null
          ? LatestSnapshotModel.fromMap(
              data['latestSnapshot'] as Map<String, dynamic>,
            )
          : null,
      previousSnapshot: data['previousSnapshot'] != null
          ? LatestSnapshotModel.fromMap(
              data['previousSnapshot'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type,
    'currency': currency,
    'color': color,
    if (description != null) 'description': description,
    'isArchived': isArchived,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'latestSnapshot': latestSnapshot?.toMap(),
    'previousSnapshot': previousSnapshot?.toMap(),
  };

  Asset toDomain() => Asset(
    id: id,
    name: name,
    type: AssetType.fromString(type),
    currency: currency,
    color: color,
    description: description,
    isArchived: isArchived,
    createdAt: createdAt,
    updatedAt: updatedAt,
    latestSnapshot: latestSnapshot?.toDomain(),
    previousSnapshot: previousSnapshot?.toDomain(),
  );
}

class LatestSnapshotModel {
  const LatestSnapshotModel({
    required this.value,
    required this.recordedAt,
    required this.entryId,
  });

  final double value;
  final DateTime recordedAt;
  final String entryId;

  factory LatestSnapshotModel.fromMap(Map<String, dynamic> map) {
    return LatestSnapshotModel(
      value: (map['value'] as num).toDouble(),
      recordedAt: (map['recordedAt'] as Timestamp).toDate(),
      entryId: map['entryId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'value': value,
    'recordedAt': Timestamp.fromDate(recordedAt),
    'entryId': entryId,
  };

  LatestSnapshot toDomain() =>
      LatestSnapshot(value: value, recordedAt: recordedAt, entryId: entryId);
}
