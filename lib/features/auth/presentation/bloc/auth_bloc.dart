import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_skadi/core/errors/failures.dart';
import 'package:pulse_skadi/core/services/prefs.dart';
import 'package:pulse_skadi/core/usecases/usecase.dart';
import 'package:pulse_skadi/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/check_auth_status.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/sign_out.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:pulse_skadi/features/auth/presentation/bloc/auth_event.dart';
import 'package:pulse_skadi/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckAuthStatus checkAuthStatus;
  final SignInWithEmailAndPassword signInWithEmailAndPassword;
  final SignUpWithEmailAndPassword signUpWithEmailAndPassword;
  final SignOut signOut;

  AuthBloc({
    required this.checkAuthStatus,
    required this.signInWithEmailAndPassword,
    required this.signUpWithEmailAndPassword,
    required this.signOut,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithEmailAndPasswordEvent>(_onSignInWithEmailAndPassword);
    on<SignUpWithEmailAndPasswordEvent>(_onSignUpWithEmailAndPassword);
    on<SignOutEvent>(_onSignOut);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await checkAuthStatus(NoParams());

    result.fold(
      (failure) => emit(Unauthenticated()),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignInWithEmailAndPassword(
    SignInWithEmailAndPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await signInWithEmailAndPassword(
      SignInWithEmailAndPasswordParams(
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(Authenticated(
          UserEntity(id: user.user!.uid, email: user.user!.email!))),
    );
  }

  Future<void> _onSignUpWithEmailAndPassword(
    SignUpWithEmailAndPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await signUpWithEmailAndPassword(
      SignUpWithEmailAndPasswordParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(Authenticated(
          UserEntity(id: user.user!.uid, email: user.user!.email!))),
    );
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    prefs?.clear();
    final result = await signOut(SignOutParams());
    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(Unauthenticated()),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server error: ${failure.message}';
      case CacheFailure _:
        return 'Cache error: ${failure.message}';
      case NetworkFailure _:
        return 'Network error: ${failure.message}';
      case ValidationFailure _:
        return 'Validation error: ${failure.message}';
      case UnauthorizedFailure _:
        return 'Unauthorized: ${failure.message}';
      case NotFoundFailure _:
        return 'Not found: ${failure.message}';
      default:
        return 'Unexpected error: ${failure.message}';
    }
  }
}
