// Endereço estruturado do cliente (#65). Modela a variedade real da base
// (casa, apartamento com bloco/apto, condomínio com endereço interno) num só
// conjunto de campos opcionais, otimizado para chegar via GPS e entrar na
// unidade certa. Persistido como jsonb na coluna `endereco` da tabela.
//
// Duas funções guiam os campos: **chegar** (logradouro, numero, bairro — o
// que o Google Maps geolocaliza) e **entrar/achar a unidade** (complemento
// absorve bloco/apto/condomínio; referencia ajuda a localizar). Sem campo de
// cidade: a cliente atende só Campo Grande - MS, que entra como âncora fixa
// na consulta ao Maps (reavaliar se a área de atendimento mudar).
class Endereco {
  // Âncora fixa da consulta ao Maps — toda a base é de Campo Grande - MS.
  static const cidadeFixa = 'Campo Grande - MS';

  final String logradouro;
  final String numero;
  final String bairro;
  final String complemento;
  final String referencia;

  const Endereco({
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.complemento = '',
    this.referencia = '',
  });

  factory Endereco.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const Endereco();
    String ler(String chave) => (map[chave] ?? '').toString();
    return Endereco(
      logradouro: ler('logradouro'),
      numero: ler('numero'),
      bairro: ler('bairro'),
      complemento: ler('complemento'),
      referencia: ler('referencia'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'complemento': complemento,
      'referencia': referencia,
    };
  }

  List<String> get _campos =>
      [logradouro, numero, bairro, complemento, referencia];

  // true quando nenhum campo foi preenchido (só espaços conta como vazio):
  // dispara o aviso "sem endereço" no formulário e o placeholder na lista.
  bool get vazio => _campos.every((c) => c.trim().isEmpty);

  // Linha curta para a lista (RF-003): "logradouro, numero - bairro",
  // omitindo as partes ausentes.
  String get resumo {
    final linha = [logradouro, numero]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
    return [
      if (linha.isNotEmpty) linha,
      if (bairro.trim().isNotEmpty) bairro.trim(),
    ].join(' - ');
  }

  // Texto único minúsculo com todos os campos, para o filtro da busca (RF-004).
  String get buscavel => _campos.join(' ').toLowerCase();

  // Consulta para o Google Maps (#66): campos de "chegar" + a cidade fixa como
  // âncora (sem ela, "Rua X, 10, Centro" é ambíguo no país inteiro).
  // Complemento e referência atrapalham a geolocalização e ficam de fora.
  String get consultaMaps {
    final partes = [logradouro, numero, bairro]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '';
    return [...partes, cidadeFixa].join(', ');
  }

  @override
  bool operator ==(Object other) =>
      other is Endereco &&
      other.logradouro == logradouro &&
      other.numero == numero &&
      other.bairro == bairro &&
      other.complemento == complemento &&
      other.referencia == referencia;

  @override
  int get hashCode =>
      Object.hash(logradouro, numero, bairro, complemento, referencia);
}
