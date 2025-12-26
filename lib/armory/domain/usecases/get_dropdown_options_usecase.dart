import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/dropdown_option.dart';
import '../repositories/armory_repository.dart';

class GetDropdownOptionsUseCase implements UseCase<List<DropdownOption>, DropdownParams> {
  final ArmoryRepository repository;
  final FirebaseAuth firebaseAuth;

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

  Future<Either<Failure, List<DropdownOption>>> _getFirearmBrands(String? type) async {
    try {
      final firearmsResult = await repository.getFirearmsRawData();
      final userFirearmsResult = await repository.getUserFirearmsRawData(firebaseAuth.currentUser?.uid ?? '');

      final firearms = firearmsResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      final userFirearms = userFirearmsResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      final allData = [...firearms, ...userFirearms];

      final filtered = _filterData(source: allData, field: 'type', value: type);
      final brands = filtered.map((e) => e['brand']?.toString() ?? '').where((b) => b.isNotEmpty).toSet().toList()..sort();

      _filteredFirearmBrands = filtered;
      _filteredFirearmModel = _filteredFirearmGeneration = _filteredFirearmCaliber = _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;

      return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm brands: $e'));
    }
  }

  Future<Either<Failure, List<DropdownOption>>> _getFirearmModels(String? brand) async {
    try {
      if (_filteredFirearmBrands == null) return const Right([]);
      final filtered = _filterData(source: _filteredFirearmBrands!, field: 'brand', value: brand);
      final models = filtered.map((e) => e['model']?.toString() ?? '').where((m) => m.isNotEmpty).toSet().toList()..sort();
      _filteredFirearmModel = filtered;
      _filteredFirearmGeneration = _filteredFirearmCaliber = _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;
      return Right(models.map((m) => DropdownOption(value: m, label: m)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm models: $e'));
    }
  }

  Future<Either<Failure, List<DropdownOption>>> _getFirearmGenerations(String? model) async {
    try {
      if (_filteredFirearmModel == null) return const Right([]);
      final filtered = _filterData(source: _filteredFirearmModel!, field: 'model', value: model);
      final generations = filtered.map((e) => e['generation']?.toString() ?? '').where((g) => g.isNotEmpty).toSet().toList()..sort();
      _filteredFirearmGeneration = filtered;
      _filteredFirearmCaliber = _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;
      return Right(generations.map((g) => DropdownOption(value: g, label: g)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm generations: $e'));
    }
  }

  // REPLACE _getCalibers method (around line 119)
  Future<Either<Failure, List<DropdownOption>>> _getCalibers(String? filterValue) async {
    try {
      List<Map<String, dynamic>> sourceData;

      // Priority: generation > model > brand
      if (_filteredFirearmGeneration != null && filterValue != null &&
          _filteredFirearmGeneration!.any((item) => item['generation']?.toString() == filterValue)) {
        // Filter by generation
        sourceData = _filterData(source: _filteredFirearmGeneration!, field: 'generation', value: filterValue);
        _filteredFirearmCaliber = sourceData;
      } else if (_filteredFirearmModel != null && filterValue != null &&
          _filteredFirearmModel!.any((item) => item['model']?.toString() == filterValue)) {
        // Filter by model
        sourceData = _filterData(source: _filteredFirearmModel!, field: 'model', value: filterValue);
        _filteredFirearmCaliber = sourceData;
      } else if (_filteredFirearmBrands != null && filterValue != null) {
        // Filter by brand
        sourceData = _filterData(source: _filteredFirearmBrands!, field: 'brand', value: filterValue);
        _filteredFirearmCaliber = sourceData;
      } else {
        return const Right([]);
      }

      final calibers = sourceData
          .map((e) => e['caliber']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()..sort();

      _filteredFirearmFiringMechanism = _filteredFirearmMakes = null;

      return Right(calibers.map((caliber) => DropdownOption(value: caliber, label: caliber)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get calibers: $e'));
    }
  }

// REPLACE _getFirearmFiringMechanisms method (around line 165)
  Future<Either<Failure, List<DropdownOption>>> _getFirearmFiringMechanisms(String? caliber) async {
    try {
      if (_filteredFirearmCaliber == null || _filteredFirearmCaliber!.isEmpty) {
        return const Right([]);
      }

      List<String> calibersToCheck = [];
      if (caliber != null && caliber.contains(',')) {
        calibersToCheck = caliber.split(',').map((c) => c.trim()).toList();
      } else if (caliber != null) {
        calibersToCheck = [caliber];
      } else {
        return const Right([]);
      }

      Set<String> allMechanisms = {};
      List<Map<String, dynamic>> allFiltered = [];

      for (final cal in calibersToCheck) {
        final filtered = _filteredFirearmCaliber!.where(
                (item) => item['caliber']?.toString() == cal
        ).toList();

        allFiltered.addAll(filtered);

        final mechanisms = filtered
            .map((e) => e['firingMechanism']?.toString() ?? '')
            .where((m) => m.isNotEmpty);
        allMechanisms.addAll(mechanisms);
      }

      final mechanismsList = allMechanisms.toList()..sort();
      _filteredFirearmFiringMechanism = allFiltered;
      _filteredFirearmMakes = null;

      return Right(mechanismsList.map((mech) =>
          DropdownOption(value: mech, label: mech)
      ).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firing mechanisms: $e'));
    }
  }

// REPLACE _getFirearmMakes method completely
  Future<Either<Failure, List<DropdownOption>>> _getFirearmMakes(String? firingMechanism) async {
    try {
      if (_filteredFirearmFiringMechanism == null) return const Right([]);

      final filtered = _filterData(
          source: _filteredFirearmFiringMechanism!,
          field: 'firingMechanism',
          value: firingMechanism
      );

      final makes = filtered
          .map((e) => e['make']?.toString() ?? '')
          .where((m) => m.isNotEmpty)
          .toSet()
          .toList()..sort();

      _filteredFirearmMakes = filtered;
      return Right(makes.map((make) => DropdownOption(value: make, label: make)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get firearm makes: $e'));
    }
  }

  // REPLACE _getAmmoCalibers method
  Future<Either<Failure, List<DropdownOption>>> _getAmmoCalibers() async {
    try {
      final ammoResult = await repository.getAmmunitionRawData();
      final userAmmoResult = await repository.getUserAmmunitionRawData(firebaseAuth.currentUser?.uid ?? '');
      final userFirearmsResult = await repository.getUserFirearmsRawData(firebaseAuth.currentUser?.uid ?? '');

      final ammo = ammoResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      final userAmmo = userAmmoResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      final userFirearms = userFirearmsResult.fold((l) => <Map<String, dynamic>>[], (r) => r);
      final allAmmo = [...ammo, ...userAmmo];

      // Split comma-separated calibers and collect them
      final ammoCalibers = <String>{};
      for (final ammoItem in allAmmo) {
        final caliberStr = ammoItem['caliber']?.toString() ?? '';
        if (caliberStr.isNotEmpty) {
          if (caliberStr.contains(',')) {
            ammoCalibers.addAll(caliberStr.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty));
          } else {
            ammoCalibers.add(caliberStr);
          }
        }
      }

      // Split comma-separated calibers for user firearms
      final userFirearmCalibers = <String>{};
      for (final firearm in userFirearms) {
        final caliberStr = firearm['caliber']?.toString() ?? '';
        if (caliberStr.isNotEmpty) {
          if (caliberStr.contains(',')) {
            userFirearmCalibers.addAll(caliberStr.split(',').map((c) => c.trim()).where((c) => c.isNotEmpty));
          } else {
            userFirearmCalibers.add(caliberStr);
          }
        }
      }

      final priorityCalibers = userFirearmCalibers.toList()..sort();
      final otherCalibers = ammoCalibers.difference(userFirearmCalibers).toList()..sort();

      final List<DropdownOption> options = [];
      if (priorityCalibers.isNotEmpty) {
        options.add(const DropdownOption(value: '---SEPARATOR---', label: '── Your Firearms Calibers ──'));
        options.addAll(priorityCalibers.map((caliber) => DropdownOption(value: caliber, label: caliber)));
      }
      if (priorityCalibers.isNotEmpty && otherCalibers.isNotEmpty) {
        options.add(const DropdownOption(value: '---SEPARATOR---', label: '── Other Calibers ──'));
      }
      options.addAll(otherCalibers.map((caliber) => DropdownOption(value: caliber, label: caliber)));

      _filteredAmmoBrands = allAmmo;
      _filteredAmmoCaliber = _filteredAmmoBulletWeight = null;
      return Right(options);
    } catch (e) {
      return Left(FileFailure('Failed to get calibers: $e'));
    }
  }

  Future<Either<Failure, List<DropdownOption>>> _getAmmunitionBrands(String? caliber) async {
    try {
      if (_filteredAmmoBrands == null) return const Right([]);
      final filtered = _filterData(source: _filteredAmmoBrands!, field: 'caliber', value: caliber);

      if (filtered.isEmpty) {
        final brands = _filteredAmmoBrands!.map((e) => e['brand']?.toString() ?? '').where((c) => c.isNotEmpty).toSet().toList()..sort();
        _filteredAmmoCaliber = _filteredAmmoBrands!;
        _filteredAmmoBulletWeight = null;
        return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
      }

      final brands = filtered.map((e) => e['brand']?.toString() ?? '').where((b) => b.isNotEmpty).toSet().toList()..sort();
      _filteredAmmoCaliber = filtered;
      _filteredAmmoBulletWeight = null;
      return Right(brands.map((brand) => DropdownOption(value: brand, label: brand)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get ammunition brands: $e'));
    }
  }

  Future<Either<Failure, List<DropdownOption>>> _getBulletTypes(String? brand) async {
    try {
      if (_filteredAmmoCaliber == null) return const Right([]);
      final filtered = brand != null && brand.isNotEmpty
          ? _filterData(source: _filteredAmmoCaliber!, field: 'brand', value: brand)
          : _filteredAmmoCaliber!;
      final bulletWeights = filtered.map((e) => e['bullet']?.toString() ?? '').where((w) => w.isNotEmpty).toSet().toList()..sort();
      _filteredAmmoBulletWeight = filtered;
      return Right(bulletWeights.map((bullet) => DropdownOption(value: bullet, label: bullet)).toList());
    } catch (e) {
      return Left(FileFailure('Failed to get bullet types: $e'));
    }
  }
}