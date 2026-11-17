import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../models/item_de_preco.dart';
import 'armazem_local.dart';

typedef Linhas = List<Map<String, dynamic>>;

// Anotar sem internet (RNF-007 ampliado, issue #94). Fica atrás do
// SupabaseService — que continua a única porta para o backend — e faz três
// coisas:
//
// 1. Guarda no aparelho a última leitura de atendimentos, de clientes e da
//    tabela de preços (RF-013, #123); ao abrir, emite primeiro o que está
//    guardado e depois o que vier do banco.
// 2. Mantém uma fila de envios (cliente provisório e atendimento novo). O
//    item entra na fila antes de qualquer tentativa de rede, aparece nas
//    streams com a marca de pendente e é enviado, na ordem, sempre que o
//    banco responder. O id é gerado aqui: reenviar não duplica.
// 3. Expõe o estado de conexão, para as telas avisarem "sem conexão". Falha
//    de rede nunca vira erro na stream.
class EspelhoLocal {
  EspelhoLocal({
    required ArmazemLocal armazem,
    required Stream<Linhas> Function() atendimentosRemotos,
    required Stream<Linhas> Function() clientesRemotos,
    // Tabela de preços (RF-013): só leitura espelhada, a escrita vai direto
    // ao banco. Opcional para os testes que não a usam.
    Stream<Linhas> Function()? precosRemotos,
    required Future<void> Function(String tabela, Map<String, dynamic> linha)
        enviar,
    Duration novaTentativa = const Duration(seconds: 20),
    Duration prazo = const Duration(seconds: 10),
    String Function()? novoId,
    DateTime Function()? agora,
  })  : _armazem = armazem,
        _atendimentosRemotos = atendimentosRemotos,
        _clientesRemotos = clientesRemotos,
        _precosRemotos = precosRemotos ?? (() => Stream.value(const [])),
        _enviar = enviar,
        _novaTentativa = novaTentativa,
        _prazo = prazo,
        _novoId = novoId ?? gerarUuid,
        _agora = agora ?? DateTime.now;

  static const chaveAtendimentos = 'espelho.atendimentos';
  static const chaveClientes = 'espelho.clientes';
  static const chaveFila = 'espelho.fila';
  static const chavePrecos = 'espelho.precos';

  final ArmazemLocal _armazem;
  final Stream<Linhas> Function() _atendimentosRemotos;
  final Stream<Linhas> Function() _clientesRemotos;
  final Stream<Linhas> Function() _precosRemotos;
  final Future<void> Function(String tabela, Map<String, dynamic> linha)
      _enviar;
  final Duration _novaTentativa;
  final Duration _prazo;
  final String Function() _novoId;
  final DateTime Function() _agora;

  final ValueNotifier<bool> _conectado = ValueNotifier(true);
  ValueListenable<bool> get conectado => _conectado;

  // Fila de envios: [{'tabela': ..., 'linha': {...}}], na ordem de registro.
  // Lida do aparelho uma vez e regravada a cada mudança.
  List<Map<String, dynamic>>? _fila;

  // Enviados nesta sessão que a stream do banco ainda não devolveu: seguem à
  // vista (sem a marca) até chegarem pelo banco, para o item não piscar.
  final Map<String, Linhas> _enviados = {
    'atendimentos': [],
    'clientes': [],
    'precos': [],
  };

  final _mudou = StreamController<void>.broadcast();
  Future<void> _envio = Future.value();

  Stream<List<Atendimento>> atendimentos() => _espelho(
        tabela: 'atendimentos',
        chave: chaveAtendimentos,
        remoto: _atendimentosRemotos,
        ler: (m, pendente) => Atendimento.fromMap(m, pendente: pendente),
      );

