// lib/user_dashboard/domain/usecases/get_dropdown_options_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/dropdown_option.dart';
import '../repositories/armory_repository.dart';

class GetDropdownOptionsUseCase implements UseCase<List<DropdownOption>, DropdownParams> {
  final ArmoryRepository repository;
  final FirebaseAuth firebaseAuth;

  // Exact same cache structure as original DataSource
  List<Map<String, dynamic>>? _firearmsCache;
  List<Map<String, dynamic>>? _ammunitionCache;
  List<Map<String, dynamic>>? _userFirearmsCache;
  List<Map<String, dynamic>>? _userAmmunitionCache;

  // Exact same filtered lists as original DataSource
  List<Map<String, dynamic>>? _filteredFirearmBrands;
  List<Map<String, dynamic>>? _filteredFirearmModel;
  List<Map<String, dynamic>>? _filteredFirearmGeneration;
  List<Map<String, dynamic>>? _filteredFirearmCaliber;
  List<Map<String, dynamic>>? _filteredFirearmFiringMechanism;
  List<Map<String, dynamic>>? _filteredFirearmMakes;

  List<Map<String, dynamic>>? _filteredAmmoBrands;
  List<Map<String, dynamic>>? _filteredAmmoCaliber;
  List<Map<String, dynamic>>? _filteredAmmoBulletWeight;

  GetDropdownOptionsUseCase(this.repository, this.firebaseAuth);

  @override
  Future<Either<Failure, List<DropdownOption>>> call(DropdownParams params) async {
    switch (params.type) {
      case DropdownType.firearmBrands:
        return await _getFirearmBrands(params.filterValue);

      case DropdownType.firearmModels:
        return await _getFirearmModels(params.filterValue);

      case DropdownType.firearmGenerations:
        return await _getFirearmGenerations(params.filterValue);

      case DropdownType.calibers:
        return await _getCalibers(params.filterValue);

      case DropdownType.firearmFiringMechanisms:
        return await _getFirearmFiringMechanisms(params.filterValue);

      case DropdownType.firearmMakes:
        return await _getFirearmMakes(params.filterValue);

      case DropdownType.ammunitionCaliber:
        return await _getAmmoCalibers();

      case DropdownType.ammunitionBrands:
        return await _getAmmunitionBrands(params.filterValue);

      case DropdownType.bulletTypes:
        return await _getBulletTypes(params.filterValue);
    }
  }

  // =============== Exact Same Helper Methods as Original DataSource ===============

  /// Initialize firearm data - Same as original DataSource
  Future<void> _initializeFirearmData() async {
    _firearmsCache ??= await _getFirearmsData();
    _userFirearmsCache ??= await _getUserFirearmsData();
  }

  /// Initialize ammo data - Same as original DataSource
  Future<void> _initializeAmmoData() async {
    _ammunitionCache ??= await _getAmmunitionData();
    _userAmmunitionCache ??= await _getUserAmmunitionData();
  }

  /// Get all firearms data - Same as original DataSource
  List<Map<String, dynamic>> get _allFirearmsData =>
      [...?_firearmsCache, ...?_userFirearmsCache];

  /// Get all ammo data - Same as original DataSource
  List<Map<String, dynamic>> get _allAmmoData =>
      [...?_ammunitionCache, ...?_userAmmunitionCache];

  /// Filter data method - Exact same as original DataSource
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

  /// Load firearms data - Same as original DataSource
  Future<List<Map<String, dynamic>>> _getFirearmsData() async {
    if (_firearmsCache != null) return _firearmsCache!;

    try {
      final result = await repository.getFirearmsRawData();
      return result.fold(
            (failure) => throw Exception('Failed to load firearms data: $failure'),
            (data) {
          _firearmsCache = data;
          return _firearmsCache!;
        },
      );
    } catch (e) {
      throw Exception('Failed to load firearms data: $e');
    }
  }

  /// Load ammunition data - Same as original DataSource
  Future<List<Map<String, dynamic>>> _getAmmunitionData() async {
    if (_ammunitionCache != null) return _ammunitionCache!;

    try {
      final result = await repository.getAmmunitionRawData();
      return result.fold(
            (failure) => throw Exception('Failed to load ammunition data: $failure'),
            (data) {
          _ammunitionCache = data;
          return _ammunitionCache!;
        },
      );
    } catch (e) {
      throw Exception('Failed to load ammunition data: $e');
    }
  }

  /// Get user firearms data - Same as original DataSource
  Future<List<Map<String, dynamic>>> _getUserFirearmsData() async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      if (currentUserId == null) return [];

