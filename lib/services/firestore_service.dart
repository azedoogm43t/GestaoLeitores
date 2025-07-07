import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leitor.dart';
import '../models/escala.dart';
import '../models/escala_liturgica.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ==========================
  // LEITORES
  // ==========================

  Future<void> addLeitor(Leitor leitor) async {
    await _db.collection('leitores').add(leitor.toMap());
  }

  Future<void> updateLeitor(Leitor leitor) async {
    await _db.collection('leitores').doc(leitor.id).update(leitor.toMap());
  }

  Stream<List<Leitor>> getLeitores() {
    return _db.collection('leitores').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Leitor.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteLeitor(String id) async {
    await _db.collection('leitores').doc(id).delete();
  }


  // ==========================
  // ESCALAS SIMPLES
  // ==========================

  Future<void> addEscala(Escala escala) async {
    await _db.collection('escalas').add(escala.toMap());
  }

  Stream<List<Escala>> getEscalas() {
    return _db.collection('escalas').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Escala.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteEscala(String id) async {
    await _db.collection('escalas').doc(id).delete();
  }

  // ==========================
  // ESCALAS LITÚRGICAS
  // ==========================

  Future<void> addEscalaLiturgica(EscalaLiturgica escala) async {
    await _db.collection('escalas_liturgicas').add(escala.toMap());
  }

  Stream<List<EscalaLiturgica>> getEscalasLiturgicas() {
    return _db.collection('escalas_liturgicas').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EscalaLiturgica.fromMap(doc.data(), doc.id))
          .toList();
    });
  }


Future<List<Leitor>> getLeitoresByIds(List<String> ids) async {
  try {
    if (ids.isEmpty) return [];

    final snapshot = await _db
        .collection('leitores')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return snapshot.docs
        .map((doc) => Leitor.fromMap(doc.data(), doc.id))
        .toList();
  } catch (e) {
    print('Erro ao buscar leitores por IDs: $e');
    rethrow;
  }
}

Future<void> deleteEscalaLiturgica(String id) async {
  await _db.collection('escalas_liturgicas').doc(id).delete();
}

Future<Leitor?> getLeitorById(String id) async {
  final doc = await _db.collection('leitores').doc(id).get();
  if (doc.exists) {
    return Leitor.fromMap(doc.data()!, doc.id);
  }
  return null;
}



}
