import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import 'financial_module_view.dart';
import 'presence_control_view.dart';
import 'demands_management_view.dart';
import 'registers_management_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedModule = 0;

  final List<Widget> _modules = [
    const Center(child: Text('Dashboard de Liquidez (BI)', style: TextStyle(color: Colors.white, fontSize: 24))),
    const RegistersManagementView(),
    const DemandsManagementView(),
    const PresenceControlView(),
    const FinancialModuleView(),
    const Center(child: Text('Configurações do Sistema', style: TextStyle(color: Colors.white, fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05)))
            ),
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CHECKFAST', style: TextStyle(color: AppColors.neonCyan, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const Text('ADMIN PANEL', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 3)),
                const SizedBox(height: 50),
                _buildMenuItem(0, IconsaxPlusLinear.chart_21, 'Liquidez BI'),
                _buildMenuItem(1, IconsaxPlusLinear.folder_open, 'Cadastros'),
                _buildMenuItem(2, IconsaxPlusLinear.task_square, 'Demandas'),
                _buildMenuItem(3, IconsaxPlusLinear.radar, 'Presença'),
                _buildMenuItem(4, IconsaxPlusLinear.wallet_check, 'Financeiro'),
                _buildMenuItem(5, IconsaxPlusLinear.setting_4, 'Configurações'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(15), 
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)), 
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 15, backgroundColor: AppColors.neonCyan, child: Icon(IconsaxPlusLinear.profile, size: 15, color: Colors.black)), 
                      SizedBox(width: 15), 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Text('Admin Agência', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)), 
                          Text('Master Access', style: TextStyle(color: AppColors.textSecondary, fontSize: 10))
                        ]
                      )
                    ]
                  )
                )
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _modules[_selectedModule]),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // DevTools - Ambientes de Teste
          showDialog(
            context: context, 
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text('Ambiente de Testes (DevTools)', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
              content: const Text('Escolha o que deseja fazer com o banco de dados temporário para validar as telas.', style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    TestDatabase.instance.clearAllData();
                    Navigator.pop(context);
                    setState(() {});
                  }, 
                  child: const Text('Limpar Dados', style: TextStyle(color: Colors.redAccent))
                ),
                ElevatedButton(
                  onPressed: () {
                    TestDatabase.instance.seedTestData();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
                  child: const Text('Injetar Dados de Teste', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          );
        },
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(IconsaxPlusLinear.code, color: Colors.white),
        label: const Text('DevTools', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String label) {
    bool selected = _selectedModule == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => setState(() => _selectedModule = index),
        leading: Icon(icon, color: selected ? AppColors.neonCyan : AppColors.textSecondary, size: 20),
        title: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: selected ? AppColors.neonCyan.withOpacity(0.05) : Colors.transparent,
      ),
    );
  }
}
