import 'package:equatable/equatable.dart';
import 'goal_type.dart';

class Goal extends Equatable {
  const Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.targetValue,
    required this.targetCurrency,
    required this.createdAt,
    this.assetId,
  });

  final String id;
  final String name;
  final GoalType type;
  final double targetValue;
  final String targetCurrency;
  final DateTime createdAt;

  /// Non-null when [type] == [GoalType.asset].
  final String? assetId;

  Goal copyWith({
    String? name,
    double? targetValue,
    String? targetCurrency,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      type: type,
      targetValue: targetValue ?? this.targetValue,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      createdAt: createdAt,
      assetId: assetId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    targetValue,
    targetCurrency,
    createdAt,
    assetId,
  ];
}
