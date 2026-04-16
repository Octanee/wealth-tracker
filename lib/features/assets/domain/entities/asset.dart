import 'package:equatable/equatable.dart';
import 'asset_config.dart';
import 'asset_type.dart';

const _assetFieldUnset = _AssetFieldUnset();

class _AssetFieldUnset {
  const _AssetFieldUnset();
}

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
    this.config,
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
  final AssetConfig? config;

  CashAssetConfig? get cashConfig =>
      config is CashAssetConfig ? config as CashAssetConfig : null;

  MetalAssetConfig? get metalConfig =>
      config is MetalAssetConfig ? config as MetalAssetConfig : null;

  Asset copyWith({
    String? name,
    AssetType? type,
    String? currency,
    String? color,
    Object? description = _assetFieldUnset,
    bool? isArchived,
    DateTime? updatedAt,
    LatestSnapshot? latestSnapshot,
    LatestSnapshot? previousSnapshot,
    Object? config = _assetFieldUnset,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      description: identical(description, _assetFieldUnset)
          ? this.description
          : description as String?,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latestSnapshot: latestSnapshot ?? this.latestSnapshot,
      previousSnapshot: previousSnapshot ?? this.previousSnapshot,
      config: identical(config, _assetFieldUnset)
          ? this.config
          : config as AssetConfig?,
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
    config,
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
