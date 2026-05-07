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
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)
        ),
        title: const Text('Cronologia do Dia', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Cronologia
            _buildTimelineHeader(),
            const SizedBox(height: 35),

            // Linha do Tempo
            const Text('LINHA DO TEMPO DA EXECUÇÃO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 25),
            
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

            const SizedBox(height: 20),

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
          Text(storeName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const Text('Projeto: Reposição Verão | Promotor', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderInfo('DATA', '27/04/2026'),
              _buildHeaderInfo('VALOR DIÁRIA', 'R\$ 150,00', valueColor: AppColors.successEmerald),
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
              width: 24, 
              height: 24, 
              decoration: BoxDecoration(
                color: isValid ? AppColors.neonCyan : Colors.white10, 
                shape: BoxShape.circle
              ),
              child: Center(child: Text(step.toString(), style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
            ),
            if (!isLast) Container(width: 2, height: 80, color: Colors.white10),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                  Text(time, style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              const SizedBox(height: 12),
              if (!isDuration) 
                Container(
                  width: 60, 
                  height: 60, 
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03), 
                    borderRadius: BorderRadius.circular(8), 
                    border: Border.all(color: Colors.white10)
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white24, size: 20),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusCard(bool isApto) {
    Color cardColor = isApto ? AppColors.successEmerald : Colors.redAccent;
    return PremiumCard(
      borderColor: cardColor.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isApto ? Icons.check_circle : Icons.error_outline, color: cardColor, size: 22),
              const SizedBox(width: 15),
              Text(
                isApto ? 'APTO PARA PAGAMENTO' : 'NÃO APTO PARA PAGAMENTO', 
                style: TextStyle(color: cardColor, fontWeight: FontWeight.w900, fontSize: 14)
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isApto) ...[
            _buildRequirement('04 Horas cumpridas', true),
            _buildRequirement('Check-in realizado', true),
            _buildRequirement('Checkout realizado', true),
            _buildRequirement('Fotos enviadas', true),
            _buildRequirement('Localização validada', true),
          ] else ...[
            const Text('Motivo: Presença em Análise / Irregularidade detectada', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(met ? Icons.check : Icons.close, color: met ? AppColors.successEmerald : Colors.redAccent, size: 14),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: met ? Colors.white70 : Colors.redAccent.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}
