import 'dart:async';

import 'package:flutter/material.dart';

import '../models/atendimento.dart';
import '../models/client_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/agenda.dart';
import 'atendimento_form_screen.dart';
import 'home_screen.dart';

// Tela inicial do app (RF-010): a agenda virtual. Mostra o dia selecionado
// agrupado por período, com a semana sempre à vista e o mês a um toque. A
// lista de clientes (RF-003) fica a um toque, na barra do topo.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key, this.service, this.agora});

  // Nos testes injeta-se um service falso; em produção usa o real.
  final SupabaseService? service;

  // Relógio injetável: a agenda nunca lê DateTime.now() direto (CT-029).
  final DateTime Function()? agora;

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late final _service = widget.service ?? SupabaseService();
  late final DateTime Function() _agora = widget.agora ?? DateTime.now;

  // Duas assinaturas únicas, abertas junto da tela: assim o primeiro quadro
  // com dados já traz atendimentos e nomes dos clientes, sem dois carregamentos
  // em sequência.
  StreamSubscription<List<Atendimento>>? _assinaturaAtendimentos;
  StreamSubscription<List<ClientModel>>? _assinaturaClientes;
  List<Atendimento>? _atendimentos;
  List<ClientModel>? _clientes;
  Object? _erro;

  late DateTime _selecionado = soData(_agora());
  late DateTime _mes = somarMeses(_selecionado, 0);
  bool _verMes = false;

  @override
  void initState() {
    super.initState();
    _assinarAtendimentos();
    _assinaturaClientes = _service.getClientsStream().listen(
          (dados) => setState(() => _clientes = dados),
          onError: (Object erro) => setState(() => _erro = erro),
        );
  }

  // (Re)abre a assinatura de atendimentos. Renovada ao voltar do formulário:
  // o projeto Supabase não entrega eventos UPDATE (issue #57), e a edição da
  // hora (RF-005) precisa refletir na agenda sem reiniciar o app.
  void _assinarAtendimentos() {
    _assinaturaAtendimentos?.cancel();
    _assinaturaAtendimentos = _service.getAtendimentosStream().listen(
          (dados) => setState(() {
            _atendimentos = dados;
            _erro = null;
          }),
          onError: (Object erro) => setState(() => _erro = erro),
        );
  }

  // Abre o formulário de atendimento (RF-005): novo, no dia selecionado, ou
  // edição de um cartão. Ao voltar, renova a stream.
  Future<void> _abrirFormulario({Atendimento? atendimento}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AtendimentoFormScreen(
        service: _service,
        data: atendimento?.data ?? _selecionado,
        clientes: _clientes ?? const [],
        atendimento: atendimento,
      ),
    ));
    if (!mounted) return;
    _assinarAtendimentos();
  }

  // Marca/desmarca feito ou pago (RF-014) direto no cartão. A tela muda na
  // hora e a gravação segue em paralelo; se falhar, a marca volta e avisa.
  Future<void> _marcar(Atendimento a, {bool? feito, bool? pago}) async {
    final novo = a.copyWith(feito: feito, pago: pago);
    _trocar(novo);
    try {
      await _service.marcarConclusao(a.id!, feito: feito, pago: pago);
    } catch (_) {
      if (!mounted) return;
      _trocar(a);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível marcar. Tente novamente.')),
      );
    }
  }

  void _trocar(Atendimento para) => setState(() {
        _atendimentos = [
          for (final x in _atendimentos ?? const <Atendimento>[])
            x.id == para.id ? para : x,
        ];
      });

  @override
  void dispose() {
    _assinaturaAtendimentos?.cancel();
    _assinaturaClientes?.cancel();
    super.dispose();
  }

  void _selecionar(DateTime dia) => setState(() {
        _selecionado = dia;
        _verMes = false;
      });

  void _abrirMes() => setState(() {
        _mes = somarMeses(_selecionado, 0);
        _verMes = true;
      });

  void _abrirClientes() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HomeScreen(service: _service),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hoje = soData(_agora());
    final foraDeHoje = _selecionado != hoje ||
        (_verMes && (_mes.year != hoje.year || _mes.month != hoje.month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          if (foraDeHoje)
            IconButton(
              key: const Key('voltar_hoje'),
              icon: const Icon(Icons.today),
              tooltip: 'Voltar para hoje',
              onPressed: () => _selecionar(hoje),
            ),
          IconButton(
            key: Key(_verMes ? 'fechar_mes' : 'abrir_mes'),
            icon: Icon(_verMes ? Icons.view_day_outlined : Icons.calendar_month),
            tooltip: _verMes ? 'Ver o dia' : 'Ver o mês',
            onPressed: _verMes
                ? () => setState(() => _verMes = false)
                : _abrirMes,
          ),
          IconButton(
            key: const Key('abrir_clientes'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Clientes',
            onPressed: _abrirClientes,
          ),
        ],
      ),
      body: _corpo(hoje),
      // NOVO ATENDIMENTO (RF-005): parte do dia selecionado.
      floatingActionButton: _verMes
          ? null
          : FloatingActionButton.extended(
              key: const Key('novo_atendimento'),
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Novo atendimento'),
            ),
    );
  }

  Widget _corpo(DateTime hoje) {
    if (_erro != null) {
      return const Center(child: Text('Não foi possível carregar a agenda.'));
    }
    final atendimentos = _atendimentos;
    final clientes = _clientes;
    if (atendimentos == null || clientes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final contagem = contagemPorDia(atendimentos);

    if (_verMes) {
      return _VisaoMes(
        mes: _mes,
        hoje: hoje,
        selecionado: _selecionado,
        contagem: contagem,
        aoMudarMes: (meses) =>
            setState(() => _mes = somarMeses(_mes, meses)),
        aoEscolher: _selecionar,
      );
    }

    return Column(
      children: [
        _FaixaDaSemana(
          selecionado: _selecionado,
          hoje: hoje,
          contagem: contagem,
          aoMudarSemana: (semanas) => setState(() =>
              _selecionado = diaAoTrocarSemana(_selecionado, semanas, hoje)),
          aoEscolher: _selecionar,
        ),
        Expanded(
          child: _DiaSelecionado(
            dia: _selecionado,
            hoje: hoje,
            atendimentos: atendimentosDoDia(atendimentos, _selecionado),
            clientes: clientes,
            aoTocar: (a) => _abrirFormulario(atendimento: a),
            aoMarcar: _marcar,
          ),
        ),
      ],
    );
  }
}

