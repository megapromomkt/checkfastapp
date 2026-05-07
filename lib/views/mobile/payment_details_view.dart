import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class PaymentDetailsView extends StatelessWidget {
  final String storeName;
  final String status;
  final String value;
  final String date;
  
  const PaymentDetailsView({
    super.key, 
    required this.storeName, 
    required this.status, 
    required this.value, 
    required this.date
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)
        )
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumHeader(title: 'Detalhe do Recebimento', subtitle: 'Informações detalhadas sobre a liquidação da diária.'),
            const SizedBox(height: 35),

            // Dossiê Financeiro
            PremiumCard(
              child: Column(
                children: [
                  _buildFinanceRow('Loja Atendida', storeName),
                  _buildFinanceRow('Data Executada', date),
                  _buildFinanceRow('Função no Projeto', 'Promotor de Vendas'),
                  _buildFinanceRow('Horário Check-in', '08:02'),
                  _buildFinanceRow('Horário Checkout', '14:14'),
                  _buildFinanceRow('Tempo em Loja', '06h 12m'),
                  const Divider(color: Colors.white10, height: 35),
                  _buildFinanceRow('Valor da Diária', 'R\$ 150,00'),
                  _buildFinanceRow('Valor Líquido Aprovado', value, valueColor: AppColors.successEmerald),
                  _buildFinanceRow('Status Financeiro', status, valueColor: _getStatusColor(status)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Alerta de Irregularidade (Se houver)
            if (status == 'Não Apto' || status == 'Reprovado')
              PremiumCard(
                borderColor: Colors.redAccent.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                        SizedBox(width: 10),
                        Text('MOTIVO DA REPROVAÇÃO', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'A jornada mínima de 4 horas obrigatória por contrato não foi identificada no sistema de auditoria do CheckFast.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
            
            // Rodapé de Suporte
            Center(
              child: TextButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.help_outline, color: AppColors.neonCyan, size: 18), 
                label: const Text('Contestar este recebimento', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 13))
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pago': return AppColors.successEmerald;
      case 'Aprovado': return AppColors.electricBlue;
      case 'Em análise': return AppColors.alertOrange;
      default: return Colors.redAccent;
    }
  }
}
