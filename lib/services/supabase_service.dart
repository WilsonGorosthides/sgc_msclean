import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/atendimento.dart';
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

  // Atendimentos da agenda (RF-010). Volume pequeno (alguns por dia), então
  // vem tudo numa stream só e a tela filtra dia, semana e mês em memória.
  Stream<List<Atendimento>> getAtendimentosStream() {
    return _supabase
        .from('atendimentos')
        .stream(primaryKey: ['id'])
        .order('data', ascending: true)
        .map((data) => data.map(Atendimento.fromMap).toList());
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

  // Registra um atendimento (RF-005); id e criado_em vêm do banco.
  Future<void> addAtendimento(Atendimento atendimento) async {
    await _supabase.from('atendimentos').insert(atendimento.toMap());
  }

  // Atualiza um atendimento existente (RF-005: hora alterável depois).
  Future<void> updateAtendimento(Atendimento atendimento) async {
    await _supabase
        .from('atendimentos')
        .update(atendimento.toMap())
        .eq('id', atendimento.id!);
  }

  // Marca ou desmarca "serviço feito" e "cliente pagou" (RF-014). Grava só a
  // coluna pedida: os dois estados são independentes.
  Future<void> marcarConclusao(String id, {bool? feito, bool? pago}) async {
    await _supabase.from('atendimentos').update({
      if (feito != null) 'feito': feito,
      if (pago != null) 'pago': pago,
    }).eq('id', id);
  }

  // Cliente provisório (RF-005): só o nome, sem telefone nem endereço — a
  // exceção declarada ao RF-001. Devolve o cliente com o id gerado, para o
  // atendimento apontar para ele.
  Future<ClientModel> addClienteProvisorio(String nome) async {
    final linha = await _supabase
        .from('clientes')
        .insert(ClientModel(nome: nome.trim(), telefones: const []).toMap())
        .select()
        .single();
    return ClientModel.fromMap(linha);
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