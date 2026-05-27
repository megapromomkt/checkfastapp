import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class TaskTimelineView extends StatelessWidget {
  final String storeName;
  final String status;
  
  const TaskTimelineView({
    super.key, 
    required this.storeName, 
    required this.status
  });

  @override
  Widget build(BuildContext context) {
    // Regra: Só está apto se cumpriu todos os requisitos (Simulação baseada no status Concluída)
    bool isApto = status == 'Concluída';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18)
        ),
        title: const Text('Cronologia do Dia', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Cronologia
            _buildTimelineHeader(),
            const SizedBox(height: 40),

            // Linha do Tempo
            const Text('LINHA DO TEMPO DA EXECUÇÃO', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 32),
            
            _buildTimelineStep(
              step: 1,
              title: 'CHECK-IN',
              time: '08:02',
              desc: 'Localização validada com sucesso',
              isValid: true,
            ),
            
            _buildTimelineStep(
              step: 2,
              title: 'PERMANÊNCIA EM LOJA',
              time: '06h 12m',
              desc: 'Tempo total cumprido: 100%',
              isValid: true,
              isDuration: true,
            ),
            
            _buildTimelineStep(
              step: 3,
              title: 'CHECKOUT',
              time: '14:14',
              desc: 'Localização validada com sucesso',
              isValid: true,
              isLast: true,
            ),

            const SizedBox(height: 40),

            // Card de Status de Pagamento
            _buildPaymentStatusCard(isApto),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(storeName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Projeto: Reposição Verão | Promotor', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: AppColors.cardBorder, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderInfo('DATA', '27/04/2026'),
              _buildHeaderInfo('VALOR DIÁRIA', 'R\$ 150,00', valueColor: AppColors.success),
              _buildHeaderInfo('MÍN. HORAS', '04:00'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTimelineStep({
    required int step, 
    required String title, 
    required String time, 
    required String desc, 
    required bool isValid,
    bool isDuration = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador Visual (Bolinha e Linha)
        Column(
          children: [
            Container(
              width: 28, 
              height: 28, 
              decoration: BoxDecoration(
                color: isValid ? AppColors.primaryBlue : AppColors.background, 
                shape: BoxShape.circle,
                border: Border.all(color: isValid ? AppColors.primaryBlue : AppColors.cardBorder, width: 2)
              ),
              child: Center(child: Text(step.toString(), style: TextStyle(color: isValid ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w900))),
            ),
            if (!isLast) Container(width: 2, height: 100, color: AppColors.cardBorder),
          ],
        ),
        const SizedBox(width: 20),
        // Conteúdo do Passo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                  Text(time, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              if (!isDuration) 
                Container(
                  width: 64, 
                  height: 64, 
                  decoration: BoxDecoration(
                    color: AppColors.background, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: AppColors.cardBorder)
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary.withOpacity(0.3), size: 24),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard(bool isApto) {
    Color statusColor = isApto ? AppColors.success : AppColors.error;
    return PremiumCard(
      borderColor: statusColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isApto ? Icons.check_circle_rounded : Icons.error_rounded, color: statusColor, size: 24),
              const SizedBox(width: 16),
              Text(
                isApto ? 'APTO PARA PAGAMENTO' : 'NÃO APTO PARA PAGAMENTO', 
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isApto) ...[
            _buildRequirement('04 Horas cumpridas', true),
            _buildRequirement('Check-in realizado', true),
            _buildRequirement('Checkout realizado', true),
            _buildRequirement('Fotos enviadas', true),
            _buildRequirement('Localização validada', true),
          ] else ...[
            const Text('Motivo: Presença em Análise / Irregularidade detectada', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildRequirement('Menos de 4 horas em loja', false),
            _buildRequirement('Checkout não realizado', false),
            _buildRequirement('Localização inválida', false),
          ],
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: (met ? AppColors.success : AppColors.error).withOpacity(0.1),
              shape: BoxShape.circle
            ),
            child: Icon(met ? Icons.check_rounded : Icons.close_rounded, color: met ? AppColors.success : AppColors.error, size: 12),
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: met ? AppColors.textPrimary : AppColors.error.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
