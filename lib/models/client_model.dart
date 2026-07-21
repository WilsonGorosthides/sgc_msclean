class ClientModel {
  final String? id;
  final String nome;
  final String endereco;
  final List<String> telefones;

  ClientModel({
    this.id,
    required this.nome,
    required this.endereco,
    required this.telefones,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      telefones: _lerTelefones(map),
    );
  }

  // Lê a coluna 'telefones' (text[] no Supabase). Durante a migração (#62),
  // aceita o antigo 'telefone' (string) como lista de um item.
  static List<String> _lerTelefones(Map<String, dynamic> map) {
    final lista = map['telefones'];
    if (lista is List) {
      return lista.map((e) => e.toString()).toList();
    }
    final legado = map['telefone'];
    if (legado != null && legado.toString().isNotEmpty) {
      return [legado.toString()];
    }
    return [];
  }

  // Mapa para escrita no banco; sem o id, que é gerado pelo Supabase.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'endereco': endereco,
      'telefones': telefones,
    };
  }
}
