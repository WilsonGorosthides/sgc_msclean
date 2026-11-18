import 'package:flutter/material.dart';

import '../models/peca.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/agenda.dart';
import '../utils/calculo.dart';

// Rodapé fixo do seletor de peças (RF-013, issue #134): o total em destaque,
// a lista detalhada (serviço, legenda e valor), os avisos de sem valor e
// falta de medida, e o botão de salvar largo. Reutilizável pelo orçamento.
//
// O valor a cobrar é o calculado, salvo quando ela muda (desconto, combinado
// diferente): aí o calculado fica à vista com "Usar o calculado" (CT-091).
class RodapeDoTotal extends StatefulWidget {
  const RodapeDoTotal({
    super.key,
    required this.pecas,
    required this.valorManual,
    required this.aoMudarValor,
    required this.aoSalvar,
    required this.rotuloSalvar,
  });

  final List<Peca> pecas;
  // Valor que ela informou; nulo = segue o calculado.
  final double? valorManual;
  // Nulo = voltar ao calculado.
  final ValueChanged<double?> aoMudarValor;
  // Nulo = salvando (botão desabilitado).
  final VoidCallback? aoSalvar;
  final String rotuloSalvar;

  // O que vai ser gravado: o informado, ou o calculado se algum serviço
  // tem valor; senão, sem valor.
  static double? valorACobrar(List<Peca> pecas, double? manual) {
    if (manual != null) return manual;
    final calculo = calcularValor(pecas);
    return calculo.temValor ? calculo.total : null;
  }

  @override
  State<RodapeDoTotal> createState() => _RodapeDoTotalState();
}

class _RodapeDoTotalState extends State<RodapeDoTotal> {
  bool _detalhes = false;

  Future<void> _mudarValor(double? atual) async {
    final texto = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoDoValor(atual: atual),
    );
    if (texto != null) widget.aoMudarValor(lerValor(texto));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final calculo = calcularValor(widget.pecas);
    final linhas = linhasDoTotal(widget.pecas);
    final aCobrar =
        RodapeDoTotal.valorACobrar(widget.pecas, widget.valorManual);
    final manualDiferente = widget.valorManual != null &&
        calculo.temValor &&
        widget.valorManual != calculo.total;
    final aviso = textos.bodySmall?.copyWith(color: AppColors.tarde);

    return Material(
      color: AppColors.superficie,
      elevation: 8,
      shadowColor: AppColors.tinta,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_detalhes && linhas.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var k = 0; k < linhas.length; k++)
                        _linha(context, k, linhas[k]),
                      const Divider(),
                    ],
                  ),
                ),
              if (calculo.semValor.isNotEmpty)
                Text('Sem valor na tabela: ${calculo.semValor.join(', ')}',
                    key: const Key('aviso_sem_valor'), style: aviso),
              if (calculo.semMedida.isNotEmpty)
                Text('Falta medida: ${calculo.semMedida.join(', ')}',
                    key: const Key('aviso_sem_medida'), style: aviso),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Total',
                                style: textos.labelLarge
                                    ?.copyWith(color: AppColors.tintaFraca)),
                            if (linhas.isNotEmpty)
                              TextButton.icon(
                                key: const Key('ver_detalhes'),
                                onPressed: () =>
                                    setState(() => _detalhes = !_detalhes),
                                icon: Icon(_detalhes
                                    ? Icons.expand_more
                                    : Icons.expand_less),
                                label: Text(
                                    '${linhas.length} ${linhas.length == 1 ? 'serviço' : 'serviços'}'),
                              ),
                          ],
                        ),
                        Text(
                          aCobrar == null ? 'sem valor' : valorEmReais(aCobrar),
                          key: const Key('total_a_cobrar'),
                          style: textos.headlineSmall?.copyWith(
                              color: aCobrar == null
                                  ? AppColors.tintaFraca
                                  : AppColors.tinta,
                              fontFeatures: AppTypography.digitosTabulares),
                        ),
                        if (manualDiferente)
                          Text(
                            'calculado ${valorEmReais(calculo.total)}',
                            key: const Key('total_calculado'),
                            style: textos.bodySmall
                                ?.copyWith(color: AppColors.tintaFraca),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (manualDiferente)
                        TextButton(
                          key: const Key('usar_calculado'),
                          onPressed: () => widget.aoMudarValor(null),
                          child: const Text('Usar o calculado'),
                        ),
                      TextButton.icon(
                        key: const Key('mudar_valor'),
                        onPressed: () => _mudarValor(aCobrar),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Mudar valor'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                key: const Key('botao_salvar'),
                onPressed: widget.aoSalvar,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.xxl * 1.75)),
                icon: const Icon(Icons.check),
                label: Text(widget.rotuloSalvar),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, int k, LinhaDoTotal linha) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(linha.servico,
                    key: Key('linha_total_${k}_servico'),
                    style: textos.bodyLarge),
                Text(linha.legenda,
                    key: Key('linha_total_${k}_legenda'),
                    style: textos.bodySmall?.copyWith(
                        color: linha.valor == null
                            ? AppColors.tarde
                            : AppColors.tintaFraca)),
              ],
            ),
          ),
          Text(
            linha.valor == null ? '—' : valorEmReais(linha.valor!),
            key: Key('linha_total_${k}_valor'),
            style: textos.titleSmall
                ?.copyWith(fontFeatures: AppTypography.digitosTabulares),
          ),
        ],
      ),
    );
  }
}

// Diálogo do valor a cobrar: dono do próprio campo (o controle vive enquanto
// o diálogo existir, inclusive na animação de fechar). Devolve o texto
// digitado, ou nada se cancelado.
class _DialogoDoValor extends StatefulWidget {
  const _DialogoDoValor({required this.atual});

  final double? atual;

  @override
  State<_DialogoDoValor> createState() => _DialogoDoValorState();
}

class _DialogoDoValorState extends State<_DialogoDoValor> {
  late final _controle = TextEditingController(
      text: widget.atual == null ? '' : valorEmReais(widget.atual!).substring(3));

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Valor a cobrar'),
      content: TextFormField(
        key: const Key('campo_valor'),
        controller: _controle,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(fontFeatures: AppTypography.digitosTabulares),
        decoration: const InputDecoration(
          prefixText: 'R\$ ',
          helperText: 'Vazio volta ao calculado pela tabela',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar_valor'),
          onPressed: () => Navigator.of(context).pop(_controle.text),
          child: const Text('Usar este valor'),
        ),
      ],
    );
  }
}
