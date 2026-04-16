import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../../features/auth/presentation/cubit/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sync user from auth state
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<SettingsCubit>().loadUser(authState.user);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ustawienia',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final user = state is SettingsLoaded
              ? state.user
              : state is SettingsSaving
              ? state.user
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user != null) _ProfileCard(user: user),
                const SizedBox(height: 20),
                if (user != null)
                  _CurrencySection(
                    user: user,
                    isSaving: state is SettingsSaving,
                  ),
                const SizedBox(height: 20),
                _AboutSection(),
                const SizedBox(height: 20),
                _LogoutButton(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (user.displayName?.isNotEmpty == true
                        ? user.displayName![0]
                        : user.email[0])
                    .toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Użytkownik',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencySection extends StatelessWidget {
  const _CurrencySection({required this.user, required this.isSaving});
  final dynamic user;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Waluta bazowa',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Wybierz walutę, w której mają być przeliczane wartości w dashboardzie i widokach aktywów.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isSaving
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: user.baseCurrency,
                    dropdownColor: AppColors.cardBg,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_exchange, size: 18),
                    ),
                    items: AppConstants.nbpSupportedCurrencies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '$c  ${AppConstants.currencySymbols[c] ?? ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsCubit>().updateBaseCurrency(v);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.info_outline,
            label: 'Wersja aplikacji',
            value: '1.0.0 MVP',
          ),
          const Divider(height: 1),
          _InfoTile(
            icon: Icons.security_outlined,
            label: 'Dane',
            value: 'Przechowywane w Firebase',
          ),
          const Divider(height: 1),
          _InfoTile(
            icon: Icons.lock_outline,
            label: 'Prywatność',
            value: 'Tylko Twoje dane',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Wylogowanie'),
            content: const Text('Czy na pewno chcesz się wylogować?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Wyloguj',
                  style: TextStyle(color: AppColors.negative),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          context.read<AuthCubit>().signOut();
        }
      },
      icon: const Icon(Icons.logout, color: AppColors.negative),
      label: const Text(
        'Wyloguj się',
        style: TextStyle(color: AppColors.negative),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.negativeSurface),
      ),
    );
  }
}
