import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as fusos;
import 'package:timezone/timezone.dart' as tz;

import '../utils/agenda.dart';
import 'armazem_local.dart';
import 'bateria.dart';
import '../utils/avisos.dart';

// Entrega dos avisos no celular (RF-015, issue #95). A regra de quais avisos
// existem está em utils/avisos.dart; aqui, só o agendamento no aparelho.
// A agenda depende desta interface, e os testes injetam uma falsa.
abstract class AgendadorDeAvisos {
  // Troca todos os avisos agendados por estes (a agenda manda a lista inteira
  // a cada mudança; refazer tudo evita aviso órfão de atendimento apagado).
  Future<void> substituir(List<Aviso> avisos);

  // Dia do aviso tocado com o app aberto ou em segundo plano.
  Stream<DateTime> get diasTocados;

  // Dia do aviso que abriu o app, se foi um aviso que o abriu.
  Future<DateTime?> diaDeAbertura();
}

// A área de atendimento é Campo Grande - MS (docs/arquitetura.md §4): o fuso é
// fixo, sem plugin para descobrir o do aparelho.
const fusoDaAgenda = 'America/Campo_Grande';

// Ícone pequeno da notificação: silhueta branca da gota, gerada por
// tool/marca/extrair_marca.py em android/app/src/main/res/drawable-*/.
const _iconeDoAviso = 'ic_aviso';

const _detalhes = NotificationDetails(
  android: AndroidNotificationDetails(
    'agenda',
    'Agenda',
    channelDescription: 'Resumos da agenda e lembretes de atendimento',
    importance: Importance.high,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(''),
  ),
);

// Avisos locais do Android via flutter_local_notifications: funcionam sem
// internet e sem servidor. Na web (e em qualquer outra plataforma) não fazem
// nada. Alarme inexato: o Android pode atrasar alguns minutos para poupar
// bateria, o que basta para um resumo e para o "1 hora antes", e dispensa a
// permissão de alarme exato.
class AvisosDoAparelho implements AgendadorDeAvisos {
  AvisosDoAparelho._();

  static final instancia = AvisosDoAparelho._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _toques = StreamController<DateTime>.broadcast();
  Future<bool>? _pronto;
  Future<void> _fila = Future.value();
  String? _ultimaAssinatura;

  Future<bool> _preparar() => _pronto ??= _iniciar();

  Future<bool> _iniciar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      fusos.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(fusoDaAgenda));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_iconeDoAviso),
        ),
        onDidReceiveNotificationResponse: (resposta) {
          final dia = _lerDia(resposta.payload);
          if (dia != null) _toques.add(dia);
        },
      );
      // Android 13+: pede a permissão de notificação na primeira vez
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      // logo depois: fora da economia de bateria, para os alarmes não serem
      // segurados (#101); negado, só pede de novo em 30 dias
      try {
        await pedirLiberacaoDeBateria(
          bateria: BateriaDoAparelho(),
          armazem: ArmazemPreferencias(),
          agora: DateTime.now(),
        );
      } catch (_) {}
      return true;
    } catch (_) {
      // sem o plugin (testes, plataforma sem suporte): a agenda segue sem avisos
      return false;
    }
  }

  @override
  Stream<DateTime> get diasTocados {
    _preparar();
    return _toques.stream;
  }

  @override
  Future<DateTime?> diaDeAbertura() async {
    if (!await _preparar()) return null;
    try {
      final detalhes = await _plugin.getNotificationAppLaunchDetails();
      if (detalhes?.didNotificationLaunchApp != true) return null;
      return _lerDia(detalhes!.notificationResponse?.payload);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> substituir(List<Aviso> avisos) =>
      _fila = _fila.then((_) => _aplicar(avisos)).catchError((_) {});

  Future<void> _aplicar(List<Aviso> avisos) async {
    if (!await _preparar()) return;
    // a agenda emite a cada mudança; se os avisos são os mesmos, nada a fazer
    final assinatura = avisos
        .map((a) => '${a.quando.toIso8601String()}|${a.titulo}|${a.corpo}')
        .join('\n');
    if (assinatura == _ultimaAssinatura) return;
    await _plugin.cancelAll();
    for (final a in avisos) {
      final q = a.quando;
      await _plugin.zonedSchedule(
        id: a.id,
        title: a.titulo,
        body: a.corpo,
        scheduledDate:
            tz.TZDateTime(tz.local, q.year, q.month, q.day, q.hour, q.minute),
        notificationDetails: _detalhes,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: chaveDoDia(a.dia),
      );
    }
    _ultimaAssinatura = assinatura;
  }

  static DateTime? _lerDia(String? payload) {
    if (payload == null) return null;
    final d = DateTime.tryParse(payload);
    return d == null ? null : soData(d);
  }
}
