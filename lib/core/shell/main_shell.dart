import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _routes = ['/dashboard', '/assets', '/settings'];

  static const _destinations = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Aktywa'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Ustawienia'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    var index = _routes.indexWhere((r) => location.startsWith(r));
    if (index < 0) index = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return isDesktop
            ? _DesktopLayout(
                destinations: _destinations,
                currentIndex: index,
                onDestinationSelected: (i) => context.go(_routes[i]),
                child: child,
              )
            : _MobileLayout(
                destinations: _destinations,
                currentIndex: index,
                onDestinationSelected: (i) => context.go(_routes[i]),
                child: child,
              );
      },
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.child,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final List<_NavItem> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.activeIcon),
                    label: d.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.child,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final Widget child;
  final List<_NavItem> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.divider)),
            ),
            child: NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onDestinationSelected,
              extended: true,
              minExtendedWidth: 220,
              leading: const _NavRailHeader(),
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.activeIcon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavRailHeader extends StatelessWidget {
  const _NavRailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'WealthLens',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
