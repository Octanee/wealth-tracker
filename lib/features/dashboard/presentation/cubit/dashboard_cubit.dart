import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../assets/domain/repositories/assets_repository.dart';
import '../../../dashboard/domain/calculators/wealth_calculator.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required AssetsRepository repository})
      : _repository = repository,
        super(const DashboardInitial());

  final AssetsRepository _repository;
  StreamSubscription? _sub;
  String? _userId;

  void loadDashboard(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    emit(const DashboardLoading());
    _sub?.cancel();
    _sub = _repository.watchAssets(userId).listen(
      (assets) {
        final totals = WealthCalculator.totalByCurrency(assets);
        final allocs = WealthCalculator.allocationPercents(assets);
        emit(DashboardLoaded(
          assets: assets,
          totalByCurrency: totals,
          allocationPercents: allocs,
        ));
      },
      onError: (e) => emit(DashboardError(e.toString())),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
