import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/assets_cubit.dart';
import '../../domain/entities/asset_type.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class AddAssetSheet extends StatefulWidget {
  const AddAssetSheet({super.key});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  AssetType _selectedType = AssetType.bank;
  String _selectedCurrency = 'PLN';
  String _selectedColor = '#4F6EF7';
  bool _isLoading = false;

  static const _typeColors = {
    AssetType.bank: '#4F6EF7',
    AssetType.broker: '#A855F7',
    AssetType.crypto: '#F59E0B',
    AssetType.metal: '#D4AF37',
    AssetType.cash: '#10B981',
    AssetType.other: '#64748B',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
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
                const Text('Nowe aktywo',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Type selector
            const Text('Typ aktywa', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AssetType.values.map((type) {
                final selected = type == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = type;
                    _selectedColor = _typeColors[type]!;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primarySurface : AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(type.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Nazwa aktywa',
                hintText: 'np. PKO Konto Oszczędnościowe',
                prefixIcon: Icon(Icons.label_outline, size: 20),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
            ),
            const SizedBox(height: 14),
            // Currency dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Waluta',
                prefixIcon: Icon(Icons.currency_exchange, size: 20),
              ),
              items: AppConstants.supportedCurrencies
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('$c  ${AppConstants.currencySymbols[c] ?? ''}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCurrency = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Opis (opcjonalnie)',
                prefixIcon: Icon(Icons.notes_outlined, size: 20),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Dodaj aktywo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await context.read<AssetsCubit>().addAsset(
      name: _nameController.text.trim(),
      type: _selectedType,
      currency: _selectedCurrency,
      color: _selectedColor,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }
}
