import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.baseCurrency,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String baseCurrency;

  UserEntity copyWith({String? baseCurrency, String? displayName}) {
    return UserEntity(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl,
      baseCurrency: baseCurrency ?? this.baseCurrency,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, baseCurrency];
}
