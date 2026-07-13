class ClientModel {
  final String? id;
  final String nome;
  final String endereco;
  final String telefone;

  ClientModel({this.id, required this.nome, required this.endereco, required this.telefone});

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      telefone: map['telefone'] ?? '',
    );
  }
}