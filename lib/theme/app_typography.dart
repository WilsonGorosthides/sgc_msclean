import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografia canonica do app, conforme `docs/design-system.md` secao 3.
///
/// Familia unica: Archivo, servida pelo pacote `google_fonts` (ja no
/// `pubspec.yaml`). O `Caveat` do prototipo nao entra: era voz de pagina, e
/// dentro da interface viraria ruido.
///
/// Os seis tokens do documento sao gravados em slots do `TextTheme` do
/// Material 3, e nao publicados como `TextStyle` soltos, porque `AppBar`,
/// `ListTile` e botoes leem do `TextTheme` — soltos, esses widgets ficariam
/// fora do sistema e cada tela teria que estiliza-los na mao.
///
/// | token do documento | slot        |
/// |--------------------|-------------|
/// | `rotulo`           | `labelSmall`   |
/// | `apoio`            | `bodySmall`    |
/// | `corpo`            | `bodyMedium`   |
/// | `titulo`           | `titleMedium`  |
/// | `secao`            | `titleLarge`   |
/// | `display`          | `headlineSmall`|
///
/// So o par `titulo` -> `titleMedium` esta fixado pelo documento (secao 6);
/// os outros cinco sao escolha deste arquivo.
///
/// Os slots que sobram (`labelLarge`, que e o texto de botao no Material 3,
/// `bodyLarge`, `displayLarge`...) herdam Archivo no tamanho padrao do
/// Material, em vez de serem zerados: zera-los quebraria botao e `ListTile`
/// sem que nenhuma tela tenha pedido. O custo e que existem slots
/// tipograficos fora dos seis tokens.
abstract final class AppTypography {
  /// Ativa os digitos de largura fixa da fonte, para numero em coluna — valor,
  /// data, hora, contagem — nao dancar entre as linhas.
  ///
  /// Aplicado por widget, e nao no [textTheme] inteiro: em texto corrido, a
  /// largura fixa alarga os numeros sem ganho nenhum.
  static const List<FontFeature> digitosTabulares = [
    FontFeature.tabularFigures(),
  ];

  static final TextTheme textTheme = _construir();

  static TextTheme _construir() {
    final base = GoogleFonts.archivoTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: AppColors.tinta, displayColor: AppColors.tinta);

    // O documento nao especifica `letterSpacing` fora do `rotulo`, entao os
    // demais slots ficam com o tracking do Material — nao ha numero medido
    // para substitui-lo.
    return base.copyWith(
      // token `rotulo`: etiquetas em caixa alta
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.9,
      ),
      // token `apoio`: legendas, endereco, lista de pecas
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      // token `corpo`: texto padrao, campos
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      // token `titulo`: nome do cliente, titulo de folha
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      // token `secao`: titulo de tela
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      // token `display`: numero em destaque, valor cobrado
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
