import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/asset_entry.dart';
import '../cubit/asset_detail_state.dart';
import '../cubit/asset_detail_cubit.dart';
import '../../../../core/theme/app_colors.dart';

class AddEntrySheet extends StatefulWidget {
  const AddEntrySheet({
    super.key,
    required this.currency,
    this.valueLabel = 'Wartość',
    this.valueIcon = Icons.attach_money_outlined,
    this.valueHintText,
    this.maxDecimalPlaces = 2,
    this.initialEntry,
    this.lockDate = false,
  });
  final String currency;
  final String valueLabel;
  final IconData valueIcon;
  final String? valueHintText;
  final int maxDecimalPlaces;
  final AssetEntry? initialEntry;
  final bool lockDate;

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      _selectedDate = DateUtils.dateOnly(widget.initialEntry!.recordedAt);
      _valueController.text = widget.initialEntry!.value.toString().replaceAll(
        '.',
        ',',
      );
      _noteController.text = widget.initialEntry!.note ?? '';
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncWithSelectedDate();
      }
    });
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
                  widget.initialEntry == null
                      ? 'Nowy wpis wartości'
                      : 'Edytuj wpis wartości',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  if (text.isEmpty) return newValue;
                  // Allow only digits and at most one decimal separator.
                  // Optional decimal part is limited by maxDecimalPlaces.
                  final validPattern = RegExp(
                    '^\\d+([\\.,]\\d{0,' +
                        widget.maxDecimalPlaces.toString() +
                        '})?',
                  );
                  final match = validPattern.matchAsPrefix(text);
                  if (match != null && match.end == text.length) {
                    return newValue;
                  }
                  return oldValue;
                }),
              ],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: widget.valueLabel,
                hintText: widget.valueHintText,
                suffixText: widget.currency,
                suffixStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Icon(widget.valueIcon, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wymagana wartość';
                final normalized = v.replaceAll(',', '.');
                final validPattern = RegExp(r'^\d+(\.\d+)?$');
                if (!validPattern.hasMatch(normalized)) {
                  return 'Wpisz poprawną liczbę';
                }
                final val = double.tryParse(normalized);
                if (val == null) return 'Nieprawidłowa liczba';
                if (val < 0) return 'Wartość nie może być ujemna';
                return null;
              },
            ),
            const SizedBox(height: 14),
            // Date picker
            InkWell(
              onTap: widget.lockDate ? null : _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Data: ${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      widget.lockDate
                          ? Icons.lock_outline
                          : Icons.chevron_right,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Notatka (opcjonalnie)',
                prefixIcon: Icon(Icons.notes_outlined, size: 20),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 28),
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
                  : Text(
                      widget.initialEntry == null
                          ? 'Zapisz wpis'
                          : 'Zapisz zmiany',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    if (widget.lockDate) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _syncWithSelectedDate();
    }
  }

  void _syncWithSelectedDate() {
    final state = context.read<AssetDetailCubit>().state;
    if (state is! AssetDetailLoaded) return;

    final selectedDay = DateUtils.dateOnly(_selectedDate);
    AssetEntry? existingEntry;
    for (final entry in state.entries) {
      final entryDay = DateUtils.dateOnly(entry.recordedAt);
      if (DateUtils.isSameDay(entryDay, selectedDay)) {
        existingEntry = entry;
        break;
      }
    }

    if (existingEntry == null) {
      _valueController.clear();
      _noteController.clear();
      return;
    }

    _valueController.text = existingEntry.value.toString().replaceAll('.', ',');
    _noteController.text = existingEntry.note ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AssetDetailCubit>().state;
    if (state is AssetDetailLoaded) {
      final selectedDay = DateUtils.dateOnly(_selectedDate);
      AssetEntry? existingEntry;
      for (final entry in state.entries) {
        final entryDay = DateUtils.dateOnly(entry.recordedAt);
        if (DateUtils.isSameDay(entryDay, selectedDay)) {
          existingEntry = entry;
          break;
        }
      }

      if (existingEntry != null) {
        final confirmed = await _confirmOverwrite();
        if (confirmed != true) return;
        if (!mounted) return;
      }
    }

    setState(() => _isLoading = true);
    final value = double.parse(_valueController.text.replaceAll(',', '.'));
    final errorMessage = await context.read<AssetDetailCubit>().addEntry(
      value: value,
      recordedAt: _selectedDate,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (errorMessage == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<bool?> _confirmOverwrite() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nadpisać wpis?'),
        content: const Text(
          'Dla wybranego dnia wpis już istnieje. Zapisanie nadpisze obecną wartość.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Nadpisz'),
          ),
        ],
      ),
    );
  }
}
