class Escala {
  final String id;
  final String data; // pode ser '2025-07-05'
  final String leitorId;
  final String idioma;
  final String leitura; // tipo de leitura: 1ª, 2ª, Salmo...

  Escala({
    required this.id,
    required this.data,
    required this.leitorId,
    required this.idioma,
    required this.leitura,
  });

  factory Escala.fromMap(Map<String, dynamic> map, String id) {
    return Escala(
      id: id,
      data: map['data'] ?? '',
      leitorId: map['leitorId'] ?? '',
      idioma: map['idioma'] ?? '',
      leitura: map['leitura'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'leitorId': leitorId,
      'idioma': idioma,
      'leitura': leitura,
    };
  }
}
