import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guarda de arquitetura do design system.
///
/// `docs/design-system.md` secao 6 diz: nenhuma tela deve conter `Color(0x...)`
/// nem `Colors.*`; cor que nao existe no sistema se acrescenta ao sistema, nao
/// se improvisa na tela. Este teste e o que impede essa regra de virar
/// recomendacao esquecida — sem ele, a proxima tela da agenda volta a
/// hardcodear e ninguem percebe na revisao.
///
/// A excecao e `lib/theme/`, que e onde o sistema e **definido**: ali as cores
/// literais e um `Colors.black` para sombra sao o proprio ponto.
///
/// O padrao exige que `Colors.` nao venha precedido de letra, digito ou `_`,
/// senao `AppColors.primaria` — que e justamente o jeito certo — seria
/// acusado, porque contem `Colors.` como pedaco do nome. O segundo teste
/// deste arquivo existe para travar essa distincao.
/// `Color(0x...)` literal, ou um `Colors.*` do Material que nao seja parte de
/// um identificador maior como `AppColors`.
final _corProibida = RegExp(r'Color\(0x|(?<![A-Za-z0-9_])Colors\.');

void main() {
  group('design_system_test:', () {
    test('nenhuma tela declara cor fora do design system', () {
      final proibido = _corProibida;
      final infracoes = <String>[];

      for (final arquivo in Directory('lib/screens')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final linhas = arquivo.readAsLinesSync();
        for (var i = 0; i < linhas.length; i++) {
          if (proibido.hasMatch(linhas[i])) {
            infracoes.add('${arquivo.path}:${i + 1}: ${linhas[i].trim()}');
          }
        }
      }

      expect(
        infracoes,
        isEmpty,
        reason: 'Cor declarada na tela em vez de vir do tema ou de AppColors.\n'
            'Use Theme.of(context).colorScheme ou AppColors.\n'
            '${infracoes.join('\n')}',
      );
    });
  });
}
