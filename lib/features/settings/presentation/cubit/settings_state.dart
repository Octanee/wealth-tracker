import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded(this.user);
  final UserEntity user;
  @override
  List<Object?> get props => [user];
}

class SettingsSaving extends SettingsState {
  const SettingsSaving(this.user);
  final UserEntity user;
  @override
  List<Object?> get props => [user];
}
