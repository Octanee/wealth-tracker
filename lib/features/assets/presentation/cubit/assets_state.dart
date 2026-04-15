import 'package:equatable/equatable.dart';
import '../../domain/entities/asset.dart';

abstract class AssetsState extends Equatable {
  const AssetsState();
  @override
  List<Object?> get props => [];
}

class AssetsInitial extends AssetsState {
  const AssetsInitial();
}

class AssetsLoading extends AssetsState {
  const AssetsLoading();
}

class AssetsLoaded extends AssetsState {
  const AssetsLoaded(this.assets);
  final List<Asset> assets;
  @override
  List<Object?> get props => [assets];
}

class AssetsError extends AssetsState {
  const AssetsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
