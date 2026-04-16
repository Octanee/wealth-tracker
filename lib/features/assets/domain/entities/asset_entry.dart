import 'package:equatable/equatable.dart';

class AssetEntry extends Equatable {
  const AssetEntry({
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
  final DateTime recordedAt; // date chosen by user
  final DateTime createdAt; // technical write timestamp

  @override
  List<Object?> get props => [id, assetId, value, note, recordedAt, createdAt];
}
