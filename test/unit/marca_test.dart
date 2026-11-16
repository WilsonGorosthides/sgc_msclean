import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guarda da identidade visual (RNF-008, issue #96 — CT-059): confere nos
// arquivos de plataforma o que só se vê instalado — nome na gaveta, ícone
// adaptativo e tela de abertura no azul-marinho da marca. Os arquivos são
// gerados por flutter_launcher_icons e flutter_native_splash a partir de
// assets/marca/ (config no pubspec.yaml); a guarda pega uma regeração que
// volte ao padrão do Flutter.
void main() {
  const nome = 'MS Clean';
  const azulMarinho = '252C67';
  const res = 'android/app/src/main/res';

  String ler(String caminho) => File(caminho).readAsStringSync();

  // Todos os XML de recurso do Android, para buscar sem depender de qual
  // arquivo o gerador escolheu.
  Iterable<String> xmlsDoAndroid() => Directory(res)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.xml'))
      .map((f) => f.readAsStringSync());

  group('marca_test:', () {
    test('nome MS Clean no Android e na web', () {
      expect(ler('android/app/src/main/AndroidManifest.xml'),
          contains('android:label="$nome"'));

      final manifesto =
          jsonDecode(ler('web/manifest.json')) as Map<String, dynamic>;
      expect(manifesto['name'], nome);
      expect(manifesto['short_name'], nome);

      final index = ler('web/index.html');
      expect(index, contains('<title>$nome</title>'));
      expect(index, contains('apple-mobile-web-app-title" content="$nome"'));
    });

    test('ícone adaptativo com o símbolo sobre o azul-marinho', () {
      for (final mestre in [
        'assets/marca/simbolo_frente.png',
        'assets/marca/simbolo_fundo.png',
        'assets/marca/logo_completo.png',
      ]) {
        expect(File(mestre).existsSync(), isTrue, reason: mestre);
      }

      final adaptativo = ler('$res/mipmap-anydpi-v26/ic_launcher.xml');
      expect(adaptativo, contains('ic_launcher_foreground'));
      expect(adaptativo, contains('ic_launcher_background'));
      expect(
          xmlsDoAndroid().any((x) =>
              x.contains('name="ic_launcher_background"') &&
              x.toUpperCase().contains('#$azulMarinho')),
          isTrue);

      final manifesto =
          jsonDecode(ler('web/manifest.json')) as Map<String, dynamic>;
      expect(manifesto['background_color'].toString().toUpperCase(),
          '#$azulMarinho');
    });

    test('abertura com o logo sobre o azul-marinho', () {
      // Android 12+: splash do sistema, cor de fundo no tema
      expect(
          xmlsDoAndroid().any((x) =>
              x.contains('windowSplashScreenBackground') &&
              x.toUpperCase().contains('#$azulMarinho')),
          isTrue);
      // Android até 11: a imagem da abertura no launch_background
      expect(ler('$res/drawable/launch_background.xml'), contains('splash'));
      // web: a abertura entra no index.html
      expect(ler('web/index.html').toLowerCase(), contains('splash'));
    });
  });
}
