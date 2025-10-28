import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../domain/entities/armory_ammunition.dart';
import '../../domain/entities/armory_firearm.dart';
import '../../domain/entities/armory_gear.dart';
import '../../domain/entities/armory_loadout.dart';
import '../../domain/entities/armory_maintenance.dart';
import '../../domain/entities/armory_tool.dart';
import '../../domain/usecases/add_maintenance_usecase.dart';
import '../../domain/usecases/delete_ammunition_usecase.dart';
import '../../domain/usecases/delete_firearm_usecase.dart';
import '../../domain/usecases/delete_gear_usecase.dart';
import '../../domain/usecases/delete_loadout_usecase.dart';
import '../../domain/usecases/delete_maintenance_usecase.dart';
import '../../domain/usecases/delete_tool_usecase.dart';
import '../../domain/usecases/get_firearms_usecase.dart';
import '../../domain/usecases/add_firearm_usecase.dart';
import '../../domain/usecases/get_ammunition_usecase.dart';
import '../../domain/usecases/add_ammunition_usecase.dart';
import '../../domain/usecases/get_gear_usecase.dart';
import '../../domain/usecases/add_gear_usecase.dart';
import '../../domain/usecases/get_maintenance_usecase.dart';
import '../../domain/usecases/get_tools_usecase.dart';
import '../../domain/usecases/add_tool_usecase.dart';
import '../../domain/usecases/get_loadouts_usecase.dart';
import '../../domain/usecases/add_loadout_usecase.dart';
import 'armory_event.dart';
import 'armory_state.dart';

class ArmoryBloc extends Bloc<ArmoryEvent, ArmoryState> {
  final GetFirearmsUseCase getFirearmsUseCase;
  final GetAmmunitionUseCase getAmmunitionUseCase;
  final GetGearUseCase getGearUseCase;
  final GetToolsUseCase getToolsUseCase;
  final GetLoadoutsUseCase getLoadoutsUseCase;
  final GetMaintenanceUseCase getMaintenanceUseCase;
  final AddFirearmUseCase addFirearmUseCase;
  final AddAmmunitionUseCase addAmmunitionUseCase;
  final AddGearUseCase addGearUseCase;
  final AddToolUseCase addToolUseCase;
  final AddLoadoutUseCase addLoadoutUseCase;
  final AddMaintenanceUseCase addMaintenanceUseCase;
  final DeleteFirearmUseCase deleteFirearmUseCase;
  final DeleteAmmunitionUseCase deleteAmmunitionUseCase;
  final DeleteGearUseCase deleteGearUseCase;
  final DeleteToolUseCase deleteToolUseCase;
  final DeleteMaintenanceUseCase deleteMaintenanceUseCase;
  final DeleteLoadoutUseCase deleteLoadoutUseCase;

  ArmoryBloc({
    required this.getFirearmsUseCase,
    required this.addFirearmUseCase,
    required this.deleteFirearmUseCase,
    required this.getAmmunitionUseCase,
    required this.addAmmunitionUseCase,
    required this.deleteAmmunitionUseCase,
    required this.getGearUseCase,
    required this.addGearUseCase,
    required this.deleteGearUseCase,
    required this.getToolsUseCase,
    required this.addToolUseCase,
    required this.deleteToolUseCase,
    required this.getLoadoutsUseCase,
    required this.addLoadoutUseCase,
    required this.deleteLoadoutUseCase,
    required this.getMaintenanceUseCase,
    required this.addMaintenanceUseCase,
    required this.deleteMaintenanceUseCase,
  }) : super(const ArmoryInitial()) {
    on<LoadAllDataEvent>(_onLoadAllData);
    on<AddFirearmEvent>(_onAddFirearm);
    on<AddAmmunitionEvent>(_onAddAmmunition);
    on<AddGearEvent>(_onAddGear);
    on<AddToolEvent>(_onAddTool);
    on<AddLoadoutEvent>(_onAddLoadout);
    on<AddMaintenanceEvent>(_onAddMaintenance);
    on<DeleteFirearmEvent>(_onDeleteFirearm);
    on<DeleteAmmunitionEvent>(_onDeleteAmmunition);
    on<DeleteGearEvent>(_onDeleteGear);
    on<DeleteToolEvent>(_onDeleteTool);
    on<DeleteMaintenanceEvent>(_onDeleteMaintenance);
    on<DeleteLoadoutEvent>(_onDeleteLoadout);
    on<ShowAddFormEvent>(_onShowAddForm);
    on<HideFormEvent>(_onHideForm);
  }

