import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/google_signin_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final GoogleSignInUseCase googleSignInUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.googleSignInUseCase,
  }) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckLoginStatus>(_onCheckLoginStatus);
  }

  void _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
          (failure) {
        // Extract clean error message
        final message = failure is AuthFailure
            ? (failure as AuthFailure).message
            : 'Login failed. Please try again';
        emit(AuthError(message));
      },
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  void _onGoogleSignInRequested(GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await googleSignInUseCase(const NoParams());

    result.fold(
          (failure) {
        // Extract clean error message
        final message = failure is AuthFailure
            ? (failure as AuthFailure).message
            : 'Google sign-in failed. Please try again';
        emit(AuthError(message));
      },
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await logoutUseCase(const NoParams());

    result.fold(
          (failure) {
        // Extract clean error message
        final message = failure is AuthFailure
            ? (failure as AuthFailure).message
            : 'Logout failed. Please try again';
        emit(AuthError(message));
      },
          (_) => emit(const AuthUnauthenticated()),
    );
  }

  void _onCheckLoginStatus(CheckLoginStatus event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase(const NoParams());

    result.fold(
          (failure) => emit(const AuthUnauthenticated()),
          (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }
}