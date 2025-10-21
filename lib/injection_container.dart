// lib/injection_container.dart - FINAL VERSION
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Authentication imports
import 'armory/data/datasources/armory_remote_datasource.dart';
import 'armory/data/repositories/armory_repository_impl.dart';
import 'armory/domain/repositories/armory_repository.dart';
import 'armory/domain/services/armory_cache_service.dart';
import 'armory/domain/usecases/add_ammunition_usecase.dart' as user_add_ammo;
import 'armory/domain/usecases/add_firearm_usecase.dart';
import 'armory/domain/usecases/add_gear_usecase.dart';
import 'armory/domain/usecases/add_loadout_usecase.dart';
import 'armory/domain/usecases/add_maintenance_usecase.dart';
import 'armory/domain/usecases/add_tool_usecase.dart';
import 'armory/domain/usecases/delete_ammunition_usecase.dart';
import 'armory/domain/usecases/delete_firearm_usecase.dart';
import 'armory/domain/usecases/delete_gear_usecase.dart';
import 'armory/domain/usecases/delete_loadout_usecase.dart';
import 'armory/domain/usecases/delete_maintenance_usecase.dart';
import 'armory/domain/usecases/delete_tool_usecase.dart';
import 'armory/domain/usecases/get_ammunition_usecase.dart' as user_ammo;
import 'armory/domain/usecases/get_dropdown_options_usecase.dart';
import 'armory/domain/usecases/get_firearms_usecase.dart' as user_firearms;
import 'armory/domain/usecases/get_gear_usecase.dart';
import 'armory/domain/usecases/get_loadouts_usecase.dart';
import 'armory/domain/usecases/get_maintenance_usecase.dart';
import 'armory/domain/usecases/get_tools_usecase.dart';
import 'armory/presentation/bloc/armory_bloc.dart';
import 'authentication/data/datasources/auth_remote_datasource.dart';
import 'authentication/data/repositories/auth_repository_impl.dart';
import 'authentication/domain/repositories/auth_repository.dart';
import 'authentication/domain/usecases/get_current_user_usecase.dart';
import 'authentication/domain/usecases/google_signin_usecase.dart';
import 'authentication/domain/usecases/login_usecase.dart';
import 'authentication/domain/usecases/logout_usecase.dart';
import 'authentication/domain/usecases/signup_usecase.dart';
import 'authentication/presentation/bloc/login_bloc/auth_bloc.dart';
import 'authentication/presentation/bloc/signup_bloc/signup_bloc.dart';


import 'core/usecases/usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // =============== BLoC ===============
  sl.registerFactory(
        () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      googleSignInUseCase: sl(),
    ),
  );

  sl.registerFactory(
        () => SignupBloc(
      signupUseCase: sl(),
      googleSignInUseCase: sl(),
    ),
  );


  // Clean Architecture ArmoryBloc - Original Interface Preserved
  sl.registerFactory(
        () => ArmoryBloc(
      getFirearmsUseCase: sl<user_firearms.GetFirearmsUseCase>(),
      addFirearmUseCase: sl(),
      getAmmunitionUseCase: sl<user_ammo.GetAmmunitionUseCase>(),
      addAmmunitionUseCase: sl<user_add_ammo.AddAmmunitionUseCase>(),
      getGearUseCase: sl(),
      addGearUseCase: sl(),
      getToolsUseCase: sl(),
      addToolUseCase: sl(),
      getLoadoutsUseCase: sl(),
      addLoadoutUseCase: sl(),
      getDropdownOptionsUseCase: sl(),
      getMaintenanceUseCase: sl(),
      addMaintenanceUseCase: sl(),
      deleteFirearmUseCase: sl(),
      deleteAmmunitionUseCase: sl(),
      deleteGearUseCase: sl(),
      deleteLoadoutUseCase: sl(),
      deleteMaintenanceUseCase: sl(),
      deleteToolUseCase: sl(),
    ),
  );

  // =============== Use Cases - Authentication ===============
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(sl()));


  // =============== Clean Architecture Use Cases - User Dashboard ===============
  // Basic CRUD Use Cases (Pure Repository Operations)
  sl.registerLazySingleton(() => user_firearms.GetFirearmsUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => AddFirearmUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => user_ammo.GetAmmunitionUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => user_add_ammo.AddAmmunitionUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => GetGearUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => AddGearUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => GetToolsUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => AddToolUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => GetLoadoutsUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => AddLoadoutUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => GetMaintenanceUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => AddMaintenanceUseCase(sl<ArmoryRepository>()));

  // Delete Use Cases
  sl.registerLazySingleton(() => DeleteFirearmUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => DeleteAmmunitionUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => DeleteGearUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => DeleteToolUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => DeleteLoadoutUseCase(sl<ArmoryRepository>()));
  sl.registerLazySingleton(() => DeleteMaintenanceUseCase(sl<ArmoryRepository>()));

  // Business Logic Use Cases (Contains Complex Logic)
  sl.registerLazySingleton(() => GetDropdownOptionsUseCase(sl<ArmoryRepository>(), sl<FirebaseAuth>()));

  // =============== Domain Services ===============
  sl.registerLazySingleton<ArmoryDataCacheService>(() => ArmoryDataCacheServiceImpl());

  // =============== Repositories - Clean Implementation ===============
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Pure Repository Implementation (No Business Logic)
  sl.registerLazySingleton<ArmoryRepository>(
        () => ArmoryRepositoryImpl(remoteDataSource: sl()),
  );

  // =============== Data Sources ===============
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(),
    ),
  );


  sl.registerLazySingleton<ArmoryRemoteDataSource>(
        () => ArmoryRemoteDataSourceImpl(firestore: sl()),
  );

  // =============== External Dependencies ===============
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
}