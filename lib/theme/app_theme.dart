import 'package:flutter/material.dart';

import 'app_colors.dart';
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
  );

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
