// lib/user_dashboard/domain/usecases/dropdown_business_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/dropdown_option.dart';
import '../repositories/armory_repository.dart';

// =============== Firearm Dropdown Business Logic ===============
class GetFirearmBrandsUseCase implements UseCase<List<DropdownOption>, DropdownParams> {
  final ArmoryRepository repository;
  final FirebaseAuth firebaseAuth;

  // Business Logic State
  List<Map<String, dynamic>>? _firearmsRawCache;
  List<Map<String, dynamic>>? _userFirearmsRawCache;
  List<Map<String, dynamic>>? _filteredFirearmBrands;

  GetFirearmBrandsUseCase(this.repository, this.firebaseAuth);

  @override
  Future<Either<Failure, List<DropdownOption>>> call(DropdownParams params) async {
    try {
      final allData = await _getAllFirearmsData();
      final filtered = _filterData(source: allData, field: 'type', value: params.filterValue);

      final brands = filtered
          .map((e) => e['brand']?.toString() ?? '')
          .where((b) => b.isNotEmpty)
          .toSet()
          .toList();
      brands.sort();

      // Store filtered data for next level filtering
      _filteredFirearmBrands = filtered;

      return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> _getAllFirearmsData() async {
    final firearmsResult = await repository.getFirearmsRawData();
    _firearmsRawCache = firearmsResult.fold((l) => [], (r) => r);

    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId != null) {
      final userFirearmsResult = await repository.getUserFirearmsRawData(currentUserId);
      _userFirearmsRawCache = userFirearmsResult.fold((l) => [], (r) => r);
      return [..._firearmsRawCache!, ..._userFirearmsRawCache!];
    }
    return _firearmsRawCache!;
  }

  List<Map<String, dynamic>> _filterData({
    required List<Map<String, dynamic>> source,
    String? field,
    String? value,
  }) {
    if (value == null || value.isEmpty || value.startsWith('__CUSTOM__')) {
      return source;
    }
    return source.where((item) => item[field]?.toString() == value).toList();
  }
}

class GetFirearmModelsUseCase implements UseCase<List<DropdownOption>, DropdownParams> {
  final ArmoryRepository repository;
  final FirebaseAuth firebaseAuth;
  final GetFirearmBrandsUseCase _brandsUseCase;

  GetFirearmModelsUseCase(this.repository, this.firebaseAuth, this._brandsUseCase);

