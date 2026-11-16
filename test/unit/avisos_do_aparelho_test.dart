import 'package:flutter_test/flutter_test.dart';
import 'package:sgc_msclean/services/avisos_do_aparelho.dart';
import 'package:timezone/data/latest.dart' as fusos;
import 'package:timezone/timezone.dart' as tz;

// O horário do aviso é o do relógio do aparelho (RF-015, CT-062). O defeito:
// os componentes (hora, minuto) eram remontados no fuso fixo de Campo Grande
// (UTC-4); num aparelho em Brasília (UTC-3), o aviso saía uma hora atrasado.
void main() {
  setUpAll(fusos.initializeTimeZones);

  group('avisos_do_aparelho_test:', () {
    test('o aviso é agendado no mesmo instante, qualquer que seja o fuso', () {
      final quando = DateTime(2026, 11, 17, 13, 30); // hora local do aparelho
      for (final fuso in ['America/Campo_Grande', 'America/Sao_Paulo', 'UTC']) {
        final agendado = instanteDoAviso(quando, tz.getLocation(fuso));
        expect(agendado.millisecondsSinceEpoch, quando.millisecondsSinceEpoch,
            reason: fuso);
      }
    });
  });
}
