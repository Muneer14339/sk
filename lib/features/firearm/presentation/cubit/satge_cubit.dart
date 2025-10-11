
import 'package:flutter_bloc/flutter_bloc.dart';

class AutoValidationCubit extends Cubit<bool> {
  AutoValidationCubit() : super(false);

  void enableAuto() {
    if (!state) {
      emit(true);
    }
  }
}

class ParTimeCubit extends Cubit<String> {
  ParTimeCubit() : super('');

  void yesPartime() => emit('Yes');
  void noParTime() => emit('No');
}

class ParTimeMuteCubit extends Cubit<int> {
  ParTimeMuteCubit() : super(0);

  void unmute() => emit(1);
  void mute() => emit(0);
}

class DropDownCubit extends Cubit<List<String>> {
  final List<String> _allItems;
  DropDownCubit(super.initialItems) : _allItems = initialItems;

  void filterItems(String query) {
    if (query.isEmpty) {
      emit(_allItems);
    } else {
      final filteredItems = _allItems
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
      emit(filteredItems);
    }
  }
}

// class DropDownCubitGen<T> extends Cubit<List<T>> {
//   final List<T> _allItems;

//   DropDownCubitGen(super.initialItems) : _allItems = initialItems;

//   void filterItems(String query) {
//     if (query.trim().isEmpty) {
//       emit(_allItems);
//     } else {
//       final filteredItems = _allItems
//           .where((item) =>
//               item.toString().toLowerCase().contains(query.toLowerCase()))
//           .toList();
//       log('---m${filteredItems.length}');
//       emit(filteredItems);
//     }
//   }
// }

class DropDownCubitGen<T> extends Cubit<List<T>> {
  final List<T> originalItems;
  final String Function(T) getSearchableString;

  DropDownCubitGen(this.originalItems, this.getSearchableString)
      : super(originalItems);

  void filterItems(String query) {
    if (query.isEmpty) {
      emit(originalItems);
    } else {
      final lowerQuery = query.toLowerCase();
      emit(
        originalItems.where((item) {
          final searchString = getSearchableString(item).toLowerCase();
          return searchString.contains(lowerQuery);
        }).toList(),
      );
    }
  }
}