      final result = await repository.getUserFirearmsRawData(currentUserId);
      return result.fold(
            (failure) => [], // Error case mein empty list return karein
            (data) => data,
      );
    } catch (e) {
      return []; // Error case mein empty list return karein
    }
  }

  /// Get user ammunition data - Same as original DataSource
  Future<List<Map<String, dynamic>>> _getUserAmmunitionData() async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      if (currentUserId == null) return [];

      final result = await repository.getUserAmmunitionRawData(currentUserId);
      return result.fold(
            (failure) => [], // Error case mein empty list return karein
            (data) => data,
      );
    } catch (e) {
      return []; // Error case mein empty list return karein
    }
  }

  // =============== Exact Same Dropdown Methods as Original DataSource ===============

  /// Get firearm brands - Exact same logic as original DataSource
  Future<Either<Failure, List<DropdownOption>>> _getFirearmBrands(String? type) async {
    try {
      await _initializeFirearmData();
      final filtered = _filterData(
        source: _allFirearmsData,
        field: 'type',
        value: type,
      );

      final brands = filtered
          .map((e) => e['brand']?.toString() ?? '')
          .where((b) => b.isNotEmpty)
          .toSet()
          .toList();
      brands.sort();

      // Save for next filters - Exact same as original
      _filteredFirearmBrands = filtered;
      _filteredFirearmModel = _filteredFirearmGeneration = _filteredFirearmCaliber =
          _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;

      return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm brands: $e'));
    }
  }

  /// Get firearm models - Exact same logic as original DataSource
  Future<Either<Failure, List<DropdownOption>>> _getFirearmModels(String? brand) async {
    try {
      if (_filteredFirearmBrands == null) return const Right([]);

      final filtered = _filterData(
        source: _filteredFirearmBrands!,
        field: 'brand',
        value: brand,
      );

      final models = filtered
          .map((e) => e['model']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList();
      models.sort();

      // Save for next filters - Exact same as original
      _filteredFirearmModel = filtered;
      _filteredFirearmGeneration = _filteredFirearmCaliber =
          _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;

      return Right(models.map((m) => DropdownOption(value: m, label: m)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm models: $e'));
    }
  }

  /// Get firearm generations - Exact same logic as original DataSource
  Future<Either<Failure, List<DropdownOption>>> _getFirearmGenerations(String? model) async {
    try {
      if (_filteredFirearmModel == null) return const Right([]);

      final filtered = _filterData(
        source: _filteredFirearmModel!,
        field: 'model',
        value: model,
      );

      final generations = filtered
          .map((e) => e['generation']?.toString() ?? '')
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList();
      generations.sort();

      // Save for next filters - Exact same as original
      _filteredFirearmGeneration = filtered;
      _filteredFirearmCaliber = _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;

      return Right(generations.map((g) => DropdownOption(value: g, label: g)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm generations: $e'));
    }
  }

  /// Get calibers - Exact same logic as original DataSource
  Future<Either<Failure, List<DropdownOption>>> _getCalibers(String? generation) async {
    try {
      if (_filteredFirearmGeneration == null) return const Right([]);

      final filtered = _filterData(
        source: _filteredFirearmGeneration!,
        field: 'generation',
        value: generation,
      );

      final calibers = filtered
          .map((e) => e['caliber']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      calibers.sort();

      // Save for next filters - Exact same as original
      _filteredFirearmCaliber = filtered;
      _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;

      return Right(calibers.map((caliber) => DropdownOption(value: caliber, label: caliber)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get calibers: $e'));
    }
  }

  /// Get firearm firing mechanisms - Exact same logic as original DataSource
  Future<Either<Failure, List<DropdownOption>>> _getFirearmFiringMechanisms(String? caliber) async {
    try {
      if (_filteredFirearmCaliber == null) return const Right([]);

      final filtered = _filterData(
        source: _filteredFirearmCaliber!,
        field: 'caliber',
        value: caliber,
      );

      final mechanisms = filtered
          .map((e) => e['firing_machanism']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList();
      mechanisms.sort();

      // Save for next filters - Exact same as original
      _filteredFirearmFiringMechanism = filtered;
      _filteredFirearmMakes = null;

      return Right(mechanisms.map((mech) => DropdownOption(value: mech, label: mech)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firing mechanisms: $e'));
    }
  }

  /// Get firearm makes - Exact same logic as original DataSource
  Future<Either<Failure, List<DropdownOption>>> _getFirearmMakes(String? firingMechanism) async {
    try {
      if (_filteredFirearmFiringMechanism == null) return const Right([]);

      final filtered = _filterData(
        source: _filteredFirearmFiringMechanism!,
        field: 'firing_machanism',
        value: firingMechanism,
      );

      final makes = filtered
          .map((e) => e['make']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList();
      makes.sort();

      // Save for next filters - Exact same as original
      _filteredFirearmMakes = filtered;

      return Right(makes.map((make) => DropdownOption(value: make, label: make)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm makes: $e'));
    }
  }

  // =============== Ammunition Dropdown Methods - Exact Same as Original DataSource ===============

  /// Get ammo calibers with user's firearm calibers prioritized - Exact same logic as original
  Future<Either<Failure, List<DropdownOption>>> _getAmmoCalibers() async {
    try {
      await _initializeAmmoData();
      final userFirearmForCaliber = await _getUserFirearmsData();

      final ammoCalibers = _allAmmoData
          .map((e) => e['caliber']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();

      final userFirearmCalibers = userFirearmForCaliber
          .map((e) => e['caliber']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();

      final priorityCalibers = userFirearmCalibers.toList()..sort();
      final otherCalibers = ammoCalibers.difference(userFirearmCalibers).toList()..sort();

      // Create options list with separator - Exact same as original
      final List<DropdownOption> options = [];

      if (priorityCalibers.isNotEmpty) {
        options.add(const DropdownOption(
            value: '---SEPARATOR---', label: '── Your Firearms Calibers ──'));
      }

      // Add priority calibers
      options.addAll(priorityCalibers.map((caliber) => DropdownOption(
          value: caliber, label: caliber)));

      // Add separator if both lists have items
      if (priorityCalibers.isNotEmpty && otherCalibers.isNotEmpty) {
        options.add(const DropdownOption(
            value: '---SEPARATOR---', label: '── Other Calibers ──'));
      }

      // Add other calibers
      options.addAll(otherCalibers.map((caliber) => DropdownOption(
          value: caliber, label: caliber)));

      // Save state for next filters - Exact same as original
      _filteredAmmoBrands = _allAmmoData;
      _filteredAmmoCaliber = _filteredAmmoBulletWeight = null;

      return Right(options);
    } catch (e) {
      return Left(FileFailure('Failed to get calibers: $e'));
    }
  }

  /// Get ammunition brands filtered by caliber - Exact same logic as original
  Future<Either<Failure, List<DropdownOption>>> _getAmmunitionBrands(String? caliber) async {
    try {
      if (_filteredAmmoBrands == null) return const Right([]);

      final filtered = _filterData(
        source: _filteredAmmoBrands!,
        field: 'caliber',
        value: caliber,
      );

      // If filtered is empty, show all brands - Exact same as original
      if (filtered.isEmpty) {
        final ammoBrands = _allAmmoData
            .map((e) => e['brand']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet();

        // Create options list
        final List<DropdownOption> options = [];

        // Add all brands
        options.addAll(ammoBrands.map((brand) => DropdownOption(
            value: brand, label: brand)));

        // Save state for next filters - Exact same as original
        _filteredAmmoCaliber = _allAmmoData;
        _filteredAmmoBulletWeight = null;

        return Right(options);
      }

      final brands = filtered
          .map((e) => e['brand']?.toString() ?? '')
          .where((b) => b.isNotEmpty)
          .toSet()
          .toList();
      brands.sort();

      // Save state for next filters - Exact same as original
      _filteredAmmoCaliber = filtered;
      _filteredAmmoBulletWeight = null;

      return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get ammunition brands: $e'));
    }
  }

  /// Get bullet types filtered by caliber and optionally brand - Exact same logic as original
  Future<Either<Failure, List<DropdownOption>>> _getBulletTypes(String? brand) async {
    try {
      if (_filteredAmmoCaliber == null) return const Right([]);

      // If brand provided, filter further - Exact same as original
      final filtered = brand != null && brand.isNotEmpty
          ? _filterData(
        source: _filteredAmmoCaliber!,
        field: 'brand',
        value: brand,
      )
          : _filteredAmmoCaliber!;

      final bulletWeights = filtered
          .map((e) => e['bullet weight (gr)']?.toString() ?? '')
          .where((w) => w.isNotEmpty)
          .toSet()
          .toList();
      bulletWeights.sort();

      // Save state - Exact same as original
      _filteredAmmoBulletWeight = filtered;

      return Right(bulletWeights.map((bullet) => DropdownOption(value: bullet, label: bullet)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get bullet types: $e'));
    }
  }

  /// Clear cache method - Same as original DataSource
  void clearCache() {
    _firearmsCache = null;
    _ammunitionCache = null;
    _userFirearmsCache = null;
    _userAmmunitionCache = null;

    // Clear filtered states
    _filteredFirearmBrands = null;
    _filteredFirearmModel = null;
    _filteredFirearmGeneration = null;
    _filteredFirearmCaliber = null;
    _filteredFirearmFiringMechanism = null;
    _filteredFirearmMakes = null;

    _filteredAmmoBrands = null;
    _filteredAmmoCaliber = null;
    _filteredAmmoBulletWeight = null;
  }
}