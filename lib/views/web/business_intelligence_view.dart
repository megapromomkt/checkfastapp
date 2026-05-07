import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import 'store_import_view.dart';
import 'worker_details_view.dart';
import 'support_dashboard_view.dart';
import 'financial_module_view.dart';
import 'clients_management_view.dart';
import 'demands_management_view.dart';
import 'presence_control_view.dart';

class BusinessIntelligenceView extends StatefulWidget {
  const BusinessIntelligenceView({super.key});

  @override
  State<BusinessIntelligenceView> createState() => _BusinessIntelligenceViewState();
}

class _BusinessIntelligenceViewState extends State<BusinessIntelligenceView> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BIContent(),
    const WorkerDetailsView(),
    const StoreImportView(),
    const ClientsManagementView(),
    const DemandsManagementView(),
    const TrainingModule(),
    const PresenceControlView(),
    const FinancialModuleView(),
    const ReportModule(),
    const GenericModule(title: 'Configurações'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.cardDark, 
        border: Border(right: BorderSide(color: AppColors.glassBorderDark))
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildLogo(),
          const SizedBox(height: 30),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(0, Icons.analytics_outlined, 'Dashboard'),
                _buildMenuItem(1, Icons.people_outline, 'Colaboradores'),
                _buildMenuItem(2, Icons.storefront_outlined, 'Lojas'),
                _buildMenuItem(3, Icons.business_outlined, 'Clientes'),
                _buildMenuItem(4, Icons.assignment_outlined, 'Demandas'),
                _buildMenuItem(5, Icons.model_training_outlined, 'Treinamento'),
                _buildMenuItem(6, Icons.how_to_reg_outlined, 'Presença'),
                _buildMenuItem(7, Icons.payments_outlined, 'Financeiro'),
                _buildMenuItem(8, Icons.description_outlined, 'Relatórios'),
                _buildMenuItem(9, Icons.settings_outlined, 'Configurações'),
              ],
            ),
          ),
          _buildProfile(),
        ],
      ),
    );
  }

  Widget _buildLogo() => Row(
    mainAxisAlignment: MainAxisAlignment.center, 
    children: [
      const Icon(Icons.verified_user, color: AppColors.neonCyan), 
      const SizedBox(width: 10), 
      const Text('CheckFast', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))
    ]
  );

  Widget _buildMenuItem(int index, IconData icon, String label) {
    bool sel = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: sel ? AppColors.neonCyan : AppColors.textSecondary, size: 20),
      title: Text(label, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13)),
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildProfile() => const Padding(
    padding: EdgeInsets.all(20), 
    child: Row(
      children: [
        CircleAvatar(backgroundColor: AppColors.electricBlue, child: Text('AD')), 
        const SizedBox(width: 12), 
        Text('Admin Master', style: TextStyle(color: Colors.white, fontSize: 14))
      ]
    )
  );
}

class BIContent extends StatelessWidget {
  const BIContent({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40), 
    child: PremiumHeader(title: 'Dashboard Geral', subtitle: 'Visão de velocidade, validação e confiança.')
  );
}

class GenericModule extends StatelessWidget {
  final String title;
  const GenericModule({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40), 
    child: PremiumHeader(title: title, subtitle: 'Módulo em operação.')
  );
}

class TrainingModule extends StatelessWidget {
  const TrainingModule({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40), 
    child: PremiumHeader(title: 'Treinamento (1º Dia)', subtitle: 'Validação obrigatória de presença e fotos para novos ingressos.')
  );
}

class FinancialModule extends StatelessWidget {
  const FinancialModule({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40), 
    child: PremiumHeader(title: 'Financeiro', subtitle: 'Pagamentos automáticos por diária (Regra 4h).')
  );
}

class ReportModule extends StatelessWidget {
  const ReportModule({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(title: 'Relatórios Exportáveis', subtitle: 'Geração de arquivos XLS para Presença e Financeiro.'),
          const SizedBox(height: 40),
          Row(
            children: [
              _buildReportCard('Relatório de Presença', 'Nome, CPF, Loja, Horas e Status.', Icons.how_to_reg),
              const SizedBox(width: 20),
              _buildReportCard('Relatório Financeiro', 'Nome, CPF, PIX, Valor e Status.', Icons.payments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String desc, IconData icon) {
    return Expanded(
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.neonCyan, size: 30),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {}, 
              icon: const Icon(Icons.download, color: Colors.black, size: 18), 
              label: const Text('EXPORTAR XLS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
            ),
          ],
        ),
      ),
    );
  }
}
