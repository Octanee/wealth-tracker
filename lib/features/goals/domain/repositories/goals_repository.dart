import '../entities/goal.dart';
import '../entities/goal_type.dart';

abstract class GoalsRepository {
  /// Streams all goals for the user (portfolio + asset goals).
  Stream<List<Goal>> watchGoals(String userId);

  /// Streams only goals tied to a specific asset.
  Stream<List<Goal>> watchAssetGoals(String userId, String assetId);

  /// Streams only portfolio-level goals.
  Stream<List<Goal>> watchPortfolioGoals(String userId);

  Future<Goal> addGoal({
    required String userId,
    required String name,
    required GoalType type,
    required double targetValue,
    required String targetCurrency,
    String? assetId,
  });

  Future<void> updateGoal(String userId, Goal goal);

  Future<void> deleteGoal(String userId, String goalId);
}
