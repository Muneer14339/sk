// // lib/user_dashboard/domain/services/armory_cache_service.dart
// import 'package:dartz/dartz.dart';
// import '../../../core/error/failures.dart';
// import '../entities/armory_firearm.dart';
// import '../entities/armory_ammunition.dart';
// import '../entities/armory_gear.dart';
// import '../entities/armory_maintenance.dart';
// import '../entities/armory_tool.dart';
// import '../entities/armory_loadout.dart';
//
// abstract class ArmoryDataCacheService {
//   Future<T> getCachedData<T>({
//     required String key,
//     required Future<T> Function() fetchData,
//   });
//
//   void invalidateCache(String key);
//   void invalidateUserCache(String userId);
//   void clearAllCaches();
// }
//
// class ArmoryDataCacheServiceImpl implements ArmoryDataCacheService {
//   final Map<String, dynamic> _cache = {};
//
//   @override
//   Future<T> getCachedData<T>({
//     required String key,
//     required Future<T> Function() fetchData,
//   }) async {
//     if (_cache.containsKey(key) && _cache[key] != null) {
//       return _cache[key]! as T;
//     }
//
//     final data = await fetchData();
//     _cache[key] = data;
//     return data;
//   }
//
//   @override
//   void invalidateCache(String key) {
//     _cache.remove(key);
//   }
//
//   @override
//   void invalidateUserCache(String userId) {
//     // Remove all user-specific cache entries
//     final keysToRemove = _cache.keys.where((key) => key.contains(userId)).toList();
//     for (final key in keysToRemove) {
//       _cache.remove(key);
//     }
//   }
//
//   @override
//   void clearAllCaches() {
//     _cache.clear();
//   }
// }
//
// // =============== Cached CRUD Use Cases ===============
// class CachedGetFirearmsUseCase {
//   final ArmoryDataCacheService cacheService;
//   final Future<Either<Failure, List<ArmoryFirearm>>> Function(String userId) getFirearms;
//
//   CachedGetFirearmsUseCase({
//     required this.cacheService,
//     required this.getFirearms,
//   });
//
//   Future<Either<Failure, List<ArmoryFirearm>>> call(String userId) async {
//     return await cacheService.getCachedData<Either<Failure, List<ArmoryFirearm>>>(
//       key: 'firearms_$userId',
//       fetchData: () => getFirearms(userId),
//     );
//   }
//
//   void invalidateCache(String userId) {
//     cacheService.invalidateCache('firearms_$userId');
//     cacheService.invalidateCache('firearms_raw');
//     cacheService.invalidateCache('user_firearms_raw_$userId');
//   }
// }
//
// class CachedGetAmmunitionUseCase {
//   final ArmoryDataCacheService cacheService;
//   final Future<Either<Failure, List<ArmoryAmmunition>>> Function(String userId) getAmmunition;
//
//   CachedGetAmmunitionUseCase({
//     required this.cacheService,
//     required this.getAmmunition,
//   });
//
//   Future<Either<Failure, List<ArmoryAmmunition>>> call(String userId) async {
//     return await cacheService.getCachedData<Either<Failure, List<ArmoryAmmunition>>>(
//       key: 'ammunition_$userId',
//       fetchData: () => getAmmunition(userId),
//     );
//   }
//
//   void invalidateCache(String userId) {
//     cacheService.invalidateCache('ammunition_$userId');
//     cacheService.invalidateCache('ammunition_raw');
//     cacheService.invalidateCache('user_ammunition_raw_$userId');
//   }
// }
//
// class CachedGetGearUseCase {
//   final ArmoryDataCacheService cacheService;
//   final Future<Either<Failure, List<ArmoryGear>>> Function(String userId) getGear;
//
//   CachedGetGearUseCase({
//     required this.cacheService,
//     required this.getGear,
//   });
//
//   Future<Either<Failure, List<ArmoryGear>>> call(String userId) async {
//     return await cacheService.getCachedData<Either<Failure, List<ArmoryGear>>>(
//       key: 'gear_$userId',
//       fetchData: () => getGear(userId),
//     );
//   }
//
//   void invalidateCache(String userId) {
//     cacheService.invalidateCache('gear_$userId');
//   }
// }
//
// class CachedGetToolsUseCase {
//   final ArmoryDataCacheService cacheService;
//   final Future<Either<Failure, List<ArmoryTool>>> Function(String userId) getTools;
//
//   CachedGetToolsUseCase({
//     required this.cacheService,
//     required this.getTools,
//   });
//
//   Future<Either<Failure, List<ArmoryTool>>> call(String userId) async {
//     return await cacheService.getCachedData<Either<Failure, List<ArmoryTool>>>(
//       key: 'tools_$userId',
//       fetchData: () => getTools(userId),
//     );
//   }
//
//   void invalidateCache(String userId) {
//     cacheService.invalidateCache('tools_$userId');
//   }
// }
//
// class CachedGetLoadoutsUseCase {
//   final ArmoryDataCacheService cacheService;
//   final Future<Either<Failure, List<ArmoryLoadout>>> Function(String userId) getLoadouts;
//
//   CachedGetLoadoutsUseCase({
//     required this.cacheService,
//     required this.getLoadouts,
//   });
//
//   Future<Either<Failure, List<ArmoryLoadout>>> call(String userId) async {
//     return await cacheService.getCachedData<Either<Failure, List<ArmoryLoadout>>>(
//       key: 'loadouts_$userId',
//       fetchData: () => getLoadouts(userId),
//     );
//   }
//
//   void invalidateCache(String userId) {
//     cacheService.invalidateCache('loadouts_$userId');
//   }
// }
//
// class CachedGetMaintenanceUseCase {
//   final ArmoryDataCacheService cacheService;
//   final Future<Either<Failure, List<ArmoryMaintenance>>> Function(String userId) getMaintenance;
//
//   CachedGetMaintenanceUseCase({
//     required this.cacheService,
//     required this.getMaintenance,
//   });
//
//   Future<Either<Failure, List<ArmoryMaintenance>>> call(String userId) async {
//     return await cacheService.getCachedData<Either<Failure, List<ArmoryMaintenance>>>(
//       key: 'maintenance_$userId',
//       fetchData: () => getMaintenance(userId),
//     );
//   }
//
//   void invalidateCache(String userId) {
//     cacheService.invalidateCache('maintenance_$userId');
//   }
// }