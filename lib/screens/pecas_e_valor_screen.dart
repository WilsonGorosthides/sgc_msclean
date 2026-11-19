import 'package:flutter/material.dart';

import '../models/item_de_preco.dart';
import '../models/peca.dart';
import '../theme/app_spacing.dart';
import '../widgets/rodape_do_total.dart';
import '../widgets/seletor_de_pecas.dart';

// O que a tela Peças e valor devolve: as peças com os serviços e o valor que
// ela informou (nulo = segue o calculado).
class PecasEValor {
  const PecasEValor(this.pecas, this.valorManual);

  final List<Peca> pecas;
  final double? valorManual;
}

// Peças e valor (RF-005/RF-013, issue #134): o seletor de peças com o rodapé
// do total, numa tela própria. O atendimento abre por uma linha de resumo,
// para anotar na agenda continuar rápido. Voltar por "Pronto" ou pela seta
// leva o que foi marcado.
class PecasEValorScreen extends StatefulWidget {
  const PecasEValorScreen({
    super.key,
    required this.pecas,
    required this.tabela,
    this.valorManual,
  });

  final List<Peca> pecas;
  final List<ItemDePreco> tabela;
  final double? valorManual;

  @override
  State<PecasEValorScreen> createState() => _PecasEValorScreenState();
}

class _PecasEValorScreenState extends State<PecasEValorScreen> {
  late List<Peca> _pecas = widget.pecas;
  late double? _valorManual = widget.valorManual;

  PecasEValor get _resultado => PecasEValor(_pecas, _valorManual);

  @override
  Widget build(BuildContext context) {
    return PopScope<PecasEValor>(
      // a seta (ou o voltar do sistema) também leva o que foi marcado
      canPop: false,
      onPopInvokedWithResult: (saiu, _) {
        if (!saiu) Navigator.of(context).pop(_resultado);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Peças e valor')),
        bottomNavigationBar: RodapeDoTotal(
          pecas: _pecas,
          valorManual: _valorManual,
          aoMudarValor: (v) => setState(() => _valorManual = v),
          aoSalvar: () => Navigator.of(context).pop(_resultado),
          rotuloSalvar: 'Pronto',
          chaveSalvar: 'pecas_pronto',
          iconeSalvar: Icons.done,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SeletorDePecas(
              pecas: widget.pecas,
              tabela: widget.tabela,
              aoMudar: (pecas) => setState(() => _pecas = pecas),
              // registro sem peças: o deslocamento já vem (CT-098)
              incluirDeslocamento: widget.pecas.isEmpty,
            ),
          ],
        ),
      ),
    );
  }
}
