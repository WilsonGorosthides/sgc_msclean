import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  /// Busca clientes diretamente no servidor (Ideal para grandes volumes como 4mil+ registros)
  Future<List<ClientModel>> searchClients(
    String query, {
    String orderBy = 'nome',
    bool ascending = true,
  }) async {
    // Iniciamos a query básica
    var request = _supabase.from('clientes').select();

    // Se houver texto na busca, filtramos Nome, Bairro ou Rua usando ILIKE (case insensitive)
    if (query.isNotEmpty) {
      request = request.or(
        'nome.ilike.%$query%,bairro.ilike.%$query%,rua.ilike.%$query%',
      );
    }

    // Aplica a ordenação escolhida no menu de filtros
    final response = await request.order(orderBy, ascending: ascending);

    // Converte a lista dinâmica do Supabase para nossa lista de objetos ClientModel
    return (response as List).map((e) => ClientModel.fromMap(e)).toList();
  }

  /// Mantemos o Stream para casos de uso em tempo real se necessário
  Stream<List<ClientModel>> getClientsStream(String query, {String orderBy = 'nome', bool ascending = true}) {
    return _supabase.from('clientes').stream(primaryKey: ['id']).order(orderBy, ascending: ascending).map((data) {
      final lista = data.map((element) => ClientModel.fromMap(element)).toList();
      if (query.isEmpty) return lista;
      return lista.where((c) {
        final busca = query.toLowerCase();
        return c.nome.toLowerCase().contains(busca) || 
               c.bairro.toLowerCase().contains(busca) ||
               c.rua.toLowerCase().contains(busca);
      }).toList();
    });
  }

  Future<void> saveClient(ClientModel client) async {
    await _supabase.from('clientes').insert({
      'nome': client.nome,
      'rua': client.rua,
      'numero': client.numero,
      'bairro': client.bairro,
      'complemento': client.complemento,
      'telefone': client.telefone,
    });
  }

  Future<void> updateClient(ClientModel client) async {
    await _supabase.from('clientes').update({
      'nome': client.nome,
      'rua': client.rua,
      'numero': client.numero,
      'bairro': client.bairro,
      'complemento': client.complemento,
      'telefone': client.telefone,
    }).eq('id', client.id!);
  }

  Future<void> deleteClient(String id) async {
    await _supabase.from('clientes').delete().eq('id', id);
  }
}