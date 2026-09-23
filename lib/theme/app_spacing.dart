/// Escala de espacamento, conforme `docs/design-system.md` secao 4.
///
/// Escala de 4, seis degraus, e nada fora deles. O prototipo usava onze
/// valores escolhidos a olho: funcionou numa pagina, nao sobreviveria a sete
/// telas.
abstract final class AppSpacing {
  /// Separacao dentro de um mesmo elemento.
  static const double xs = 4;

  /// Entre itens irmaos de uma lista.
  static const double sm = 8;

  /// Padding interno de cartao pequeno.
  static const double md = 12;

  /// Padding de tela, padding de cartao.
  static const double lg = 16;

  /// Entre blocos distintos.
  static const double xl = 24;

  /// Respiro de secao.
  static const double xxl = 32;
}

/// Escala de raio, conforme `docs/design-system.md` secao 5.
///
/// Tres degraus, e nada fora deles. O prototipo usava oito.
///
/// Mora neste arquivo, e nao num `app_radius.dart`, porque tres constantes
/// nao sustentam um arquivo proprio: raio e espacamento sao a mesma familia
/// de decisao de forma.
abstract final class AppRadius {
  /// Selos, chips, campos.
  static const double pequeno = 8;

  /// Cartoes, botoes, folhas.
  static const double medio = 14;

  /// Conteineres de destaque.
  static const double grande = 22;
}
