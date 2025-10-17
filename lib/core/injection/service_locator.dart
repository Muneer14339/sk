import 'package:get_it/get_it.dart';
import 'package:pulse_skadi/features/auth/data/remote/service/auth_service.dart';
import 'package:pulse_skadi/features/auth/data/repositories/auth_repo_impl.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/check_auth_status.dart';
import 'package:pulse_skadi/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/sign_out.dart';
import 'package:pulse_skadi/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:pulse_skadi/features/training/data/repositories/ble_repository_impl.dart';
import 'package:pulse_skadi/features/training/data/repositories/session_details_repository_impl.dart';
import 'package:pulse_skadi/features/training/data/datasources/session_details_local_datasource.dart';
import 'package:pulse_skadi/features/training/data/datasources/session_details_remote_datasource.dart';
import 'package:pulse_skadi/features/training/domain/repositories/ble_repository.dart';
import 'package:pulse_skadi/features/training/domain/repositories/session_details_repository.dart';
import 'package:pulse_skadi/features/training/domain/usecases/export_session_data.dart';
import 'package:pulse_skadi/features/training/domain/usecases/get_session_details.dart';
import 'package:pulse_skadi/features/training/domain/usecases/share_session_results.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/ble_scan/ble_scan_bloc.dart';
import 'package:pulse_skadi/features/training/presentation/bloc/training_session/training_session_bloc.dart';
import 'package:pulse_skadi/features/training/data/model/programs_model.dart';
import 'package:pulse_skadi/core/network/network_info.dart';
import 'package:pulse_skadi/core/network/api_client.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(
      () => BleScanBloc(bleRepository: sl(), trainingSessionBloc: sl()));
  sl.registerFactory(() => TrainingSessionBloc(bleRepository: sl()));

  // Services

  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<ProgramsModel>(() => ProgramsModel());

  // Network Dependencies
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  // sl.registerLazySingleton<http.Client>(() => http.Client());
  sl.registerLazySingleton<ApiClient>(() => ApiClient(
        client: sl(),
        networkInfo: sl(),
      ));

  // Repositories

  sl.registerLazySingleton<SignInWithEmailAndPassword>(
    () => SignInWithEmailAndPassword(sl()),
  );

  sl.registerLazySingleton<SignUpWithEmailAndPassword>(
    () => SignUpWithEmailAndPassword(sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SignOut>(
    () => SignOut(sl()),
  );

  sl.registerLazySingleton<CheckAuthStatus>(
    () => CheckAuthStatus(sl()),
  );
  sl.registerLazySingleton<BleRepository>(
    () => BleRepositoryImpl(),
  );
  sl.registerLazySingleton<BleRepositoryImpl>(
    () => BleRepositoryImpl(),
  );
  sl.registerLazySingleton<GetSessionDetails>(
    () => GetSessionDetails(sl()),
  );
  sl.registerLazySingleton<ExportSessionData>(
    () => ExportSessionData(sl()),
  );
  sl.registerLazySingleton<ShareSessionResults>(
    () => ShareSessionResults(sl()),
  );

  // Session Details Dependencies
  sl.registerLazySingleton<SessionDetailsRemoteDataSource>(
    () => SessionDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SessionDetailsLocalDataSource>(
    () => SessionDetailsLocalDataSourceImpl(),
  );
  sl.registerLazySingleton<SessionDetailsRepository>(
    () => SessionDetailsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
}
