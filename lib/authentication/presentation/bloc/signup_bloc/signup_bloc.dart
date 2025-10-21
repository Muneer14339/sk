import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../domain/usecases/signup_usecase.dart';
import '../../../domain/usecases/google_signin_usecase.dart';
import 'signup_event.dart';
import 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final SignupUseCase signupUseCase;
  final GoogleSignInUseCase googleSignInUseCase;

  SignupBloc({
    required this.signupUseCase,
    required this.googleSignInUseCase,
  }) : super(const SignupInitial()) {
    on<SignupRequested>(_onSignupRequested);
    on<GoogleSignUpRequested>(_onGoogleSignUpRequested);
  }

  void _onSignupRequested(SignupRequested event, Emitter<SignupState> emit) async {
    emit(const SignupLoading());

    final result = await signupUseCase(
      SignupParams(
        firstName: event.firstName,
        email: event.email,
        password: event.password,
        location: event.location,
      ),
    );

    result.fold(
          (failure) {
        // Extract clean error message
        final message = failure is AuthFailure
            ? failure.message
            : 'Signup failed. Please try again';
        emit(SignupError(message));
      },
          (user) => emit(SignupSuccess(user)),
    );
  }

  void _onGoogleSignUpRequested(GoogleSignUpRequested event, Emitter<SignupState> emit) async {
    emit(const SignupLoading());

    final result = await googleSignInUseCase(const NoParams());

    result.fold(
          (failure) {
        // Extract clean error message
        final message = failure is AuthFailure
            ? failure.message
            : 'Google sign-up failed. Please try again';
        emit(SignupError(message));
      },
          (user) => emit(SignupSuccess(user)),
    );
  }
}