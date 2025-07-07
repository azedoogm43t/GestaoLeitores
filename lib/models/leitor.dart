class Leitor {
  final String id;
  final String nome;
  final String contacto;
  final List<String> idiomas;
  final bool ativo;
  final List<String> estadoCivil;

  Leitor({
    required this.id,
    required this.nome,
    required this.contacto,
    required this.idiomas,
    required this.ativo,
    required this.estadoCivil,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'contacto': contacto,
      'idiomas': idiomas,
      'ativo': ativo,
      'estadoCivil': estadoCivil,
    };
  }

  factory Leitor.fromMap(Map<String, dynamic> map, String id) {
    return Leitor(
      id: id,
      nome: map['nome'] ?? '',
      contacto: map['contacto'] ?? '',
      idiomas: List<String>.from(map['idiomas'] ?? []),
      ativo: map['ativo'] ?? true,
      estadoCivil: List<String>.from(map['estadoCivil'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Leitor &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
