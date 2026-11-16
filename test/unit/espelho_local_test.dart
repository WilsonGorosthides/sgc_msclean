import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/models/atendimento.dart';
import 'package:sgc_msclean/services/armazem_local.dart';
import 'package:sgc_msclean/services/espelho_local.dart';

// Testes do EspelhoLocal (RNF-007 ampliado, issue #94): a cópia no aparelho da
// agenda e dos clientes, e a fila de envios. Roteiros CT-053 a CT-057 em
// docs/casos-de-teste.md. O banco é falso e pode estar fora do ar; o
// armazenamento é em memória e sobrevive ao EspelhoLocal, como o
// shared_preferences sobrevive a fechar o app.

// Banco falso: guarda as linhas por tabela e, no ar, entrega a stream com elas.
// O envio é idempotente pelo id (o upsert com ignoreDuplicates do service).
class BancoFalso {
  bool noAr = true;
  // simula a resposta perdida: o banco grava, mas o app recebe erro
  bool perderResposta = false;
  final linhas = <String, List<Map<String, dynamic>>>{
    'atendimentos': [],
    'clientes': [],
  };
  final enviados = <String>[]; // 'tabela:id', na ordem em que chegaram

  Stream<List<Map<String, dynamic>>> stream(String tabela) => noAr
      ? Stream.value([...linhas[tabela]!])
      : Stream.error(Exception('sem rede'));

  Future<void> enviar(String tabela, Map<String, dynamic> linha) async {
    if (!noAr) throw Exception('sem rede');
    enviados.add('$tabela:${linha['id']}');
    final tab = linhas[tabela]!;
    if (!tab.any((l) => l['id'] == linha['id'])) tab.add(linha);
    if (perderResposta) {
      perderResposta = false;
      throw Exception('resposta perdida');
    }
  }
}

