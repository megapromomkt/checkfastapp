import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../models/app_models.dart';
import 'package:intl/intl.dart';

class FinancialModuleView extends StatefulWidget {
  const FinancialModuleView({super.key});

  @override
  State<FinancialModuleView> createState() => _FinancialModuleViewState();
}

class _FinancialModuleViewState extends State<FinancialModuleView> {
  @override
  Widget build(BuildContext context) {
    final db = TestDatabase.instance;
    final batches = db.financialBatches;
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        const PremiumHeader(title: 'Módulo Financeiro', subtitle: 'Gestão de liquidez e fechamento de pagamentos.'),
        const SizedBox(height: 30),
        PremiumCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text('VALOR TOTAL PARA PAGAMENTO (HOJE)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)), 
                  const SizedBox(height: 12),
                  Text(currencyFormat.format(db.currentLiquidity), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1))
                ]
              ),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success, 
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ), 
                label: const Text('XLS PAGAMENTO DO DIA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
              )
            ]
          )
        ),
        const SizedBox(height: 40),
        const Text('HISTÓRICO DE LOTES', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 20),
        Expanded(
          child: batches.isEmpty 
          ? const Center(child: Text('Nenhum lote financeiro processado.', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              itemCount: batches.length,
              itemBuilder: (context, i) {
                final b = batches[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.batchName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      Row(
                        children: [
                          Text(currencyFormat.format(b.totalValue), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(width: 24),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: (b.isPaid ? AppColors.success : AppColors.warning).withOpacity(0.1),
                              shape: BoxShape.circle
                            ),
                            child: Icon(
                              b.isPaid ? Icons.check_rounded : Icons.access_time_filled_rounded, 
                              color: b.isPaid ? AppColors.success : AppColors.warning, 
                              size: 18
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ),
      ]
    );
  }
}
