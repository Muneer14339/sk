// dropdown_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../domain/entities/dropdown_option.dart';
import '../../../domain/usecases/get_dropdown_options_usecase.dart';
import 'dropdown_event.dart';
import 'dropdown_state.dart';

class DropdownBloc extends Bloc<DropdownEvent, DropdownState> {
  final GetDropdownOptionsUseCase getDropdownOptionsUseCase;

  // Cache to store loaded options
  final Map<String, List<DropdownOption>> _dropdownCache = {};

  DropdownBloc({
    required this.getDropdownOptionsUseCase,
  }) : super(const DropdownInitial()) {
    on<LoadDropdownEvent>(_onLoadDropdown);
    on<ClearDropdownEvent>(_onClearDropdown);
  }

  void _onLoadDropdown(LoadDropdownEvent event, Emitter<DropdownState> emit) async {
    emit(DropdownLoading(loadingKey: event.key));

    final result = await getDropdownOptionsUseCase(
      DropdownParams(
        type: event.type,
        filterValue: event.filterValue,
      ),
    );

    result.fold(
          (failure) => emit(DropdownError(
        message: failure.toString(),
        key: event.key,
      )),
          (options) {
        // Cache the loaded options
        _dropdownCache[event.key] = options;

        emit(DropdownLoaded(
          key: event.key,
          options: options,
        ));
      },
    );
  }

  void _onClearDropdown(ClearDropdownEvent event, Emitter<DropdownState> emit) {
    _dropdownCache.remove(event.key);
    emit(const DropdownInitial());
  }

  // Helper to get cached options
  List<DropdownOption> getCachedOptions(String key) {
    return _dropdownCache[key] ?? [];
  }
}
