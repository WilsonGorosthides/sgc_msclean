import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Tema do aplicativo, montado a partir dos tokens de
/// `docs/design-system.md`.
///
/// O app e claro e so claro: o documento (secao 8) registra que um tema
/// escuro exigiria medir a paleta inteira de novo e que nao ha demanda da
/// usuaria.
abstract final class AppTheme {
  static final ThemeData claro = ThemeData(
    useMaterial3: true,
    colorScheme: _esquemaClaro,
    textTheme: AppTypography.textTheme,
    scaffoldBackgroundColor: AppColors.fundo,

    // Os temas de componente abaixo existem para que a tela nao precise
    // estilizar nada: um `Card` sem parametro de cor, raio ou elevacao ja sai
    // com a forma do sistema. O item 2 da issue #60 pede exatamente isso —
    // estilo centralizado em vez de solto pelas telas.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.superficie,
      foregroundColor: AppColors.tinta,
      centerTitle: true,
      // Sem sombra: a separacao do conteudo e feita pela borda inferior, ja
      // que o `surfaceTint` esta desligado e a elevacao do Material 3 nao
      // teria como se manifestar em cor.
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: AppColors.borda)),
    ),

    cardTheme: CardThemeData(
      color: AppColors.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medio),
        side: const BorderSide(color: AppColors.borda),
      ),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.tintaFraca,
      textColor: AppColors.tinta,
      subtitleTextStyle: TextStyle(color: AppColors.tintaFraca),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.superficie,
      // Campo usa o raio pequeno (design-system.md secao 5).
      border: _bordaCampo(AppColors.borda),
      enabledBorder: _bordaCampo(AppColors.borda),
      focusedBorder: _bordaCampo(AppColors.primaria, espessura: 2),
      errorBorder: _bordaCampo(AppColors.alerta),
      focusedErrorBorder: _bordaCampo(AppColors.alerta, espessura: 2),
      disabledBorder: _bordaCampo(AppColors.tintaDesabilitada),
      labelStyle: const TextStyle(color: AppColors.tintaFraca),
      hintStyle: const TextStyle(color: AppColors.tintaFraca),
      errorStyle: const TextStyle(color: AppColors.alerta),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaria,
      foregroundColor: AppColors.superficie,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaria,
        foregroundColor: AppColors.superficie,
        disabledBackgroundColor: AppColors.borda,
        disabledForegroundColor: AppColors.tintaDesabilitada,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medio),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaria,
        disabledForegroundColor: AppColors.tintaDesabilitada,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pequeno),
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.tintaFraca,
        disabledForegroundColor: AppColors.tintaDesabilitada,
      ),
    ),

    // O `SnackBar` inverte o contraste: tinta no fundo, fundo na tinta. E o
    // par mais forte que existe no sistema (14.50), e aviso que aparece por
    // tres segundos precisa ser lido de relance.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.tinta,
      contentTextStyle: const TextStyle(color: AppColors.fundo, fontSize: 15),
      actionTextColor: AppColors.primariaFundo,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.superficie,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.grande),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.bordaForte,
      thickness: 1,
      space: 1,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaria,
    ),
  );

  /// Borda de campo, no raio pequeno do sistema. Existe para os seis estados
  /// de `InputDecorationTheme` nao repetirem a mesma construcao.
  static OutlineInputBorder _bordaCampo(Color cor, {double espessura = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pequeno),
      borderSide: BorderSide(color: cor, width: espessura),
    );
  }

  /// `ColorScheme` escrito a mao, e nao `ColorScheme.fromSeed`.
  ///
  /// `fromSeed` derivaria as trinta e tantas cores de uma unica semente,
  /// pelo algoritmo tonal do Material 3, e no caminho descartaria a paleta
  /// escolhida a mao — inclusive as tres correcoes de contraste que o
  /// documento registra na secao 7. Os pares aqui foram **medidos**; os
  /// derivados nao teriam sido.
  ///
  /// O custo e manutencao: acrescentar uma cor de papel exige decidir em que
  /// slot ela entra, ou se ela fica fora do esquema, em `AppColors`.
  static const ColorScheme _esquemaClaro = ColorScheme(
    brightness: Brightness.light,

    // Acao principal. Tambem carrega o periodo da manha nas telas da agenda.
    primary: AppColors.primaria,
    onPrimary: AppColors.superficie,
    primaryContainer: AppColors.primariaFundo,
    onPrimaryContainer: AppColors.primaria,

    // `secondary` e `tertiary` espelham a primaria de proposito. As outras
    // duas cores de papel do sistema — `tarde` e `sucesso` — significam
    // periodo do dia e servico feito, e nao nivel de hierarquia: ficam fora
    // do esquema, em `AppColors`, como manda a secao 6 do documento. Um
    // widget que peca `tertiary` por acidente recebe a paleta principal em
    // vez de um verde que mentiria sobre o estado do atendimento.
    secondary: AppColors.primaria,
    onSecondary: AppColors.superficie,
    secondaryContainer: AppColors.primariaFundo,
    onSecondaryContainer: AppColors.primaria,
    tertiary: AppColors.primaria,
    onTertiary: AppColors.superficie,
    tertiaryContainer: AppColors.primariaFundo,
    onTertiaryContainer: AppColors.primaria,

    // Erro e conflito de horario (RF-012).
    error: AppColors.alerta,
    onError: AppColors.superficie,
    errorContainer: AppColors.alertaFundo,
    onErrorContainer: AppColors.alerta,

    surface: AppColors.superficie,
    onSurface: AppColors.tinta,
    onSurfaceVariant: AppColors.tintaFraca,
    surfaceDim: AppColors.fundo,
    surfaceBright: AppColors.superficie,

    // O documento define tres superficies; o Material 3 quer cinco degraus de
    // conteiner. Os dois ultimos repetem o degrau mais escuro que existe em
    // vez de inventar um cinza intermediario que ninguem mediu.
    surfaceContainerLowest: AppColors.superficie,
    surfaceContainerLow: AppColors.superficieAlt,
    surfaceContainer: AppColors.fundo,
    surfaceContainerHigh: AppColors.fundo,
    surfaceContainerHighest: AppColors.fundo,

    outline: AppColors.bordaForte,
    outlineVariant: AppColors.borda,

    // Usado pelo `SnackBar` e pelos widgets que invertem o contraste.
    inverseSurface: AppColors.tinta,
    onInverseSurface: AppColors.fundo,
    inversePrimary: AppColors.primariaFundo,

    // No Material 3 o `surfaceTint` tinge cartao elevado com a primaria. Toda
    // a paleta foi medida contra branco e contra o `fundo`; com o tint ligado,
    // qualquer cartao com elevacao passaria a ter um branco azulado que nao
    // foi medido. Desligado, a elevacao se faz por sombra e borda.
    surfaceTint: Colors.transparent,

    // Sombra e veu de modal sao do Material, nao tokens deste sistema — dai o
    // `Colors.*`, que as telas continuam proibidas de usar.
    shadow: Colors.black,
    scrim: Colors.black,
  );
}
