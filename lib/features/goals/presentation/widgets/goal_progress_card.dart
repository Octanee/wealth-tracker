import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/goal.dart';
import '../cubit/goals_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import 'add_goal_sheet.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.goal,
    required this.currentValue,
  });

  final Goal goal;

  /// The current value in the same currency as [goal.targetCurrency].
  final double currentValue;

  double get _progress {
    if (goal.targetValue <= 0) return 0;
    return (currentValue / goal.targetValue).clamp(0.0, 1.0);
  }

  bool get _isAchieved => currentValue >= goal.targetValue;

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final percent = (progress * 100).toStringAsFixed(1);
    final achieved = _isAchieved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achieved
              ? AppColors.positive.withAlpha(100)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (achieved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.positiveSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Osiągnięty ✓',
                    style: TextStyle(
                      color: AppColors.positive,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              _GoalMenu(goal: goal),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.cardBgLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                achieved ? AppColors.positive : AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.format(currentValue, goal.targetCurrency),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$percent% / ',
                      style: TextStyle(
                        color: achieved
                            ? AppColors.positive
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: CurrencyFormatter.format(
                        goal.targetValue,
                        goal.targetCurrency,
                      ),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalMenu extends StatelessWidget {
  const _GoalMenu({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_GoalMenuAction>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textMuted,
        size: 18,
      ),
      color: AppColors.cardBg,
      onSelected: (action) async {
        switch (action) {
          case _GoalMenuAction.edit:
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => BlocProvider.value(
                value: context.read<GoalsCubit>(),
                child: AddGoalSheet(
                    goalType: goal.type,
                    initialGoal: goal,
                  ),
              ),
            );
          case _GoalMenuAction.delete:
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Usunąć cel?'),
                content: Text(
                  'Cel "${goal.name}" zostanie trwale usunięty.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Anuluj'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Usuń',
                      style: TextStyle(color: AppColors.negative),
                    ),
                  ),
                ],
              ),
            );
            if (confirmed != true || !context.mounted) return;
            final error = await context.read<GoalsCubit>().deleteGoal(goal.id);
            if (error != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _GoalMenuAction.edit,
          child: Text('Edytuj cel'),
        ),
        PopupMenuItem(
          value: _GoalMenuAction.delete,
          child: Text(
            'Usuń cel',
            style: TextStyle(color: AppColors.negative),
          ),
        ),
      ],
    );
  }
}

enum _GoalMenuAction { edit, delete }
