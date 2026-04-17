import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_type.dart';
import '../../domain/repositories/goals_repository.dart';
import '../models/goal_model.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  GoalsRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference _goalsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  @override
  Stream<List<Goal>> watchGoals(String userId) {
    return _goalsCol(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GoalModel.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Stream<List<Goal>> watchAssetGoals(String userId, String assetId) {
    return _goalsCol(userId)
        .where('assetId', isEqualTo: assetId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GoalModel.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Stream<List<Goal>> watchPortfolioGoals(String userId) {
    return _goalsCol(userId)
        .where('type', isEqualTo: 'portfolio')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GoalModel.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  @override
  Future<Goal> addGoal({
    required String userId,
    required String name,
    required GoalType type,
    required double targetValue,
    required String targetCurrency,
    String? assetId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final model = GoalModel(
      id: id,
      name: name,
      type: type,
      targetValue: targetValue,
      targetCurrency: targetCurrency,
      createdAt: now,
      assetId: assetId,
    );
    await _goalsCol(userId).doc(id).set(model.toMap());
    return model.toDomain();
  }

  @override
  Future<void> updateGoal(String userId, Goal goal) async {
    final model = GoalModel.fromDomain(goal);
    await _goalsCol(userId).doc(goal.id).update({
      'name': model.name,
      'targetValue': model.targetValue,
    });
  }

  @override
  Future<void> deleteGoal(String userId, String goalId) async {
    await _goalsCol(userId).doc(goalId).delete();
  }
}
