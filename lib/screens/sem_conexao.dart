import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// Peças de tela do anotar sem internet (RNF-007, #94), usadas pela agenda e
// pela lista de clientes. A cor é a da tarde (âmbar): chama atenção sem soar
// como erro — sem conexão o app continua funcionando.

// Aviso de item que ainda está só no aparelho: editar, excluir ou marcar
// feito/pago esperam o envio, para o aparelho e o banco não divergirem.
const avisoItemPendente =
    'Ainda aguardando envio: dá para mudar depois que for enviado.';

// Faixa discreta no topo da tela enquanto o banco não responde.
class AvisoSemConexao extends StatelessWidget {
  const AvisoSemConexao({super.key, required this.conectado});

  final ValueListenable<bool> conectado;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: conectado,
      builder: (context, online, _) {
        if (online) return const SizedBox.shrink();
        return Container(
          key: const Key('aviso_sem_conexao'),
          width: double.infinity,
          color: AppColors.tardeFundo,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: AppSpacing.lg,
                  color: AppColors.tarde),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sem conexão — o que anotar fica no aparelho e é enviado '
                  'quando a internet voltar.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.tarde),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Selo "aguardando envio" no cartão do atendimento e no item do cliente.
class SeloAguardandoEnvio extends StatelessWidget {
  const SeloAguardandoEnvio({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.tardeFundo,
        borderRadius: BorderRadius.circular(AppRadius.pequeno),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_outlined,
              size: AppSpacing.md, color: AppColors.tarde),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'aguardando envio',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.tarde),
          ),
        ],
      ),
    );
  }
}