  Stream<List<ClientModel>> clientes() => _espelho(
        tabela: 'clientes',
        chave: chaveClientes,
        remoto: _clientesRemotos,
        ler: (m, pendente) => ClientModel.fromMap(m, pendente: pendente),
        // o banco entrega em ordem de nome; um item local entra na mesma ordem
        ordenar: (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );

  // Tabela de preços (RF-013), guardada no aparelho para o cálculo do valor
  // sem internet (#124). Nada dela passa pela fila.
  Stream<List<ItemDePreco>> precos() => _espelho(
        tabela: 'precos',
        chave: chavePrecos,
        remoto: _precosRemotos,
        ler: (m, _) => ItemDePreco.fromMap(m),
      );

  // Cliente provisório (RF-005) criado no aparelho: o id nasce aqui, para o
  // atendimento apontar para ele antes de o cliente chegar ao banco.
  // Com telefones, é o cliente vindo dos contatos do celular (RF-016): não é
  // provisório, mas entra na mesma fila, pelo mesmo caminho.
  Future<ClientModel> registrarClienteProvisorio(String nome,
      {List<String> telefones = const []}) async {
    final linha = {
      'id': _novoId(),
      ...ClientModel(nome: nome.trim(), telefones: telefones).toMap(),
    };
    await _enfileirar('clientes', linha);
    return ClientModel.fromMap(linha, pendente: true);
  }

  // Atendimento novo. criado_em vai do aparelho: preserva a ordem em que foi
  // anotado, mesmo que o envio aconteça horas depois.
  Future<void> registrarAtendimento(Atendimento atendimento) async {
    await _enfileirar('atendimentos', {
      'id': atendimento.id ?? _novoId(),
      ...atendimento.toMap(),
      'criado_em': _agora().toUtc().toIso8601String(),
    });
  }

  // Uma cópia da fila, na ordem de envio.
  Future<List<Map<String, dynamic>>> pendentes() async =>
      [...await _carregarFila()];

  // Envia a fila na ordem, parando no primeiro erro (o resto espera a próxima
  // tentativa: um atendimento não pode chegar antes do seu cliente). Chamadas
  // simultâneas entram em sequência, nunca em paralelo.
  Future<void> enviarPendentes() =>
      _envio = _envio.then((_) => _enviarFila()).catchError((_) {});

  void dispose() {
    _mudou.close();
  }

  // ---- interno ----

  Future<List<Map<String, dynamic>>> _carregarFila() async {
    if (_fila != null) return _fila!;
    final guardada = _decodificar(await _armazem.ler(chaveFila));
    return _fila ??= guardada ?? [];
  }

  Future<void> _gravarFila() =>
      _armazem.gravar(chaveFila, jsonEncode(_fila ?? const []));

  Future<void> _enfileirar(String tabela, Map<String, dynamic> linha) async {
    final fila = await _carregarFila();
    fila.add({'tabela': tabela, 'linha': linha});
    await _gravarFila();
    _avisar();
    // não espera a rede: com sinal fraco o formulário não pode ficar preso
    unawaited(enviarPendentes());
  }

  Future<void> _enviarFila() async {
    final fila = await _carregarFila();
    while (fila.isNotEmpty) {
      final item = fila.first;
      final tabela = item['tabela'] as String;
      final linha = (item['linha'] as Map).cast<String, dynamic>();
      try {
        await _enviar(tabela, linha);
      } catch (_) {
        _conectado.value = false;
        _avisar();
        return;
      }
      fila.removeAt(0);
      _enviados[tabela]?.add(linha);
      await _gravarFila();
      _conectado.value = true;
    }
    _avisar();
  }

  void _avisar() {
    if (!_mudou.isClosed) _mudou.add(null);
  }

  // A stream do Supabase pode entregar a mesma linha duas vezes: o INSERT do
  // realtime chega depois da leitura inicial que já a trazia (#128 — atendimento
  // recém-salvo em dobro na agenda até reabrir o app). Fica uma por id, a
  // última recebida, na posição da primeira.
  static Linhas _semRepetidas(Linhas dados) {
    final porId = <String, Map<String, dynamic>>{};
    final semId = <Map<String, dynamic>>[];
    for (final linha in dados) {
      final id = linha['id']?.toString();
      if (id == null) {
        semId.add(linha);
      } else {
        porId[id] = linha;
      }
    }
    if (porId.length + semId.length == dados.length) return dados;
    final vistos = <String>{};
    return [
      for (final linha in dados)
        if (linha['id'] == null)
          linha
        else if (vistos.add(linha['id'].toString()))
          porId[linha['id'].toString()]!,
    ];
  }

  static List<Map<String, dynamic>>? _decodificar(String? texto) {
    if (texto == null) return null;
    try {
      final valor = jsonDecode(texto);
      if (valor is! List) return null;
      return [
        for (final item in valor)
          if (item is Map) item.cast<String, dynamic>(),
      ];
    } catch (_) {
      return null; // guardado corrompido: vale como nada guardado
    }
  }

  // Uma stream espelhada: o guardado no aparelho, depois o banco, mais o que
  // está na fila ou acabou de ser enviado.
  Stream<List<T>> _espelho<T>({
    required String tabela,
    required String chave,
    required Stream<Linhas> Function() remoto,
    required T Function(Map<String, dynamic> linha, bool pendente) ler,
    int Function(T a, T b)? ordenar,
  }) {
    // Criada já na chamada (o listen fica para quando a tela ouvir), e
    // recriada a cada nova tentativa depois de uma falha.
    var fonte = remoto();
    Linhas? linhas;
    StreamSubscription<Linhas>? assinatura;
    StreamSubscription<void>? mudancas;
    Timer? tentativa;
    Timer? limite;
    late final StreamController<List<T>> saida;

    Future<void> emitir() async {
      if (linhas == null || saida.isClosed) return;
      final fila = await _carregarFila();
      if (saida.isClosed) return;
      final base = linhas!;
      final ids = {for (final l in base) l['id']?.toString()};
      final enviados = _enviados[tabela]!
        ..removeWhere((l) => ids.contains(l['id']?.toString()));
      final extras = [
        for (final l in enviados) ler(l, false),
        for (final item in fila)
          if (item['tabela'] == tabela &&
              !ids.contains((item['linha'] as Map)['id']?.toString()))
            ler((item['linha'] as Map).cast<String, dynamic>(), true),
      ];
      final lista = [for (final l in base) ler(l, false), ...extras];
      if (extras.isNotEmpty && ordenar != null) lista.sort(ordenar);
      saida.add(lista);
    }

    void semConexao() {
      _conectado.value = false;
      linhas ??= [];
      emitir();
    }

    void assinar() {
      // sem resposta nem erro no prazo (sinal muito fraco): conta como sem
      // conexão; a assinatura continua e os dados entram se chegarem
      limite = Timer(_prazo, semConexao);
      assinatura = fonte.listen(
        (dados) {
          limite?.cancel();
          linhas = _semRepetidas(dados);
          _conectado.value = true;
          _armazem.gravar(chave, jsonEncode(linhas)).catchError((_) {});
          emitir();
          enviarPendentes();
        },
        onError: (Object _) {
          limite?.cancel();
          semConexao();
          assinatura?.cancel();
          tentativa?.cancel();
          tentativa = Timer(_novaTentativa, () {
            if (saida.isClosed) return;
            fonte = remoto();
            assinar();
          });
        },
      );
    }

    saida = StreamController<List<T>>(
      onListen: () async {
        mudancas = _mudou.stream.listen((_) => emitir());
        final guardado = _decodificar(await _armazem.ler(chave));
        if (linhas == null && guardado != null) {
          linhas = _semRepetidas(guardado); // cópia gravada antes do #128
          await emitir();
        }
        if (!saida.isClosed) assinar();
      },
      onCancel: () async {
        limite?.cancel();
        tentativa?.cancel();
        await mudancas?.cancel();
        await assinatura?.cancel();
        unawaited(saida.close());
      },
    );
    return saida.stream;
  }
}

// uuid v4 com gerador seguro: o id do registro nasce no aparelho.
String gerarUuid() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
