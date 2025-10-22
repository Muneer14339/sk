import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/saved_session_model.dart';

abstract class SavedSessionsDataSource {
  Future<String> saveSession(SavedSessionModel session);
  Future<List<SavedSessionModel>> listSessions();
  Future<SavedSessionModel> getSession(String sessionId);
}

class SavedSessionsDataSourceImpl implements SavedSessionsDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SavedSessionsDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _collection() {
    final uid = auth.currentUser!.uid;
    return firestore
        .collection('training')
        .doc(uid)
        .collection('sessions')
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
      toFirestore: (data, _) => data,
    );
  }

  @override
  Future<String> saveSession(SavedSessionModel session) async {
    final col = _collection();
    final docRef = await col.add(session.toJson());
    return docRef.id;
  }

  @override
  Future<List<SavedSessionModel>> listSessions() async {
    final col = _collection();
    final query = await col.orderBy('startedAt', descending: true).get();
    return query.docs
        .map((d) => SavedSessionModel.fromFirestore(d.id, d.data()))
        .toList();
  }

  @override
  Future<SavedSessionModel> getSession(String sessionId) async {
    final col = _collection();
    final doc = await col.doc(sessionId).get();
    final data = doc.data() ?? <String, dynamic>{};
    return SavedSessionModel.fromFirestore(doc.id, data);
  }
}