import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../utils/texto.dart';
import 'armazem_local.dart';
import 'espelho_local.dart';

class SupabaseService {
  // Nos testes injeta-se um cliente falso; em produção usa o cliente real.
  // O armazém é o do aparelho (shared_preferences), salvo nos testes.
  SupabaseService({SupabaseClient? client, ArmazemLocal? armazem})
      : _client = client,
        _armazem = armazem;

  final SupabaseClient? _client;
  final ArmazemLocal? _armazem;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // Anotar sem internet (RNF-007, #94): as duas streams e o registro de
  // atendimento passam pelo espelho no aparelho; o banco continua sendo
  // acessado só por aqui.
  late final EspelhoLocal _espelho = EspelhoLocal(
    armazem: _armazem ?? ArmazemPreferencias(),
    // Lista de clientes em tempo real. Sem parâmetro de busca: a assinatura
    // realtime é única e vive pela tela inteira — recriá-la a cada mudança
    // de filtro derruba a entrega de eventos UPDATE (CT-008); o filtro da
    // busca é aplicado no widget, sobre a lista emitida.
    clientesRemotos: () => _supabase
        .from('clientes')
        .stream(primaryKey: ['id'])
        // ascending: true explícito — o padrão do .order() da stream é
        // decrescente, diferente do PostgREST via REST (issue #39)
        .order('nome', ascending: true),
    // Atendimentos da agenda (RF-010). Volume pequeno (alguns por dia), então
    // vem tudo numa stream só e a tela filtra dia, semana e mês em memória.
    atendimentosRemotos: () => _supabase
        .from('atendimentos')
        .stream(primaryKey: ['id'])
        .order('data', ascending: true),
    // upsert sem sobrescrever: o id vem do app, então reenviar um item que o
    // banco já gravou (resposta perdida no caminho) não duplica nem altera.
    enviar: (tabela, linha) async {
      await _supabase
          .from(tabela)
          .upsert(linha, onConflict: 'id', ignoreDuplicates: true);
    },
  );

  // Falso quando o banco não respondeu na última tentativa: as telas avisam
  // "sem conexão" e seguem com o que está guardado no aparelho.
  ValueListenable<bool> get conectado => _espelho.conectado;

  Stream<List<ClientModel>> getClientsStream() => _espelho.clientes();

  Stream<List<Atendimento>> getAtendimentosStream() => _espelho.atendimentos();

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

  // Registra um atendimento (RF-005). Vai para a fila do aparelho e é
  // enviado em seguida, ou quando a conexão voltar (RNF-007); id e criado_em
  // nascem no app. Não falha por falta de rede.
  Future<void> addAtendimento(Atendimento atendimento) =>
      _espelho.registrarAtendimento(atendimento);

  // Atualiza um atendimento existente (RF-005: hora alterável depois).
  Future<void> updateAtendimento(Atendimento atendimento) async {
    await _supabase
        .from('atendimentos')
        .update(atendimento.toMap())
        .eq('id', atendimento.id!);
  }

  // Exclui um atendimento (RF-005, #106): cliente que desmarcou ou anotação
  // errada. Vai direto ao banco; sem internet, falha e a tela avisa (RNF-007).
  Future<void> deleteAtendimento(String id) async {
    await _supabase.from('atendimentos').delete().eq('id', id);
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
  // exceção declarada ao RF-001. Entra na fila do aparelho antes do
  // atendimento (RNF-007) e devolve o cliente com o id gerado no app, para o
  // atendimento apontar para ele.
  Future<ClientModel> addClienteProvisorio(String nome) =>
      _espelho.registrarClienteProvisorio(nome);

  // Filtro da busca (RF-004): substring em nome ou em qualquer campo do
  // endereço (via Endereco.buscavel), sem diferenciar maiúsculas nem acento.
  // Ordem por relevância (#113): com a agenda inteira importada, "Paulo" tem
  // de vir antes de "João Paulo". Faixas: 0 nome igual, 1 começa com o termo,
  // 2 uma palavra começa com o termo, 3 no meio do nome, 4 só no endereço.
  // Dentro da faixa, a ordem de entrada (alfabética, da stream). Função pura:
  // testável sem mockar a stream do Supabase.
  static List<ClientModel> filtrarClientes(
      List<ClientModel> clientes, String query) {
    final termo = paraBusca(query.trim());
    if (termo.isEmpty) return clientes.toList();
    final faixas = List.generate(5, (_) => <ClientModel>[]);
    for (final cliente in clientes) {
      final faixa = _faixaDeRelevancia(cliente, termo);
      if (faixa != null) faixas[faixa].add(cliente);
    }
    return [for (final faixa in faixas) ...faixa];
  }

  static int? _faixaDeRelevancia(ClientModel cliente, String termo) {
    final nome = paraBusca(cliente.nome.trim());
    if (nome == termo) return 0;
    int? melhor;
    var i = nome.indexOf(termo);
    while (i >= 0) {
      if (i == 0) return 1;
      if (!_letraOuDigito(nome[i - 1])) return 2;
      melhor = 3;
      i = nome.indexOf(termo, i + 1);
    }
    if (melhor != null) return melhor;
    return paraBusca(cliente.endereco.buscavel).contains(termo) ? 4 : null;
  }

  static final _alfanumerico = RegExp(r'[a-z0-9]');
  static bool _letraOuDigito(String c) => _alfanumerico.hasMatch(c);
}