import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/programs_model.dart';

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
      return ProgramsModel(
        programName: data['programName'],
        programDescription: data['programDescription'],
        modeName: data['modeName'],
        trainingType: data['trainingType'],
        focusArea: data['focusArea'],
        difficultyLevel: data['difficultyLevel'],
        noOfShots: data['noOfShots'],
        timePressure: data['timePressure'],
        recommenedDistance: data['recommenedDistance'],
        successThreshold: data['successThreshold'],
        successCriteria: data['successCriteria'],
        timeLimit: data['timeLimit'],
        type: data['type'],
        badge: data['badge'],
        badgeColor: data['badgeColor'],
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