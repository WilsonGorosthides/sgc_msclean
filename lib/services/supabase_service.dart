import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // Busca a lista de clientes em tempo real
  Stream<List<ClientModel>> getClientsStream(String query) {
    // Pegamos a stream da tabela 'clientes'
    return _supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        .order('nome') // Organiza por ordem alfabética
        .map((data) {
          // Aqui filtramos a lista com base no que o usuário digita na busca
          return data
              .map((element) => ClientModel.fromMap(element))
              .where((client) =>
                  client.nome.toLowerCase().contains(query.toLowerCase()) ||
                  client.endereco.toLowerCase().contains(query.toLowerCase()))
              .toList();
        });
  }
}