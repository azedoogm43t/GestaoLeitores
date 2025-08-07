import 'package:cloud_firestore/cloud_firestore.dart';

class PresencaModel {
  final String id;
  final String escalaId;
  final String leitorId;
  final DateTime data;
  final bool presenteEnsaio;
  final bool presenteMissa;
  final double diccao;
  final double colocacaoVoz;
  final double sinaisPontuacao;
  final double ritmo;
  final String observacao;

  PresencaModel({
    required this.id,
    required this.escalaId,
    required this.leitorId,
    required this.data,
    this.presenteEnsaio = false,
    this.presenteMissa = false,
    required this.diccao,
    required this.colocacaoVoz,
    required this.sinaisPontuacao,
    required this.ritmo,
    this.observacao = '',
  });

  factory PresencaModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PresencaModel(
      id: documentId,
      escalaId: map['escalaId'] ?? '',
      leitorId: map['leitorId'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      presenteEnsaio: map['presenteEnsaio'] ?? false,
      presenteMissa: map['presenteMissa'] ?? false,
      diccao: _getDoubleFromDynamic(map['diccao']),
      colocacaoVoz: _getDoubleFromDynamic(map['colocacaoVoz']),
      sinaisPontuacao: _getDoubleFromDynamic(map['sinaisPontuacao']),
      ritmo: _getDoubleFromDynamic(map['ritmo']),
      observacao: map['observacao'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'escalaId': escalaId,
      'leitorId': leitorId,
      'data': Timestamp.fromDate(data),
      'presenteMissa': presenteMissa,
      'presenteEnsaio': presenteEnsaio,
      'diccao': diccao,
      'colocacaoVoz': colocacaoVoz,
      'sinaisPontuacao': sinaisPontuacao,
      'ritmo': ritmo,
      'observacao': observacao,
    };
  }

  // Função auxiliar para garantir que valores booleanos sejam convertidos para double
  static double _getDoubleFromDynamic(dynamic value) {
    if (value is bool) {
      // Se for booleano, retorne 1.0 para true e 0.0 para false
      return value ? 10.0 : 0.0;
    } else if (value is double) {
      // Se for um double, apenas retorne o valor
      return value;
    } else {
      // Caso contrário, retorne 0.0 por padrão
      return 0.0;
    }
  }
}
