import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

class SupabaseService {
  // Nos testes injeta-se um cliente falso; em produção usa o cliente real.
  SupabaseService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // Busca a lista de clientes em tempo real. Sem parâmetro de busca:
  // a assinatura realtime é única e vive pela tela inteira — recriá-la a
  // cada mudança de filtro derruba a entrega de eventos UPDATE (CT-008);
  // o filtro da busca é aplicado no widget, sobre a lista emitida.
  Stream<List<ClientModel>> getClientsStream() {
    // Pegamos a stream da tabela 'clientes'
    return _supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        // ascending: true explícito — o padrão do .order() da stream é
        // decrescente, diferente do PostgREST via REST (issue #39)
        .order('nome', ascending: true)
        .map((data) => data.map(ClientModel.fromMap).toList());
  }

  // Cadastra um cliente novo (RF-001); o id é gerado pelo Supabase.
  Future<void> addClient(ClientModel client) async {
    await _supabase.from('clientes').insert(client.toMap());
  }

  // Atualiza um cliente existente pela chave primária (RF-002).
  Future<void> updateClient(ClientModel client) async {
    await _supabase.from('clientes').update(client.toMap()).eq('id', client.id!);
  }

  // Remove um cliente pela chave primária (RF-008).
  Future<void> deleteClient(ClientModel client) async {
    await _supabase.from('clientes').delete().eq('id', client.id!);
  }

  // Filtro da busca (RF-004): substring em nome ou em qualquer campo do
  // endereço (via Endereco.buscavel), sem diferenciar maiúsculas de
  // minúsculas. Função pura: testável sem mockar a stream do Supabase.
  static List<ClientModel> filtrarClientes(
      List<ClientModel> clientes, String query) {
    final termo = query.toLowerCase();
    return clientes
        .where((client) =>
            client.nome.toLowerCase().contains(termo) ||
            client.endereco.buscavel.contains(termo))
        .toList();
  }
}