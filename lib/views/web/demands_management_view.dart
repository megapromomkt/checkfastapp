import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../models/app_models.dart';
import 'widgets/create_demand_modal.dart';

class DemandsManagementView extends StatefulWidget {
  const DemandsManagementView({super.key});

  @override
  State<DemandsManagementView> createState() => _DemandsManagementViewState();
}

class _DemandsManagementViewState extends State<DemandsManagementView> {
  @override
  Widget build(BuildContext context) {
    final db = TestDatabase.instance;
    final demands = db.demands;

    int countRascunho = demands.where((d) => d.status == 'RASCUNHO').length;
    int countAbertas = demands.where((d) => d.status == 'ABERTAS').length;
    int countPreenchidas = demands.where((d) => d.status == 'PREENCHIDAS').length;
    int countAndamento = demands.where((d) => d.status == 'EM ANDAMENTO').length;
    int countFinalizadas = demands.where((d) => d.status == 'FINALIZADAS').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        PremiumHeader(
          title: 'Gestão de Demandas', 
          subtitle: 'Painel operacional de acompanhamento de vagas.',
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                final res = await showDialog(
                  context: context, 
                  builder: (context) => const Center(child: CreateDemandModal()),
                );
                if (res == true) setState(() {});
              },
              icon: const Icon(IconsaxPlusLinear.add, color: Colors.black, size: 20),
              label: const Text('NOVA DEMANDA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20)),
            )
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKanbanColumn('RASCUNHO', countRascunho, AppColors.textSecondary, demands.where((d) => d.status == 'RASCUNHO').toList()),
                const SizedBox(width: 20),
                _buildKanbanColumn('ABERTAS', countAbertas, AppColors.alertOrange, demands.where((d) => d.status == 'ABERTAS').toList()),
                const SizedBox(width: 20),
                _buildKanbanColumn('PREENCHIDAS', countPreenchidas, AppColors.electricBlue, demands.where((d) => d.status == 'PREENCHIDAS').toList()),
                const SizedBox(width: 20),
                _buildKanbanColumn('EM ANDAMENTO', countAndamento, AppColors.neonCyan, demands.where((d) => d.status == 'EM ANDAMENTO').toList()),
                const SizedBox(width: 20),
                _buildKanbanColumn('FINALIZADAS', countFinalizadas, AppColors.successEmerald, demands.where((d) => d.status == 'FINALIZADAS').toList()),
              ],
            ),
          ),
        ),
      ]
    );
  }

  Widget _buildKanbanColumn(String title, int count, Color color, List<AppDemand> colDemands) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(15),
          border: Border(top: BorderSide(color: color, width: 4))
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(count.toString(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Expanded(
              child: colDemands.isEmpty 
              ? Center(child: Text('Nenhuma demanda\npara esta etapa.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 11)))
              : ListView.builder(
                  itemCount: colDemands.length,
                  itemBuilder: (context, i) => _buildKanbanCard(colDemands[i]),
                ),
            ),
          ],
        ),
      );
  }

  Widget _buildKanbanCard(AppDemand demand) {
    double progress = demand.totalVagas > 0 ? demand.filledVagas / demand.totalVagas : 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(demand.storeName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
              if (demand.priority == 'Alta')
                const Icon(IconsaxPlusBold.info_circle, color: Colors.redAccent, size: 14),
            ],
          ),
          const SizedBox(height: 5),
          Text('${demand.clientName ?? 'S/C'} | ${demand.projectName ?? 'S/P'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.profile, color: AppColors.textSecondary, size: 12),
              const SizedBox(width: 5),
              Text(demand.role, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              const Spacer(),
              Text('${demand.filledVagas}/${demand.totalVagas}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(progress == 1 ? AppColors.successEmerald : AppColors.neonCyan),
              minHeight: 4,
            ),
          ),
          if (demand.assignedPromoter != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(radius: 8, backgroundColor: AppColors.electricBlue, child: Text('?', style: TextStyle(fontSize: 6, color: Colors.white))),
                const SizedBox(width: 5),
                Text(demand.assignedPromoter!, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            )
          ]
        ],
      ),
    );
  }
}
