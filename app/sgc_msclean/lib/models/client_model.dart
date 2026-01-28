class ClientModel {
  final String? id;
  final String nome;
  final String rua;
  final String numero;
  final String bairro;
  final String complemento;
  final String telefone;

  ClientModel({
    this.id,
    required this.nome,
    required this.rua,
    required this.numero,
    required this.bairro,
    required this.complemento,
    required this.telefone,
  });

  // Converte o que vem do Supabase (JSON) para o código (Objeto)
  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      rua: map['rua'] ?? '',
      numero: map['numero'] ?? '',
      bairro: map['bairro'] ?? '',
      complemento: map['complemento'] ?? '',
      telefone: map['telefone'] ?? '',
    );
  }

  // Atalho para mostrar o endereço completo na lista
  String get enderecoExibicao => '$rua, $numero - $bairro';
}