// lib/user_dashboard/presentation/bloc/armory_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
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
import '../../domain/usecases/get_dropdown_options_usecase.dart';
import 'armory_event.dart';
import 'armory_state.dart';

class ArmoryBloc extends Bloc<ArmoryEvent, ArmoryState> {
  // Original Use Cases (Exact same as before - GUI Safe)
  final GetFirearmsUseCase getFirearmsUseCase;
  final GetAmmunitionUseCase getAmmunitionUseCase;
  final GetGearUseCase getGearUseCase;
  final GetToolsUseCase getToolsUseCase;
  final GetLoadoutsUseCase getLoadoutsUseCase;
  final GetMaintenanceUseCase getMaintenanceUseCase;

  // CRUD Use Cases (Exact same as before)
  final AddFirearmUseCase addFirearmUseCase;
  final AddAmmunitionUseCase addAmmunitionUseCase;
  final AddGearUseCase addGearUseCase;
  final AddToolUseCase addToolUseCase;
  final AddLoadoutUseCase addLoadoutUseCase;
  final AddMaintenanceUseCase addMaintenanceUseCase;

  // Delete Use Cases (Exact same as before)
  final DeleteFirearmUseCase deleteFirearmUseCase;
  final DeleteAmmunitionUseCase deleteAmmunitionUseCase;
  final DeleteGearUseCase deleteGearUseCase;
  final DeleteToolUseCase deleteToolUseCase;
  final DeleteMaintenanceUseCase deleteMaintenanceUseCase;
  final DeleteLoadoutUseCase deleteLoadoutUseCase;

  // Business Logic Use Cases (Same interface)
  final GetDropdownOptionsUseCase getDropdownOptionsUseCase;

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
    required this.getDropdownOptionsUseCase,
    required this.getMaintenanceUseCase,
    required this.addMaintenanceUseCase,
    required this.deleteMaintenanceUseCase,
  }) : super(const ArmoryInitial()) {
    on<LoadFirearmsEvent>(_onLoadFirearms);
    on<LoadAmmunitionEvent>(_onLoadAmmunition);
    on<LoadGearEvent>(_onLoadGear);
    on<LoadToolsEvent>(_onLoadTools);
    on<LoadLoadoutsEvent>(_onLoadLoadouts);
    on<AddFirearmEvent>(_onAddFirearm);
    on<AddAmmunitionEvent>(_onAddAmmunition);
    on<AddGearEvent>(_onAddGear);
    on<AddToolEvent>(_onAddTool);
    on<AddLoadoutEvent>(_onAddLoadout);
    on<LoadDropdownOptionsEvent>(_onLoadDropdownOptions);
    on<LoadMaintenanceEvent>(_onLoadMaintenance);
    on<AddMaintenanceEvent>(_onAddMaintenance);

    // Delete events
    on<DeleteFirearmEvent>(_onDeleteFirearm);
    on<DeleteAmmunitionEvent>(_onDeleteAmmunition);
    on<DeleteGearEvent>(_onDeleteGear);
    on<DeleteToolEvent>(_onDeleteTool);
    on<DeleteMaintenanceEvent>(_onDeleteMaintenance);
    on<DeleteLoadoutEvent>(_onDeleteLoadout);

    on<ShowAddFormEvent>(_onShowAddForm);
    on<HideFormEvent>(_onHideForm);
  }

  // =============== Load Events (Using Original Use Cases) ===============
  void _onLoadFirearms(LoadFirearmsEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final result = await getFirearmsUseCase(UserIdParams(userId: event.userId));

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (firearms) => emit(FirearmsLoaded(firearms: firearms)),
    );
  }

  void _onLoadAmmunition(LoadAmmunitionEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final result = await getAmmunitionUseCase(UserIdParams(userId: event.userId));

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (ammunition) => emit(AmmunitionLoaded(ammunition: ammunition)),
    );
  }

  void _onLoadGear(LoadGearEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final result = await getGearUseCase(UserIdParams(userId: event.userId));

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (gear) => emit(GearLoaded(gear: gear)),
    );
  }

  void _onLoadTools(LoadToolsEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final result = await getToolsUseCase(UserIdParams(userId: event.userId));

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (tools) => emit(ToolsLoaded(tools: tools)),
    );
  }

  void _onLoadLoadouts(LoadLoadoutsEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final result = await getLoadoutsUseCase(UserIdParams(userId: event.userId));

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (loadouts) => emit(LoadoutsLoaded(loadouts: loadouts)),
    );
  }

  void _onLoadMaintenance(LoadMaintenanceEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoading());

    final result = await getMaintenanceUseCase(UserIdParams(userId: event.userId));

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (maintenance) => emit(MaintenanceLoaded(maintenance: maintenance)),
    );
  }

  // =============== Add Events (Original Implementation) ===============
  void _onAddFirearm(AddFirearmEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await addFirearmUseCase(
      AddFirearmParams(userId: event.userId, firearm: event.firearm),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Firearm added successfully!'));
        add(LoadFirearmsEvent(userId: event.userId));
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
        add(LoadAmmunitionEvent(userId: event.userId));
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
        add(LoadGearEvent(userId: event.userId));
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
        add(LoadToolsEvent(userId: event.userId));
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
        add(LoadLoadoutsEvent(userId: event.userId));
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
        add(LoadMaintenanceEvent(userId: event.userId));
      },
    );
  }

  // =============== Delete Events (Original Implementation) ===============
  void _onDeleteFirearm(DeleteFirearmEvent event, Emitter<ArmoryState> emit) async {
    emit(const ArmoryLoadingAction());

    final result = await deleteFirearmUseCase(
      DeleteFirearmParams(userId: event.userId, firearm: event.firearm),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (_) {
        emit(const ArmoryActionSuccess(message: 'Firearm deleted successfully!'));
        add(LoadFirearmsEvent(userId: event.userId));
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
        add(LoadAmmunitionEvent(userId: event.userId));
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
        add(LoadGearEvent(userId: event.userId));
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
        add(LoadToolsEvent(userId: event.userId));
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
        add(LoadMaintenanceEvent(userId: event.userId));
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
        add(LoadLoadoutsEvent(userId: event.userId));
      },
    );
  }

  // =============== Business Logic Events ===============
  void _onLoadDropdownOptions(LoadDropdownOptionsEvent event, Emitter<ArmoryState> emit) async {
    final result = await getDropdownOptionsUseCase(
      DropdownParams(
        type: event.type,
        filterValue: event.filterValue,
      ),
    );

    result.fold(
          (failure) => emit(ArmoryError(message: failure.toString())),
          (options) => emit(DropdownOptionsLoaded(options: options)),
    );
  }

  // =============== UI Events ===============
  void _onShowAddForm(ShowAddFormEvent event, Emitter<ArmoryState> emit) {
    emit(ShowingAddForm(tabType: event.tabType));
  }

  void _onHideForm(HideFormEvent event, Emitter<ArmoryState> emit) {
    emit(const ArmoryInitial());
  }
}