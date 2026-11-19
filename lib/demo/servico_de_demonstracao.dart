import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../models/item_de_preco.dart';
import '../screens/agenda_screen.dart';
import '../services/avisos_do_aparelho.dart';
import '../services/supabase_service.dart';
import '../utils/avisos.dart';
import 'dados_de_demonstracao.dart';

// Modo demonstração (#139): o mesmo serviço que as telas recebem, só que em
// memória, com os dados fictícios. Nenhum método chega ao Supabase (o espelho
// do aparelho nem é criado): o que ela faz na demonstração some ao fechar.
class ServicoDeDemonstracao extends SupabaseService {
  ServicoDeDemonstracao({DateTime? hoje}) {
    final dados = DadosDeDemonstracao.gerar(hoje ?? DateTime.now());
    _clientes.addAll(dados.clientes);
    _atendimentos.addAll(dados.atendimentos);
    _precos.addAll(dados.precos);
  }

  final _clientes = <ClientModel>[];
  final _atendimentos = <Atendimento>[];
  final _precos = <ItemDePreco>[];
  final _mudou = StreamController<void>.broadcast();
  final _conectado = ValueNotifier(true);
  var _proximo = 0;

  String _id(String prefixo) => 'demo-$prefixo-novo-${_proximo++}';

  // A lista de agora e, depois, a cada mudança.
  Stream<List<T>> _vivo<T>(List<T> Function() atual) async* {
    yield atual();
    await for (final _ in _mudou.stream) {
      yield atual();
    }
  }

  void _avisar() => _mudou.add(null);

  @override
  ValueListenable<bool> get conectado => _conectado;

  @override
  Stream<List<ClientModel>> getClientsStream() =>
      _vivo(() => [..._clientes]..sort((a, b) => a.nome.compareTo(b.nome)));

  @override
  Stream<List<Atendimento>> getAtendimentosStream() =>
      _vivo(() => [..._atendimentos]..sort((a, b) => a.data.compareTo(b.data)));

  @override
  Stream<List<ItemDePreco>> getPrecosStream() =>
      _vivo(() => [..._precos]..sort((a, b) => a.ordem.compareTo(b.ordem)));

  ItemDePreco _comId(ItemDePreco i, String id) => ItemDePreco(
    id: id,
    nome: i.nome,
    unidade: i.unidade,
    valor: i.valor,
    ordem: i.ordem,
    peca: i.peca,
    variante: i.variante,
    servico: i.servico,
    retratil: i.retratil,
    categoria: i.categoria,
  );

  @override
  Future<void> addPreco(ItemDePreco item) async {
    _precos.add(_comId(item, _id('p')));
    _avisar();
  }

  @override
  Future<void> addPrecos(List<ItemDePreco> itens) async {
    _precos.addAll([for (final i in itens) _comId(i, _id('p'))]);
    _avisar();
  }

  @override
  Future<void> updatePreco(ItemDePreco item) async {
    final i = _precos.indexWhere((p) => p.id == item.id);
    if (i >= 0) _precos[i] = item;
    _avisar();
  }

  @override
  Future<void> deletePreco(String id) async {
    _precos.removeWhere((p) => p.id == id);
    _avisar();
  }

  ClientModel _clienteComId(ClientModel c, String id) => ClientModel(
    id: id,
    nome: c.nome,
    endereco: c.endereco,
    telefones: c.telefones,
  );

  @override
  Future<void> addClient(ClientModel client) async {
    _clientes.add(_clienteComId(client, _id('c')));
    _avisar();
  }

  @override
  Future<void> updateClient(ClientModel client) async {
    final i = _clientes.indexWhere((c) => c.id == client.id);
    if (i >= 0) _clientes[i] = client;
    _avisar();
  }

  @override
  Future<void> deleteClient(ClientModel client) async {
    _clientes.removeWhere((c) => c.id == client.id);
    _avisar();
  }

  Atendimento _atendimentoComId(Atendimento a, String id) => Atendimento(
    id: id,
    data: a.data,
    periodo: a.periodo,
    hora: a.hora,
    clienteId: a.clienteId,
    local: a.local,
    pecas: a.pecas,
    valor: a.valor,
    criadoEm: a.criadoEm ?? DateTime.now(),
    feito: a.feito,
    pago: a.pago,
  );

  @override
  Future<void> addAtendimento(Atendimento atendimento) async {
    _atendimentos.add(
      _atendimentoComId(atendimento, atendimento.id ?? _id('a')),
    );
    _avisar();
  }

  @override
  Future<void> updateAtendimento(Atendimento atendimento) async {
    final i = _atendimentos.indexWhere((a) => a.id == atendimento.id);
    if (i >= 0) _atendimentos[i] = atendimento;
    _avisar();
  }

  @override
  Future<void> deleteAtendimento(String id) async {
    _atendimentos.removeWhere((a) => a.id == id);
    _avisar();
  }

  @override
  Future<void> marcarConclusao(String id, {bool? feito, bool? pago}) async {
    final i = _atendimentos.indexWhere((a) => a.id == id);
    if (i >= 0) {
      _atendimentos[i] = _atendimentos[i].copyWith(feito: feito, pago: pago);
    }
    _avisar();
  }

  @override
  Future<ClientModel> addClienteProvisorio(String nome) =>
      addClienteDoContato(nome, null);

  @override
  Future<ClientModel> addClienteDoContato(String nome, String? telefone) async {
    final cliente = ClientModel(
      id: _id('c'),
      nome: nome,
      telefones: [if (telefone != null) telefone],
    );
    _clientes.add(cliente);
    _avisar();
    return cliente;
  }
}

// Avisos do celular desligados na demonstração: nada é agendado.
class AvisosDeDemonstracao implements AgendadorDeAvisos {
  @override
  Future<void> substituir(List<Aviso> avisos) async {}

  @override
  Stream<DateTime> get diasTocados => const Stream.empty();

  @override
  Future<DateTime?> diaDeAbertura() async => null;
}

// A agenda da demonstração. Com [hoje] (testes), o relógio fica parado nele.
Widget telaDeDemonstracao({DateTime? hoje}) => AgendaScreen(
  service: ServicoDeDemonstracao(hoje: hoje),
  avisos: AvisosDeDemonstracao(),
  agora: hoje == null ? null : () => hoje,
);
