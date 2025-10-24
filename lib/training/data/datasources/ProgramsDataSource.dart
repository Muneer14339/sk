import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/programs_model.dart';
import '../model/drill_model.dart';

abstract class ProgramsDataSource {
  Future<void> addProgram(ProgramsModel program);
  Future<List<ProgramsModel>> getPrograms();
  Future<void> updateProgram(String programId, ProgramsModel program);
  Future<void> deleteProgram(String programId);
}

class ProgramsDataSourceImpl implements ProgramsDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ProgramsDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  CollectionReference<Map<String, dynamic>> _collection() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection('training')
        .doc(uid)
        .collection('programs');
  }

  @override
  Future<void> addProgram(ProgramsModel program) async {
    await _collection().add(program.toMap());
  }

  @override
  Future<List<ProgramsModel>> getPrograms() async {
    final snapshot = await _collection().get();
    return snapshot.docs.map((doc) {
      final data = doc.data();

      // Parse performance metrics safely
      final List<PerformanceMetrics>? metrics = (data['performanceMetrics'] is List)
          ? (data['performanceMetrics'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => PerformanceMetrics(
        stability: m['stability'],
        target: m['target'],
        unit: m['unit'],
      ))
          .toList()
          : null;

      // Parse nested drill
      final DrillModel? drill = (data['drill'] is Map<String, dynamic>)
          ? DrillModel.fromMap(data['drill'] as Map<String, dynamic>)
          : null;

      return ProgramsModel(
        programName: data['programName'],
        programDescription: data['programDescription'],
        modeName: data['modeName'],
        focusArea: data['focusArea'],
        timePressure: data['timePressure'],
        successThreshold: data['successThreshold'],
        successCriteria: data['successCriteria'],
        performanceMetrics: metrics,
        type: data['type'],
        badge: data['badge'],
        badgeColor: data['badgeColor'],
        drill: drill, // ✅ nested drill
        // NOTE: loadout is stored as weaponProfileId in Firestore.
        // If you later want to hydrate ArmoryLoadout, do that at repository layer.
      );
    }).toList();
  }

  @override
  Future<void> updateProgram(String programId, ProgramsModel program) async {
    await _collection().doc(programId).update(program.toMap());
  }

  @override
  Future<void> deleteProgram(String programId) async {
    await _collection().doc(programId).delete();
  }
}
