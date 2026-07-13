import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

class SupabaseService {
  // Nos testes injeta-se um cliente falso; em produção usa o cliente real.
  SupabaseService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // Busca a lista de clientes em tempo real
  Stream<List<ClientModel>> getClientsStream(String query) {
    // Pegamos a stream da tabela 'clientes'
    return _supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('nome') // Organiza por ordem alfabética
        .map((data) => filtrarClientes(data, query));
  }

  // Mapeia as linhas da tabela e aplica o filtro da busca (RF-004):
  // substring em nome ou endereço, sem diferenciar maiúsculas de minúsculas.
  // Função pura: testável sem mockar a stream do Supabase.
  static List<ClientModel> filtrarClientes(
      List<Map<String, dynamic>> data, String query) {
    return data
        .map((element) => ClientModel.fromMap(element))
        .where((client) =>
            client.nome.toLowerCase().contains(query.toLowerCase()) ||
            client.endereco.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}