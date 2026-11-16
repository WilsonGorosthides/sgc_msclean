import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/services/armazem_local.dart';
import 'package:sgc_msclean/services/bateria.dart';

// Pedido de liberação da economia de bateria (RF-015, issue #101 — CT-066):
// a regra de quando pedir, com o Android trocado por um falso.
class BateriaFalsa implements LiberacaoDeBateria {
  bool estaLiberada = false;
  int pedidos = 0;

  @override
  Future<bool> liberada() async => estaLiberada;

  @override
  Future<void> pedir() async => pedidos++;
}

void main() {
  late BateriaFalsa bateria;
  late ArmazemEmMemoria armazem;
  final hoje = DateTime(2026, 11, 16, 9);

  Future<bool> abrir(DateTime agora) => pedirLiberacaoDeBateria(
      bateria: bateria, armazem: armazem, agora: agora);

  setUp(() {
    bateria = BateriaFalsa();
    armazem = ArmazemEmMemoria();
  });

  group('bateria_test:', () {
    test('pede a liberação quando ainda não foi liberada nem pedida', () async {
      expect(await abrir(hoje), isTrue);
      expect(bateria.pedidos, 1);
      expect(await armazem.ler(chavePedidoDeBateria), isNotNull);
    });

    test('não pede se a bateria já está liberada', () async {
      bateria.estaLiberada = true;
      expect(await abrir(hoje), isFalse);
      expect(bateria.pedidos, 0);
    });

    test('negado, não pede de novo antes de 30 dias', () async {
      await abrir(hoje);
      expect(await abrir(hoje.add(const Duration(days: 10))), isFalse);
      expect(bateria.pedidos, 1);
    });

    test('negado há mais de 30 dias, pede de novo', () async {
      await abrir(hoje);
      expect(await abrir(hoje.add(const Duration(days: 31))), isTrue);
      expect(bateria.pedidos, 2);
    });
  });
}
