import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_type.dart';
import '../cubit/goals_cubit.dart';
import '../../../../core/theme/app_colors.dart';

class AddGoalSheet extends StatefulWidget {
  const AddGoalSheet({
    super.key,
    required this.goalType,
    this.targetCurrency,
    this.assetId,
    this.initialGoal,
  });

  /// Type of goal being created. Ignored when [initialGoal] is provided.
  final GoalType goalType;

  /// Currency label shown next to the target value field.
  final String? targetCurrency;

  /// Required when [goalType] == [GoalType.asset].
  final String? assetId;

  /// When provided the sheet operates in edit mode.
  final Goal? initialGoal;

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  bool _isLoading = false;

  bool get _isEditMode => widget.initialGoal != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialGoal?.name ?? '',
    );
    _targetController = TextEditingController(
      text: widget.initialGoal != null
          ? widget.initialGoal!.targetValue.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  String get _currency =>
      widget.initialGoal?.targetCurrency ??
      widget.targetCurrency ??
      '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final targetValue = double.parse(
      _targetController.text.trim().replaceAll(',', '.'),
    );

    String? error;
    if (_isEditMode) {
      final updated = widget.initialGoal!.copyWith(
        name: name,
        targetValue: targetValue,
      );
      error = await context.read<GoalsCubit>().updateGoal(updated);
    } else {
      error = await context.read<GoalsCubit>().addGoal(
        name: name,
        type: widget.goalType,
        targetValue: targetValue,
        targetCurrency: _currency,
        assetId: widget.assetId,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  _isEditMode ? 'Edytuj cel' : 'Nowy cel',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nazwa celu',
                hintText: 'np. Fundusz awaryjny',
                prefixIcon: Icon(Icons.flag_outlined, size: 20),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Wymagane' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _targetController,
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Wartość docelowa',
                hintText: 'np. 50000',
                prefixIcon: const Icon(Icons.track_changes_outlined, size: 20),
                suffixText: _currency,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wymagane';
                final parsed = double.tryParse(
                  v.trim().replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) {
                  return 'Podaj wartość większą od zera';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditMode ? 'Zapisz zmiany' : 'Dodaj cel'),
            ),
          ],
        ),
      ),
    );
  }
}
