import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_type.dart';
import '../../domain/repositories/goals_repository.dart';
import 'goals_state.dart';

class GoalsCubit extends Cubit<GoalsState> {
  GoalsCubit({required GoalsRepository repository})
      : _repository = repository,
        super(const GoalsInitial());

  final GoalsRepository _repository;
  StreamSubscription? _sub;
  String? _userId;

  void loadGoals(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    emit(const GoalsLoading());
    _sub?.cancel();
    _sub = _repository.watchGoals(userId).listen(
      (goals) => emit(GoalsLoaded(goals)),
      onError: (e) => emit(GoalsError(e.toString())),
    );
  }

  Future<String?> addGoal({
    required String name,
    required GoalType type,
    required double targetValue,
    required String targetCurrency,
    String? assetId,
  }) async {
    if (_userId == null) return 'Użytkownik nie jest zalogowany';
    try {
      await _repository.addGoal(
        userId: _userId!,
        name: name,
        type: type,
        targetValue: targetValue,
        targetCurrency: targetCurrency,
        assetId: assetId,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateGoal(Goal goal) async {
    if (_userId == null) return 'Użytkownik nie jest zalogowany';
    try {
      await _repository.updateGoal(_userId!, goal);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteGoal(String goalId) async {
    if (_userId == null) return 'Użytkownik nie jest zalogowany';
    try {
      await _repository.deleteGoal(_userId!, goalId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
