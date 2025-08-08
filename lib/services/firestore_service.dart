import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gestao_leitores/models/evento_religioso.dart';
import 'package:gestao_leitores/models/presenca_model.dart';
import 'package:gestao_leitores/models/usuarios.dart';
import '../models/leitor.dart';
import '../models/escala.dart';
import '../models/escala_liturgica.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _colecaoUsuarios = 'usuarios';

  // ==========================
  // USUÁRIOS
  // ==========================
  Future<Usuario?> login(String celular, String senha) async {
    final query = await _db
        .collection(_colecaoUsuarios)
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
    final docRef = await _db.collection(_colecaoUsuarios).add(usuario.toMap());
    return docRef.id;
  }

  Future<void> updateUsuario(Usuario usuario) async {
    if (usuario.id.isEmpty) throw ArgumentError('ID do usuário não pode ser vazio');
    await _db.collection(_colecaoUsuarios).doc(usuario.id).update(usuario.toMap());
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
      return snapshot.docs.map((doc) => Leitor.fromMap(doc.data(), doc.id)).toList();
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
      return snapshot.docs.map((doc) => Escala.fromMap(doc.data(), doc.id)).toList();
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
    return _db
        .collection('escalas_liturgicas')
        .orderBy('data') // Garanta que o índice esteja configurado no Firestore para isso
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EscalaLiturgica.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateEscalaLiturgica(EscalaLiturgica escala) async {
    if (escala.id.isEmpty) {
      throw ArgumentError("ID da escala não pode ser vazio");
    }
    try {
      final doc = await _db.collection('escalas_liturgicas').doc(escala.id).get();
      if (!doc.exists) {
        throw Exception("Escala Litúrgica não encontrada.");
      }
      await _db.collection('escalas_liturgicas').doc(escala.id).update(escala.toMap());
    } catch (e) {
      throw Exception("Erro ao atualizar escala: $e");
    }
  }

  Future<void> deleteEscalaLiturgica(String id) async {
    await _db.collection('escalas_liturgicas').doc(id).delete();
  }

  // Buscar leitores por IDs (usando o método 'whereIn')
  Future<List<Leitor>> getLeitoresByIds(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];
      final snapshot = await _db
          .collection('leitores')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      return snapshot.docs.map((doc) => Leitor.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Erro ao buscar leitores por IDs: $e');
      rethrow;
    }
  }

  Future<Leitor?> getLeitorById(String id) async {
    final doc = await _db.collection('leitores').doc(id).get();
    if (doc.exists) {
      return Leitor.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // ==========================
  // EVENTOS RELIGIOSOS
  // ==========================
  Future<List<EventoReligioso>> getEventosReligiosos() async {
    final snapshot = await _db
        .collection('eventos_religiosos')
        .orderBy('criadoEm', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => EventoReligioso.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> criarEventoReligioso(EventoReligioso evento) async {
    await _db.collection('eventos_religiosos').add(evento.toMap());
  }

  Future<void> atualizarEventoReligioso(String id, Map<String, dynamic> dados) async {
    await _db.collection('eventos_religiosos').doc(id).update(dados);
  }

  Future<void> deletarEventoReligioso(String id) async {
    await _db.collection('eventos_religiosos').doc(id).delete();
  }

  // ==========================
  // BUSCAR ESCALA E LEITORES
  // ==========================
  Future<Map<String, dynamic>> getEscalaELeitores(String escalaId) async {
    try {
      // Buscar a escala litúrgica
      final escalaDoc = await _db.collection('escalas_liturgicas').doc(escalaId).get();

      if (!escalaDoc.exists) {
        throw Exception("Escala Litúrgica não encontrada.");
      }

      final escala = EscalaLiturgica.fromMap(escalaDoc.data()!, escalaDoc.id);

      // Buscar leitores envolvidos na escala
      List<String> leitoresIds = [
        escala.introdutorId,
        escala.primeiraLeituraLLId,
        escala.primeiraLeituraPTId,
        escala.segundaLeituraLLId,
        escala.segundaLeituraPTId,
        escala.evangelhoId,
      ];

      final leitores = await getLeitoresByIds(leitoresIds);

      return {
        'escala': escala,
        'leitores': leitores,
      };
    } catch (e) {
      print("Erro ao buscar escala e leitores: $e");
      Fluttertoast.showToast(msg: 'Erro ao buscar escala e leitores');
      rethrow;
    }
  }
  // ==========================
  // REGISTRO DE PRESENÇA
  // ==========================
  Future<void> registrarPresenca(PresencaModel presenca) async {
    try {
      await _db.collection('presencas').add(presenca.toMap());
      Fluttertoast.showToast(msg: 'Presença registrada com sucesso!');
    } catch (e) {
      print('Erro ao registrar presença: $e');
      Fluttertoast.showToast(msg: 'Erro ao registrar presença');
    }
    Future<void> atualizarPresenca(PresencaModel presenca) async {
      await FirebaseFirestore.instance
      .collection('presencas')
      .doc(presenca.id)
      .update(presenca.toMap());
    }

  }

// ==========================
// Consulta DE PRESENÇA
// ==========================
Stream<List<PresencaModel>> getPresencas({String? escalaId, String? leitorId}) {
  try {
    // Criar uma consulta inicial para a coleção 'presencas'
    Query query = _db.collection('presencas');

    // Filtrar por escalaId se fornecido
    if (escalaId != null) {
      query = query.where('escalaId', isEqualTo: escalaId);
    }

    // Filtrar por leitorId se fornecido
    if (leitorId != null) {
      query = query.where('leitorId', isEqualTo: leitorId);
    }

    // Retorna um Stream de presenças com a consulta atualizada
    return query.snapshots().map((snapshot) {
      // Transforma os documentos do snapshot em uma lista de objetos PresencaModel
      return snapshot.docs.map((doc) {
        return PresencaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  } catch (e) {
    // Se ocorrer um erro, exibimos uma mensagem e propaga a exceção
    print('Erro ao buscar presenças: $e');
    Fluttertoast.showToast(msg: 'Erro ao buscar presenças');
    rethrow; // Propaga o erro
  }
}

  Future<void> atualizarPresenca(PresencaModel presenca) async {}

}
