class Usuario {
  String id;
  String celular;
  String senha;
  String nome;
  bool estado;

  Usuario({
    required this.id,
    required this.celular,
    required this.senha,
    required this.nome,
    this.estado = true,
  });

  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    return Usuario(
      id: id,
      celular: map['celular'] ?? '',
      senha: map['senha'] ?? '',
      nome: map['nome'] ?? '',
      estado: map['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'celular': celular,
      'senha': senha,
      'nome': nome,
      'ativo': estado,
    };
  }
}
