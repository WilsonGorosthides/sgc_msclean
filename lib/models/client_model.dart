import 'endereco.dart';

class ClientModel {
  final String? id;
  final String nome;
  final Endereco endereco;
  final List<String> telefones;

  ClientModel({
    this.id,
    required this.nome,
    this.endereco = const Endereco(),
    required this.telefones,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      endereco: _lerEndereco(map['endereco']),
      telefones: _lerTelefones(map),
    );
  }

  // Endereço estruturado (#65): a coluna 'endereco' é jsonb. Durante a
  // migração, uma linha antiga com 'endereco' em texto vira o logradouro,
  // preservando o dado até ser reorganizado nos campos.
  static Endereco _lerEndereco(dynamic valor) {
    if (valor is Map) {
      return Endereco.fromMap(valor.cast<String, dynamic>());
    }
    if (valor is String && valor.trim().isNotEmpty) {
      return Endereco(logradouro: valor);
    }
    return const Endereco();
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
      'endereco': endereco.toMap(),
      'telefones': telefones,
    };
  }
}
