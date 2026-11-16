import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'armazem_local.dart';

// Liberação da economia de bateria (RF-015, issue #101). Samsung, Xiaomi e
// Motorola seguram os alarmes de app parado; sem a liberação, os avisos
// atrasam ou somem. O pedido é o diálogo do próprio Android ("Permitir que o
// MS Clean seja executado em segundo plano?"): um toque, sem a usuária
// procurar nada nas configurações.
abstract class LiberacaoDeBateria {
  Future<bool> liberada();
  Future<void> pedir();
}

const chavePedidoDeBateria = 'bateria.ultimo_pedido';

// Negado, só volta a pedir depois disto. Também cobre o celular novo que
// recebe as preferências do antigo pelo backup do Google: o pedido volta em
// até 30 dias.
const intervaloEntrePedidos = Duration(days: 30);

// Pede se ainda não está liberada e se não pediu nos últimos 30 dias.
// Devolve se pediu.
Future<bool> pedirLiberacaoDeBateria({
  required LiberacaoDeBateria bateria,
  required ArmazemLocal armazem,
  required DateTime agora,
}) async {
  if (await bateria.liberada()) return false;
  final ultimo = DateTime.tryParse(await armazem.ler(chavePedidoDeBateria) ?? '');
  if (ultimo != null && agora.difference(ultimo) < intervaloEntrePedidos) {
    return false;
  }
  await armazem.gravar(chavePedidoDeBateria, agora.toIso8601String());
  await bateria.pedir();
  return true;
}

// Android: canal com a MainActivity (Kotlin), sem plugin. Fora do Android,
// conta como liberada (não há o que pedir).
class BateriaDoAparelho implements LiberacaoDeBateria {
  static const _canal = MethodChannel('msclean/bateria');

  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> liberada() async {
    if (!_android) return true;
    try {
      return await _canal.invokeMethod<bool>('liberada') ?? true;
    } catch (_) {
      return true; // sem o canal: não insiste
    }
  }

  @override
  Future<void> pedir() async {
    if (!_android) return;
    try {
      await _canal.invokeMethod<void>('pedir');
    } catch (_) {}
  }
}
