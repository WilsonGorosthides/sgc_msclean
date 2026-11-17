// Texto comparável na busca (RF-004, #113): minúsculas e sem acento, para
// "joao" achar "João". Só as letras do português (e o ñ); o resto passa igual.
const _comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _semAcento = 'aaaaaeeeeiiiiooooouuuucn';

String paraBusca(String texto) {
  final minusculo = texto.toLowerCase();
  final saida = StringBuffer();
  for (final letra in minusculo.split('')) {
    final i = _comAcento.indexOf(letra);
    saida.write(i < 0 ? letra : _semAcento[i]);
  }
  return saida.toString();
}