// Cabeçalho "‹ título ›" compartilhado pela semana e pelo mês.
class _Navegador extends StatelessWidget {
  const _Navegador({
    required this.titulo,
    required this.chaveTitulo,
    required this.chaveAnterior,
    required this.chaveProximo,
    required this.aoAnterior,
    required this.aoProximo,
  });

  final String titulo;
  final String chaveTitulo;
  final String chaveAnterior;
  final String chaveProximo;
  final VoidCallback aoAnterior;
  final VoidCallback aoProximo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          key: Key(chaveAnterior),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Anterior',
          onPressed: aoAnterior,
        ),
        Expanded(
          child: Text(
            titulo,
            key: Key(chaveTitulo),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: Key(chaveProximo),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Próximo',
          onPressed: aoProximo,
        ),
      ],
    );
  }
}

class _FaixaDaSemana extends StatelessWidget {
  const _FaixaDaSemana({
    required this.selecionado,
    required this.hoje,
    required this.contagem,
    required this.aoMudarSemana,
    required this.aoEscolher,
  });

  final DateTime selecionado;
  final DateTime hoje;
  final Map<DateTime, int> contagem;
  final void Function(int semanas) aoMudarSemana;
  final void Function(DateTime dia) aoEscolher;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Navegador(
          titulo: '${nomeMes(selecionado)} de ${selecionado.year}',
          chaveTitulo: 'titulo_semana',
          chaveAnterior: 'semana_anterior',
          chaveProximo: 'semana_proxima',
          aoAnterior: () => aoMudarSemana(-1),
          aoProximo: () => aoMudarSemana(1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (final dia in semanaDe(selecionado))
                Expanded(
                  child: _CelulaDia(
                    prefixo: '',
                    dia: dia,
                    rotulo: abreviaturaDiaSemana(dia),
                    selecionado: dia == selecionado,
                    ehHoje: dia == hoje,
                    quantidade: contagem[dia] ?? 0,
                    aoTocar: () => aoEscolher(dia),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisaoMes extends StatelessWidget {
  const _VisaoMes({
    required this.mes,
    required this.hoje,
    required this.selecionado,
    required this.contagem,
    required this.aoMudarMes,
    required this.aoEscolher,
  });

  final DateTime mes;
  final DateTime hoje;
  final DateTime selecionado;
  final Map<DateTime, int> contagem;
  final void Function(int meses) aoMudarMes;
  final void Function(DateTime dia) aoEscolher;

  @override
  Widget build(BuildContext context) {
    final grade = gradeDoMes(mes);
    final semanas = [
      for (var i = 0; i < grade.length; i += 7) grade.sublist(i, i + 7),
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          _Navegador(
            titulo: '${nomeMes(mes)} de ${mes.year}',
            chaveTitulo: 'titulo_mes',
            chaveAnterior: 'mes_anterior',
            chaveProximo: 'mes_proximo',
            aoAnterior: () => aoMudarMes(-1),
            aoProximo: () => aoMudarMes(1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final dia in semanaDe(mes))
                      Expanded(
                        child: Center(
                          child: Text(
                            abreviaturaDiaSemana(dia),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.tintaFraca),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final semana in semanas)
                  Row(
                    children: [
                      for (final dia in semana)
                        Expanded(
                          child: dia == null
                              ? const SizedBox.shrink()
                              : _CelulaDia(
                                  prefixo: 'mes_',
                                  dia: dia,
                                  selecionado: dia == selecionado,
                                  ehHoje: dia == hoje,
                                  quantidade: contagem[dia] ?? 0,
                                  aoTocar: () => aoEscolher(dia),
                                ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Célula de um dia, na faixa da semana e no calendário do mês. O prefixo
// diferencia as chaves das duas visões ('' na semana, 'mes_' no mês).
class _CelulaDia extends StatelessWidget {
  const _CelulaDia({
    required this.prefixo,
    required this.dia,
    required this.selecionado,
    required this.ehHoje,
    required this.quantidade,
    required this.aoTocar,
    this.rotulo,
  });

  final String prefixo;
  final DateTime dia;
  final String? rotulo;
  final bool selecionado;
  final bool ehHoje;
  final int quantidade;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final chave = chaveDoDia(dia);
    final corTexto = selecionado ? AppColors.superficie : AppColors.tinta;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs / 2),
      child: Material(
        key: Key('${prefixo}dia_$chave'),
        color: selecionado ? AppColors.primaria : AppColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pequeno),
          side: BorderSide(
            color: ehHoje ? AppColors.primaria : AppColors.borda,
            width: ehHoje ? AppSpacing.xs / 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pequeno),
          onTap: aoTocar,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rotulo != null)
                        Text(
                          rotulo!,
                          style: textos.labelSmall?.copyWith(
                            color: selecionado
                                ? AppColors.superficie
                                : AppColors.tintaFraca,
                          ),
                        ),
                      Text(
                        '${dia.day}',
                        style: textos.titleMedium?.copyWith(
                          color: corTexto,
                          fontFeatures: AppTypography.digitosTabulares,
                        ),
                      ),
                      // Altura reservada mesmo sem atendimento, para as
                      // células não mudarem de tamanho conforme a carga.
                      SizedBox(
                        height: AppSpacing.lg,
                        child: quantidade == 0
                            ? null
                            : Text(
                                '$quantidade',
                                key: Key('${prefixo}contagem_$chave'),
                                style: textos.bodySmall?.copyWith(
                                  color: selecionado
                                      ? AppColors.superficie
                                      : AppColors.primaria,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: AppTypography.digitosTabulares,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (ehHoje)
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: Container(
                    key: Key('${prefixo}marca_hoje'),
                    width: AppSpacing.sm - AppSpacing.xs,
                    height: AppSpacing.sm - AppSpacing.xs,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selecionado
                          ? AppColors.superficie
                          : AppColors.primaria,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaSelecionado extends StatelessWidget {
  const _DiaSelecionado({
    required this.dia,
    required this.hoje,
    required this.atendimentos,
    required this.clientes,
    required this.aoTocar,
    required this.aoMarcar,
  });

  final DateTime dia;
  final DateTime hoje;
  final List<Atendimento> atendimentos;
  final List<ClientModel> clientes;
  final void Function(Atendimento) aoTocar;
  final void Function(Atendimento, {bool? feito, bool? pago}) aoMarcar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final nome = nomeDiaSemana(dia);
    final titulo =
        dia == hoje ? 'Hoje' : nome[0].toUpperCase() + nome.substring(1);
    final grupos = agruparPorPeriodo(atendimentos);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl * 3),
      children: [
        Text(titulo, style: textos.titleLarge),
        Text(
          dataPorExtenso(dia),
          key: const Key('data_selecionada'),
          style: textos.bodySmall?.copyWith(color: AppColors.tintaFraca),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (grupos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Center(
              child: Text(
                'Nenhum atendimento neste dia.',
                style: textos.bodyMedium?.copyWith(color: AppColors.tintaFraca),
              ),
            ),
          ),
        for (final entrada in grupos.entries) ...[
          _CabecalhoPeriodo(periodo: entrada.key, total: entrada.value.length),
          for (final a in entrada.value)
            _CartaoAtendimento(
              atendimento: a,
              nomeDoCliente: _nomeDoCliente(a.clienteId),
              aoTocar: () => aoTocar(a),
              aoMarcarFeito: () => aoMarcar(a, feito: !a.feito),
              aoMarcarPago: () => aoMarcar(a, pago: !a.pago),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }

  String _nomeDoCliente(String id) {
    for (final c in clientes) {
      if (c.id == id) return c.nome;
    }
    return 'Cliente não encontrado';
  }
}

// Manhã e tarde têm temperaturas opostas (design-system.md 2.2): é a pista
// visual que separa os dois blocos do dia quando a tela é olhada de relance.
Color _corDoPeriodo(Periodo p) =>
    p == Periodo.manha ? AppColors.primaria : AppColors.tarde;

Color _fundoDoPeriodo(Periodo p) =>
    p == Periodo.manha ? AppColors.primariaFundo : AppColors.tardeFundo;

class _CabecalhoPeriodo extends StatelessWidget {
  const _CabecalhoPeriodo({required this.periodo, required this.total});

  final Periodo periodo;
  final int total;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      key: Key('periodo_${periodo.name}'),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            periodo.rotulo,
            style: textos.titleMedium?.copyWith(color: _corDoPeriodo(periodo)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: _fundoDoPeriodo(periodo),
              borderRadius: BorderRadius.circular(AppRadius.grande),
            ),
            child: Text(
              '$total',
              key: Key('contagem_periodo_${periodo.name}'),
              style: textos.bodySmall?.copyWith(
                color: _corDoPeriodo(periodo),
                fontWeight: FontWeight.w700,
                fontFeatures: AppTypography.digitosTabulares,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _CartaoAtendimento extends StatelessWidget {
  const _CartaoAtendimento({
    required this.atendimento,
    required this.nomeDoCliente,
    required this.aoTocar,
    required this.aoMarcarFeito,
    required this.aoMarcarPago,
  });

  final Atendimento atendimento;
  final String nomeDoCliente;
  final VoidCallback aoTocar;
  final VoidCallback aoMarcarFeito;
  final VoidCallback aoMarcarPago;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final a = atendimento;
    final apoio = textos.bodySmall?.copyWith(color: AppColors.tintaFraca);

    return Card(
      key: Key('atendimento_${a.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      // Concluído (feito e pago) muda o cartão inteiro: é a terceira situação
      // que a agenda distingue (RF-014).
      color: a.concluido ? AppColors.sucessoFundo : null,
      child: InkWell(
        onTap: aoTocar,
        child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: AppSpacing.xs, color: _corDoPeriodo(a.periodo)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          a.hora ?? 'sem hora',
                          style: textos.bodySmall?.copyWith(
                            color: AppColors.tintaFraca,
                            fontWeight: a.hora == null
                                ? FontWeight.w400
                                : FontWeight.w700,
                            fontStyle: a.hora == null
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontFeatures: AppTypography.digitosTabulares,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            nomeDoCliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textos.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (a.local.isNotEmpty) Text(a.local, style: apoio),
                    if (a.pecas.isNotEmpty)
                      Text(a.pecas.map((p) => p.resumo).join(' · '),
                          style: apoio),
                    if (a.valor != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          valorEmReais(a.valor!),
                          style: textos.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTypography.digitosTabulares,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _Marca(
                          chave: 'feito_${a.id}',
                          rotulo: 'Feito',
                          marcada: a.feito,
                          aoTocar: aoMarcarFeito,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _Marca(
                          chave: 'pago_${a.id}',
                          rotulo: 'Pago',
                          marcada: a.pago,
                          aoTocar: aoMarcarPago,
                        ),
                        const Spacer(),
                        if (a.concluido)
                          Text(
                            'Concluído',
                            key: Key('concluido_${a.id}'),
                            style: textos.labelSmall
                                ?.copyWith(color: AppColors.sucesso),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// Marca de conferido do cartão (RF-014): "Feito" e "Pago", independentes. O
// toque não abre o formulário — a marca tem o seu próprio alvo de toque.
class _Marca extends StatelessWidget {
  const _Marca({
    required this.chave,
    required this.rotulo,
    required this.marcada,
    required this.aoTocar,
  });

  final String chave;
  final String rotulo;
  final bool marcada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = marcada ? AppColors.sucesso : AppColors.tintaFraca;
    return Material(
      key: Key(chave),
      color: marcada ? AppColors.sucessoFundo : AppColors.superficie,
      shape: StadiumBorder(
        side: BorderSide(color: marcada ? AppColors.sucesso : AppColors.borda),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                marcada ? Icons.check_circle : Icons.radio_button_unchecked,
                size: AppSpacing.lg + AppSpacing.xs,
                color: cor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                rotulo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