  void _onLoadAllData(LoadAllDataEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final results = await Future.wait([
      getFirearmsUseCase(UserIdParams(userId: event.userId)),
      getAmmunitionUseCase(UserIdParams(userId: event.userId)),
      getGearUseCase(UserIdParams(userId: event.userId)),
      getToolsUseCase(UserIdParams(userId: event.userId)),
      getLoadoutsUseCase(UserIdParams(userId: event.userId)),
      getMaintenanceUseCase(UserIdParams(userId: event.userId)),
    ]);

    final firearms = results[0].fold((l) => <ArmoryFirearm>[], (r) => r);
    final ammunition = results[1].fold((l) => <ArmoryAmmunition>[], (r) => r);
    final gear = results[2].fold((l) => <ArmoryGear>[], (r) => r);
    final tools = results[3].fold((l) => <ArmoryTool>[], (r) => r);
    final loadouts = results[4].fold((l) => <ArmoryLoadout>[], (r) => r);
    final maintenance = results[5].fold((l) => <ArmoryMaintenance>[], (r) => r);

    emit(ArmoryDataLoaded(
      firearms: firearms.cast<ArmoryFirearm>(),
      ammunition: ammunition.cast<ArmoryAmmunition>(),
      gear: gear.cast<ArmoryGear>(),
      tools: tools.cast<ArmoryTool>(),
      loadouts: loadouts.cast<ArmoryLoadout>(),
      maintenance: maintenance.cast<ArmoryMaintenance>(),
    ));
  }

  void _onAddFirearm(AddFirearmEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addFirearmUseCase(
      AddFirearmParams(userId: event.userId, firearm: event.firearm),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) async {
        emit(const ArmoryActionSuccess(message: 'Firearm added successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onAddAmmunition(AddAmmunitionEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addAmmunitionUseCase(
      AddAmmunitionParams(userId: event.userId, ammunition: event.ammunition),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Ammunition added successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onAddGear(AddGearEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addGearUseCase(
      AddGearParams(userId: event.userId, gear: event.gear),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Gear added successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onAddTool(AddToolEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addToolUseCase(
      AddToolParams(userId: event.userId, tool: event.tool),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Tool added successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onAddLoadout(AddLoadoutEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addLoadoutUseCase(
      AddLoadoutParams(userId: event.userId, loadout: event.loadout),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Loadout added successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onAddMaintenance(AddMaintenanceEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addMaintenanceUseCase(
      AddMaintenanceParams(userId: event.userId, maintenance: event.maintenance),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Maintenance log added successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteFirearm(DeleteFirearmEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteFirearmUseCase(
      DeleteFirearmParams(userId: event.userId, firearm: event.firearm),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Firearm deleted successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteAmmunition(DeleteAmmunitionEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteAmmunitionUseCase(
      DeleteAmmunitionParams(userId: event.userId, ammunition: event.ammunition),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Ammunition deleted successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteGear(DeleteGearEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteGearUseCase(
      DeleteGearParams(userId: event.userId, gear: event.gear),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Gear deleted successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteTool(DeleteToolEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteToolUseCase(
      DeleteToolParams(userId: event.userId, tool: event.tool),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Tool deleted successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteMaintenance(DeleteMaintenanceEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteMaintenanceUseCase(
      DeleteMaintenanceParams(userId: event.userId, maintenance: event.maintenance),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Maintenance deleted successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }

  void _onDeleteLoadout(DeleteLoadoutEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteLoadoutUseCase(
      DeleteLoadoutParams(userId: event.userId, loadout: event.loadout),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Loadout deleted successfully!'));
        add(LoadAllDataEvent(userId: event.userId));
      },
    );
  }



  void _onShowAddForm(ShowAddFormEvent event, Emitter<ArmoryState> emit) {
    // Get current loaded data from state
    final currentState = state;
    if (currentState is ArmoryDataLoaded) {
      emit(ShowingAddForm(
        tabType: event.tabType,
        firearms: currentState.firearms,
        ammunition: currentState.ammunition,
        gear: currentState.gear,
        tools: currentState.tools,
        loadouts: currentState.loadouts,
        maintenance: currentState.maintenance,
      ));
    }
    // If previously ShowingAddForm, preserve data
    else if (currentState is ShowingAddForm) {
      emit(ShowingAddForm(
        tabType: event.tabType,
        firearms: currentState.firearms,
        ammunition: currentState.ammunition,
        gear: currentState.gear,
        tools: currentState.tools,
        loadouts: currentState.loadouts,
        maintenance: currentState.maintenance,
      ));
    }
    // Otherwise, fallback to empty
    else {
      emit(ShowingAddForm(
        tabType: event.tabType,
        firearms: [],
        ammunition: [],
        gear: [],
        tools: [],
        loadouts: [],
        maintenance: [],
      ));
    }
  }

  void _onHideForm(HideFormEvent event, Emitter<ArmoryState> emit) {
    final currentState = state;
    // Preserve previously loaded data if possible
    if (currentState is ArmoryDataLoaded) {
      emit(ArmoryDataLoaded(
        firearms: currentState.firearms,
        ammunition: currentState.ammunition,
        gear: currentState.gear,
        tools: currentState.tools,
        loadouts: currentState.loadouts,
        maintenance: currentState.maintenance,
      ));
    } else if (currentState is ShowingAddForm) {
      emit(ArmoryDataLoaded(
        firearms: currentState.firearms.cast<ArmoryFirearm>(),
        ammunition: currentState.ammunition.cast<ArmoryAmmunition>(),
        gear: currentState.gear.cast<ArmoryGear>(),
        tools: currentState.tools.cast<ArmoryTool>(),
        loadouts: currentState.loadouts.cast<ArmoryLoadout>(),
        maintenance: currentState.maintenance.cast<ArmoryMaintenance>(),
      ));
    } else {
      emit(const ArmoryInitial());
    }
  }


}