void main() {
  late BancoFalso banco;
  late ArmazemEmMemoria armazem;
  final hoje = DateTime(2026, 11, 16);
  var contador = 0;

  EspelhoLocal abrir() => EspelhoLocal(
        armazem: armazem,
        atendimentosRemotos: () => banco.stream('atendimentos'),
        clientesRemotos: () => banco.stream('clientes'),
        enviar: banco.enviar,
        novaTentativa: const Duration(hours: 1), // fora do alcance do teste
        novoId: () => 'id-${++contador}',
        agora: () => DateTime(2026, 11, 16, 9, contador),
      );

  Atendimento novo(String clienteId) =>
      Atendimento(data: hoje, periodo: Periodo.manha, clienteId: clienteId);

  // Primeira emissão da stream (a do aparelho ou a do banco).
  Future<List<T>> primeira<T>(Stream<List<T>> s) => s.first;

  // Última emissão depois de a fila de eventos assentar.
  Future<List<T>> ultima<T>(Stream<List<T>> s) async {
    List<T>? valor;
    final sub = s.listen((v) => valor = v);
    await pumpEventQueue();
    await sub.cancel();
    return valor!;
  }

  setUp(() {
    banco = BancoFalso();
    armazem = ArmazemEmMemoria();
    contador = 0;
  });

  group('espelho_local_test:', () {
    test('guarda no aparelho o que chega do banco', () async {
      banco.linhas['atendimentos']!.add({
        'id': 'a1',
        'data': '2026-11-16',
        'periodo': 'manha',
        'cliente_id': 'c1',
      });
      banco.linhas['clientes']!.add({
        'id': 'c1',
        'nome': 'Ana Souza',
        'telefones': ['11 91111-1111'],
      });

      final espelho = abrir();
      await ultima(espelho.atendimentos());
      await ultima(espelho.clientes());

      expect(await armazem.ler(EspelhoLocal.chaveAtendimentos), contains('a1'));
      expect(await armazem.ler(EspelhoLocal.chaveClientes), contains('Ana Souza'));
      expect(espelho.conectado.value, isTrue);
    });

    test('sem conexão, abre com o que está guardado no aparelho', () async {
      banco.linhas['atendimentos']!.add({
        'id': 'a1',
        'data': '2026-11-16',
        'periodo': 'tarde',
        'cliente_id': 'c1',
      });
      banco.linhas['clientes']!.add({'id': 'c1', 'nome': 'Ana Souza'});
      final online = abrir();
      await ultima(online.atendimentos());
      await ultima(online.clientes());

      banco.noAr = false;
      final offline = abrir();
      final atendimentos = await primeira(offline.atendimentos());
      final clientes = await primeira(offline.clientes());

      expect(atendimentos.single.id, 'a1');
      expect(atendimentos.single.periodo, Periodo.tarde);
      expect(clientes.single.nome, 'Ana Souza');
    });

    test('falha de conexão vira aviso, não erro na stream', () async {
      banco.noAr = false;
      final espelho = abrir();

      final erros = <Object>[];
      List<Atendimento>? emitido;
      final sub = espelho
          .atendimentos()
          .listen((v) => emitido = v, onError: erros.add);
      await pumpEventQueue();
      await sub.cancel();

      expect(erros, isEmpty);
      expect(emitido, isEmpty); // nada guardado: lista vazia, com o aviso
      expect(espelho.conectado.value, isFalse);
    });

    test(
        'registrar sem conexão guarda na fila e aparece como aguardando envio',
        () async {
      banco.noAr = false;
      final espelho = abrir();

      await espelho.registrarAtendimento(novo('c1'));
      final lista = await ultima(espelho.atendimentos());

      expect(lista.single.pendente, isTrue);
      expect(lista.single.id, 'id-1');
      expect(await espelho.pendentes(), hasLength(1));
      expect(banco.linhas['atendimentos'], isEmpty);
    });

    test('cliente provisório sem conexão entra na fila antes do atendimento',
        () async {
      banco.noAr = false;
      final espelho = abrir();

      final cliente = await espelho.registrarClienteProvisorio('  Dona Ivete ');
      await espelho.registrarAtendimento(novo(cliente.id!));

      expect(cliente.nome, 'Dona Ivete');
      expect(cliente.provisorio, isTrue);
      final fila = await espelho.pendentes();
      expect(fila.map((p) => p['tabela']), ['clientes', 'atendimentos']);

      final clientes = await ultima(espelho.clientes());
      expect(clientes.single.nome, 'Dona Ivete');
      expect(clientes.single.pendente, isTrue);
      final atendimentos = await ultima(espelho.atendimentos());
      expect(atendimentos.single.clienteId, cliente.id);
    });

    test('ao voltar a conexão envia a fila na ordem e esvazia', () async {
      banco.noAr = false;
      final espelho = abrir();
      final cliente = await espelho.registrarClienteProvisorio('Dona Ivete');
      await espelho.registrarAtendimento(novo(cliente.id!));

      banco.noAr = true;
      final lista = await ultima(espelho.atendimentos());

      expect(banco.enviados, ['clientes:id-1', 'atendimentos:id-2']);
      expect(await espelho.pendentes(), isEmpty);
      expect(espelho.conectado.value, isTrue);
      // enviado, o atendimento continua na agenda, sem a marca
      expect(lista.single.id, 'id-2');
      expect(lista.single.pendente, isFalse);
    });

    test('o id é gerado no app: o envio leva o id e reenviar não duplica',
        () async {
      final espelho = abrir();
      banco.perderResposta = true;

      await espelho.registrarAtendimento(novo('c1'));
      // o banco gravou, mas o app não soube: o item segue na fila
      expect(await espelho.pendentes(), hasLength(1));

      await espelho.enviarPendentes();

      expect(banco.enviados, ['atendimentos:id-1', 'atendimentos:id-1']);
      expect(banco.linhas['atendimentos'], hasLength(1));
      expect(banco.linhas['atendimentos']!.single['id'], 'id-1');
      expect(await espelho.pendentes(), isEmpty);
    });

    test('a fila sobrevive a fechar e reabrir o app', () async {
      banco.noAr = false;
      final antes = abrir();
      await antes.registrarAtendimento(novo('c1'));
      antes.dispose();

      final depois = abrir();
      final lista = await ultima(depois.atendimentos());

      expect(await depois.pendentes(), hasLength(1));
      expect(lista.single.id, 'id-1');
      expect(lista.single.pendente, isTrue);
    });
  });
}
