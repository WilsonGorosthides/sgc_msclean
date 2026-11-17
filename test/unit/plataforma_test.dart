import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guarda da preparação do APK (#23): o que só aparece no aparelho instalado.
// A permissão de internet vinha só nos manifestos de debug e profile — um APK
// de release sairia sem acesso ao Supabase.
void main() {
  group('plataforma_test:', () {
    test('o APK de release pede internet', () {
      expect(
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
          contains('android.permission.INTERNET'));
    });

    test('o identificador do app é br.com.msclean.agenda', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "br.com.msclean.agenda"'));
    });

    // Assinatura do release (#109): com a chave de debug, que é de cada
    // máquina, nenhuma atualização instalaria por cima do app da usuária
    // depois de trocar de computador.
    test('o release é assinado com a chave própria, não com a de debug', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('key.properties'));
      expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
    });

    // Contatos do celular (RF-016, #115): só o contato escolhido, pelo
    // seletor do sistema; o app não pede para ler a agenda inteira.
    test('o app não pede permissão de ler os contatos', () {
      final manifesto =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifesto, isNot(contains('READ_CONTACTS')));
      final atividade = File(
              'android/app/src/main/kotlin/com/example/sgc_msclean/MainActivity.kt')
          .readAsStringSync();
      expect(atividade, contains('"msclean/contatos"'));
    });

    test('a chave e as senhas ficam fora do git, com um exemplo versionado',
        () {
      final ignorados = File('android/.gitignore').readAsStringSync();
      expect(ignorados, contains('key.properties'));
      expect(ignorados, contains('**/*.jks'));
      final exemplo = File('android/key.properties.example');
      expect(exemplo.existsSync(), isTrue);
      expect(exemplo.readAsStringSync(), contains('storeFile='));
    });
  });
}
