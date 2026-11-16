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
  });
}
