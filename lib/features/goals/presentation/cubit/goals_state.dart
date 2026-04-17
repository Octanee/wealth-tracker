import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';

abstract class GoalsState extends Equatable {
  const GoalsState();
  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {
  const GoalsInitial();
}

class GoalsLoading extends GoalsState {
  const GoalsLoading();
}

class GoalsLoaded extends GoalsState {
  const GoalsLoaded(this.goals);
  final List<Goal> goals;
  @override
  List<Object?> get props => [goals];
}

class GoalsError extends GoalsState {
  const GoalsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
