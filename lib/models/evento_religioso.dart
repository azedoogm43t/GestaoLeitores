import 'package:cloud_firestore/cloud_firestore.dart';

class EventoReligioso {
  final String id;
  final String titulo;
  final String observacao;
  final DateTime criadoEm;

  EventoReligioso({
    required this.id,
    required this.titulo,
    required this.observacao,
    required this.criadoEm,
  });

  factory EventoReligioso.fromMap(String id, Map<String, dynamic> data) {
    return EventoReligioso(
      id: id,
      titulo: data['titulo'] ?? '',
      observacao: data['observacao'] ?? '',
      criadoEm: (data['criadoEm'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'observacao': observacao,
      'criadoEm': DateTime.now(),
    };
  }
}
