import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/assets/presentation/cubit/assets_cubit.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/goals/presentation/cubit/goals_cubit.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pl_PL', null);
  await ServiceLocator.instance.setup();
  runApp(const WealthLensApp());
}

class WealthLensApp extends StatelessWidget {
  const WealthLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sl = ServiceLocator.instance;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            authRepository: sl.authRepository,
            analytics: sl.analyticsService,
          ),
        ),
        BlocProvider(
          create: (_) => AssetsCubit(
            repository: sl.assetsRepository,
            analytics: sl.analyticsService,
          ),
        ),
        BlocProvider(
          create: (_) => DashboardCubit(
            repository: sl.assetsRepository,
            portfolioValuationService: sl.portfolioValuationService,
            goldHistoryService: sl.goldHistoryService,
            analytics: sl.analyticsService,
          ),
        ),
        BlocProvider(
          create: (_) => SettingsCubit(
            authRepository: sl.authRepository,
            analytics: sl.analyticsService,
          ),
        ),
        BlocProvider(
          create: (_) => GoalsCubit(repository: sl.goalsRepository),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.create(context.read<AuthCubit>());
          return MaterialApp.router(
            title: 'WealthLens',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
