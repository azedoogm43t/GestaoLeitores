class EscalaLiturgica {
  final String id;
  final String domingo;
  final String data;
  final String introdutorId;
  final String primeiraLeituraLLId;
  final String primeiraLeituraPTId;
  final String segundaLeituraLLId;
  final String segundaLeituraPTId;
  final String evangelhoId;

  EscalaLiturgica({
    required this.id,
    required this.domingo,
    required this.data,
    required this.introdutorId,
    required this.primeiraLeituraLLId,
    required this.primeiraLeituraPTId,
    required this.segundaLeituraLLId,
    required this.segundaLeituraPTId,
    required this.evangelhoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'domingo': domingo,
      'data': data,
      'introdutorId': introdutorId,
      'primeiraLeituraLLId': primeiraLeituraLLId,
      'primeiraLeituraPTId': primeiraLeituraPTId,
      'segundaLeituraLLId': segundaLeituraLLId,
      'segundaLeituraPTId': segundaLeituraPTId,
      'evangelhoId': evangelhoId,
    };
  }

  factory EscalaLiturgica.fromMap(Map<String, dynamic> map, String id) {
    return EscalaLiturgica(
      id: id,
      domingo: map['domingo'] ?? '',
      data: map['data'] ?? '',
      introdutorId: map['introdutorId'] ?? '',
      primeiraLeituraLLId: map['primeiraLeituraLLId'] ?? '',
      primeiraLeituraPTId: map['primeiraLeituraPTId'] ?? '',
      segundaLeituraLLId: map['segundaLeituraLLId'] ?? '',
      segundaLeituraPTId: map['segundaLeituraPTId'] ?? '',
      evangelhoId: map['evangelhoId'] ?? '',
    );
  }
}