  @override
  Future<Either<Failure, List<DropdownOption>>> call(DropdownParams params) async {
    try {
      // Get filtered brands data first
      if (_brandsUseCase._filteredFirearmBrands == null) {
        await _brandsUseCase.call(DropdownParams(type: DropdownType.firearmBrands));
      }

      final filtered = _filterData(
        source: _brandsUseCase._filteredFirearmBrands!,
        field: 'brand',
        value: params.filterValue,
      );

      final models = filtered
          .map((e) => e['model']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList();
      models.sort();

      return Right(models.map((m) => DropdownOption(value: m, label: m)).toList());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  List<Map<String, dynamic>> _filterData({
    required List<Map<String, dynamic>> source,
    String? field,
    String? value,
  }) {
    if (value == null || value.isEmpty || value.startsWith('__CUSTOM__')) {
      return source;
    }
    return source.where((item) => item[field]?.toString() == value).toList();
  }
}

// =============== Ammunition Dropdown Business Logic ===============
class GetAmmunitionCalibersUseCase implements UseCase<List<DropdownOption>, NoParams> {
  final ArmoryRepository repository;
  final FirebaseAuth firebaseAuth;

  GetAmmunitionCalibersUseCase(this.repository, this.firebaseAuth);

  @override
  Future<Either<Failure, List<DropdownOption>>> call(NoParams params) async {
    try {
      final allAmmoData = await _getAllAmmoData();
      final currentUserId = firebaseAuth.currentUser?.uid;

      // Business Logic: User's firearm calibers get priority
      final ammoCalibers = allAmmoData
          .map((e) => e['caliber']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();

      Set<String> userFirearmCalibers = {};
      if (currentUserId != null) {
        final userFirearmsResult = await repository.getUserFirearmsRawData(currentUserId);
        final userFirearms = userFirearmsResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
        userFirearmCalibers = userFirearms
            .map((e) => e['caliber']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet();
      }

      final priorityCalibers = userFirearmCalibers.toList()..sort();
      final otherCalibers = ammoCalibers.difference(userFirearmCalibers).toList()..sort();

      final List<DropdownOption> options = [];

      // Business Logic: Add priority section
      if (priorityCalibers.isNotEmpty) {
        options.add(const DropdownOption(
            value: '---SEPARATOR---', label: '── Your Firearms Calibers ──'));
        options.addAll(priorityCalibers.map((caliber) => DropdownOption(
            value: caliber, label: caliber)));
      }

      if (priorityCalibers.isNotEmpty && otherCalibers.isNotEmpty) {
        options.add(const DropdownOption(
            value: '---SEPARATOR---', label: '── Other Calibers ──'));
      }

      options.addAll(otherCalibers.map((caliber) => DropdownOption(
          value: caliber, label: caliber)));

      return Right(options);
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> _getAllAmmoData() async {
    final ammoResult = await repository.getAmmunitionRawData();
    final ammoData = ammoResult.fold((l) => <Map<String, dynamic>>[], (r) => r);

    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId != null) {
      final userAmmoResult = await repository.getUserAmmunitionRawData(currentUserId);
      final userAmmoData = userAmmoResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      return [...ammoData, ...userAmmoData];
    }
    return ammoData;
  }
}

class GetAmmunitionBrandsUseCase implements UseCase<List<DropdownOption>, DropdownParams> {
  final ArmoryRepository repository;
  final FirebaseAuth firebaseAuth;

  GetAmmunitionBrandsUseCase(this.repository, this.firebaseAuth);

  @override
  Future<Either<Failure, List<DropdownOption>>> call(DropdownParams params) async {
    try {
      final allAmmoData = await _getAllAmmoData();

      final filtered = _filterData(
        source: allAmmoData,
        field: 'caliber',
        value: params.filterValue,
      );

      // Business Logic: If no filtered results, show all brands
      if (filtered.isEmpty) {
        final ammoBrands = allAmmoData
            .map((e) => e['brand']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()..sort();

        return Right(ammoBrands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
      }

      final brands = filtered
          .map((e) => e['brand']?.toString() ?? '')
          .where((b) => b.isNotEmpty)
          .toSet()
          .toList();
      brands.sort();

      return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
    } catch (e) {
      return Left(FileFailure(e.toString()));
    }
  }

  Future<List<Map<String, dynamic>>> _getAllAmmoData() async {
    final ammoResult = await repository.getAmmunitionRawData();
    final ammoData = ammoResult.fold((l) => <Map<String, dynamic>>[], (r) => r);

    final currentUserId = firebaseAuth.currentUser?.uid;
    if (currentUserId != null) {
      final userAmmoResult = await repository.getUserAmmunitionRawData(currentUserId);
      final userAmmoData = userAmmoResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      return [...ammoData, ...userAmmoData];
    }
    return ammoData;
  }

  List<Map<String, dynamic>> _filterData({
    required List<Map<String, dynamic>> source,
    String? field,
    String? value,
  }) {
    if (value == null || value.isEmpty || value.startsWith('__CUSTOM__')) {
      return source;
    }
    return source.where((item) => item[field]?.toString() == value).toList();
  }
}

// =============== Caching Service ===============
class ArmoryDataCacheService {
  Map<String, List<dynamic>?> _cache = {};

  Future<T> getCachedData<T>({
    required String key,
    required Future<T> Function() fetchData,
  }) async {
    if (_cache.containsKey(key) && _cache[key] != null) {
      return _cache[key]! as T;
    }

    final data = await fetchData();
    _cache[key] = data as List<dynamic>?;
    return data;
  }

  void invalidateCache(String key) {
    _cache.remove(key);
  }

  void clearAllCaches() {
    _cache.clear();
  }
}