import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_type.dart';

class GoalModel {
  const GoalModel({
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
  final String? assetId;

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      name: data['name'] as String,
      type: data['type'] == 'portfolio' ? GoalType.portfolio : GoalType.asset,
      targetValue: (data['targetValue'] as num).toDouble(),
      targetCurrency: data['targetCurrency'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      assetId: data['assetId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type == GoalType.portfolio ? 'portfolio' : 'asset',
      'targetValue': targetValue,
      'targetCurrency': targetCurrency,
      'createdAt': Timestamp.fromDate(createdAt),
      'assetId': assetId,
    };
  }

  Goal toDomain() => Goal(
    id: id,
    name: name,
    type: type,
    targetValue: targetValue,
    targetCurrency: targetCurrency,
    createdAt: createdAt,
    assetId: assetId,
  );

  factory GoalModel.fromDomain(Goal goal) => GoalModel(
    id: goal.id,
    name: goal.name,
    type: goal.type,
    targetValue: goal.targetValue,
    targetCurrency: goal.targetCurrency,
    createdAt: goal.createdAt,
    assetId: goal.assetId,
  );
}
