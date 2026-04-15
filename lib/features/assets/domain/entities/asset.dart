import 'package:equatable/equatable.dart';
import 'asset_type.dart';

class Asset extends Equatable {
  const Asset({
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
  final AssetType type;
  final String currency;
  final String color; // hex
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LatestSnapshot? latestSnapshot;
  final LatestSnapshot? previousSnapshot;

  Asset copyWith({
    String? name,
    AssetType? type,
    String? currency,
    String? color,
    String? description,
    bool? isArchived,
    DateTime? updatedAt,
    LatestSnapshot? latestSnapshot,
    LatestSnapshot? previousSnapshot,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latestSnapshot: latestSnapshot ?? this.latestSnapshot,
      previousSnapshot: previousSnapshot ?? this.previousSnapshot,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    currency,
    color,
    description,
    isArchived,
    createdAt,
    updatedAt,
    latestSnapshot,
    previousSnapshot,
  ];
}

class LatestSnapshot extends Equatable {
  const LatestSnapshot({
    required this.value,
    required this.recordedAt,
    required this.entryId,
  });

  final double value;
  final DateTime recordedAt;
  final String entryId;

  @override
  List<Object> get props => [value, recordedAt, entryId];
}
