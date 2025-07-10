import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gestao_leitores/models/evento_religioso.dart';
import 'package:gestao_leitores/models/usuarios.dart';
import '../models/leitor.dart';
import '../models/escala.dart';
import '../models/escala_liturgica.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  final String _colecao = 'usuarios';

  Future<Usuario?> login(String celular, String senha) async {
    final query = await _db
        .collection(_colecao)
        .where('celular', isEqualTo: celular)
        .where('senha', isEqualTo: senha)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Usuario.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  Future<String> addUsuario(Usuario usuario) async {
    final docRef = await _db.collection(_colecao).add(usuario.toMap());
    return docRef.id;
  }

  Future<void> updateUsuario(Usuario usuario) async {
    if (usuario.id.isEmpty)
      throw ArgumentError('ID do usuário não pode ser vazio');
    await _db.collection(_colecao).doc(usuario.id).update(usuario.toMap());
  }

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
  return FirebaseFirestore.instance
      .collection('escalas_liturgicas')
      .orderBy('data')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => EscalaLiturgica.fromMap(doc.data(), doc.id))
          .toList());
}


  Future<void> updateEscalaLiturgica(EscalaLiturgica escala) async {
    if (escala.id.isEmpty) {
      throw ArgumentError("ID da escala não pode ser vazio");
    }

    try {
      await _db
          .collection('escalas_liturgicas')
          .doc(escala.id)
          .update(escala.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar escala: $e");
    }
  }

// Future<List<Leitor>> getLeitoresByIds(List<String> ids) async {
//   // Exemplo com Firebase
//   final snapshot = await _db.collection('leitores').where(FieldPath.documentId, whereIn: ids).get();
//   return snapshot.docs.map((doc) => Leitor.fromMap(doc.data(), doc.id)).toList();
// }

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

  Future<Map<String, Leitor>> _buscarLeitoresDaEscala(
    EscalaLiturgica escala,
  ) async {
    final ids = {
      escala.introdutorId,
      escala.primeiraLeituraLLId,
      escala.primeiraLeituraPTId,
      escala.segundaLeituraLLId,
      escala.segundaLeituraPTId,
      escala.evangelhoId,
    }.where((id) => id.trim().isNotEmpty).toList(); // <<<<< apenas IDs válidos

    final leitores = await this.getLeitoresByIds(ids);
    return {for (var l in leitores) l.id: l};
  }

  Future<Map<String, Leitor>> getLeitoresDaEscala(
      EscalaLiturgica escala) async {
    try {
      final leitores = await _buscarLeitoresDaEscala(escala);
      return leitores;
    } catch (e) {
      print('Erro ao buscar leitores da escala: $e');
      return {};
    }
  }

  // ==========================
  // EVENTOS RELIGIOSOS
  // ==========================

  Future<List<EventoReligioso>> getEventosReligiosos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('eventos_religiosos')
        .orderBy('criadoEm', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => EventoReligioso.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> criarEventoReligioso(EventoReligioso evento) async {
    await FirebaseFirestore.instance
        .collection('eventos_religiosos')
        .add(evento.toMap());
  }

  Future<void> atualizarEventoReligioso(
      String id, Map<String, dynamic> dados) async {
    await FirebaseFirestore.instance
        .collection('eventos_religiosos')
        .doc(id)
        .update(dados);
  }

  Future<void> deletarEventoReligioso(String id) async {
    await FirebaseFirestore.instance
        .collection('eventos_religiosos')
        .doc(id)
        .delete();
  }
}
