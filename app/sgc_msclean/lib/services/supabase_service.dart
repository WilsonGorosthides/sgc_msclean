import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  Stream<List<ClientModel>> getClientsStream(String query) {
    return _supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('nome')
        .map((data) {
          return data
              .map((element) => ClientModel.fromMap(element))
              .where((client) =>
                  client.nome.toLowerCase().contains(query.toLowerCase()) ||
                  client.rua.toLowerCase().contains(query.toLowerCase()) ||
                  client.bairro.toLowerCase().contains(query.toLowerCase()))
              .toList();
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