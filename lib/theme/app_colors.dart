import 'package:flutter/material.dart';

/// Paleta canonica do app, conforme `docs/design-system.md` secao 2.
///
/// Os contrastes anotados foram medidos par a par contra o criterio WCAG 2.1
/// nivel AA para texto normal (minimo 4.5:1). O numero vive aqui, junto do
/// valor, para nao depender de alguem abrir o markdown para saber se um par
/// e legivel.
///
/// Nenhuma tela deve declarar `Color(0x...)` nem usar `Colors.*`. Cor que nao
/// existe aqui se acrescenta aqui e no documento — nao se improvisa na tela.
abstract final class AppColors {
  // --- Superficies e texto (design-system.md 2.1) ---

  /// Fundo da aplicacao.
  static const Color fundo = Color(0xFFF2F4F4);

  /// Cartoes, folhas, campos.
  static const Color superficie = Color(0xFFFFFFFF);

  /// Cabecalho, linha de total, faixas.
  static const Color superficieAlt = Color(0xFFFAFBFB);

  /// Texto principal. Contraste 14.50 sobre [fundo], 16.01 sobre [superficie].
  static const Color tinta = Color(0xFF12242A);

  /// Texto secundario, legendas. Contraste 4.65 sobre [fundo],
  /// 5.14 sobre [superficie].
  static const Color tintaFraca = Color(0xFF5C7178);

  /// Contraste 2.97 — reprova em AA. **So** para controle desabilitado, que a
  /// WCAG 2.1 isenta do criterio de contraste (1.4.3), e para ornamento sem
  /// conteudo. Texto que precisa ser lido usa [tinta] ou [tintaFraca];
  /// o terceiro nivel de hierarquia se faz por tamanho e peso, nao por cor.
  static const Color tintaDesabilitada = Color(0xFF8699A0);

  /// Borda padrao.
  static const Color borda = Color(0xFFDCE3E4);

  /// Borda enfatizada, divisor.
  static const Color bordaForte = Color(0xFFC3CFD1);

  // --- Cores de papel (design-system.md 2.2 e 2.3) ---
  //
  // A cor carrega informacao, nao decoracao. Manha e tarde ganharem
  // temperaturas opostas e a unica pista visual que separa os dois blocos do
  // dia quando a tela e olhada de relance.

  /// Acao principal e periodo da **manha**.
  /// Contraste 5.91 sobre branco, 5.06 sobre [primariaFundo].
  static const Color primaria = Color(0xFF0B6E7F);
  static const Color primariaFundo = Color(0xFFE2F0F2);

  /// Periodo da **tarde**. Fora do `ColorScheme` por ser papel de dominio.
  /// Contraste 5.25 sobre branco, 4.54 sobre [tardeFundo].
  static const Color tarde = Color(0xFF9E5C17);
  static const Color tardeFundo = Color(0xFFF7EDDF);

  /// Servico feito, cliente pagou (RF-014). Fora do `ColorScheme`, idem.
  /// Contraste 5.27 sobre branco, 4.52 sobre [sucessoFundo].
  static const Color sucesso = Color(0xFF2D7958);
  static const Color sucessoFundo = Color(0xFFE3F1EA);

  /// Erro e conflito de horario (RF-012).
  /// Contraste 5.51 sobre branco, 4.60 sobre [alertaFundo].
  static const Color alerta = Color(0xFFB3452F);
  static const Color alertaFundo = Color(0xFFF8E7E3);
}
