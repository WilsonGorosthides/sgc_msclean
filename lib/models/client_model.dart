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

  // Mapa para escrita no banco; sem o id, que é gerado pelo Supabase.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
    };
  }
}