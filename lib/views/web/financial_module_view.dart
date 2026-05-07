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
                  const Text('VALOR TOTAL PARA PAGAMENTO (HOJE)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 10),
                  Text(currencyFormat.format(db.currentLiquidity), style: const TextStyle(color: AppColors.neonCyan, fontSize: 36, fontWeight: FontWeight.w900))
                ]
              ),
              ElevatedButton.icon(
                onPressed: () {}, 
                icon: const Icon(Icons.download, color: Colors.black), 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.successEmerald, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                label: const Text('XLS PAGAMENTO DO DIA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900))
              )
            ]
          )
        ),
        const SizedBox(height: 25),
        const Text('HISTÓRICO DE LOTES', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Expanded(
          child: batches.isEmpty 
          ? const Center(child: Text('Nenhum lote financeiro processado.', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              itemCount: batches.length,
              itemBuilder: (context, i) {
                final b = batches[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(b.batchName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(currencyFormat.format(b.totalValue), style: const TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.bold)),
                      Icon(b.isPaid ? Icons.check_circle : Icons.pending, color: b.isPaid ? AppColors.successEmerald : AppColors.alertOrange, size: 16),
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
