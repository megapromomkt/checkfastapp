import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Logo customizado aproximado da imagem
      Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.check, color: Colors.white, size: 18),
            Positioned(
              top: 4,
              child: CircleAvatar(radius: 2, backgroundColor: Colors.white),
            )
          ],
        ),
      ),
      const SizedBox(width: 12), 
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

  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAll(reg, '.');
    if (decimalPart == '00') {
      return 'R\$ $formattedInteger';
    }
    return 'R\$ $formattedInteger,$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumHeader(
            title: 'Bem-vindo(a) de volta!', 
            subtitle: 'Sua operação esta em movimento.\nAcompanhe resultados, valide execuções e transforme dados em performance.'
          ),

          const SizedBox(height: 32),
          
          // Big Numbers (6 cards)
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.5,
            children: [
              // 1. Diárias Pagas (Real)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('status', isEqualTo: 'pago')
                    .snapshots(),
                builder: (context, snapshot) {
                  double total = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final val = doc.data()['value'];
                      if (val is num) {
                        total += val.toDouble();
                      }
                    }
                  }
                  return _buildBigNumberCard('Diárias Pagas', _formatCurrency(total), Icons.payments, AppColors.success, 'Pago');
                },
              ),
              // 2. Lojas Ativas (Real)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('stores').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildBigNumberCard('Lojas Ativas', '$count', Icons.storefront, AppColors.primaryBlue, 'Cadastradas');
                },
              ),
              // 3. Cadastros Prestador (Real)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('type', isEqualTo: 'prestador')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildBigNumberCard('Cadastros Prestador', '$count', Icons.people, AppColors.warning, 'Total');
                },
              ),
              // 4. Diárias Pendentes (Real)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('status', isEqualTo: 'liberado_pagamento')
                    .snapshots(),
                builder: (context, snapshot) {
                  double total = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final val = doc.data()['value'];
                      if (val is num) {
                        total += val.toDouble();
                      }
                    }
                  }
                  return _buildBigNumberCard('Diárias Pendentes', _formatCurrency(total), Icons.hourglass_empty, Colors.purple, 'Em liberação');
                },
              ),
              // 5. Taxa de Validação (Real)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('applications').snapshots(),
                builder: (context, snapshot) {
                  int approved = 0;
                  int notApproved = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final status = doc.data()['status'] ?? '';
                      if (status == 'liberado_pagamento' || status == 'pago') {
                        approved++;
                      } else if (status == 'nao_aprovada') {
                        notApproved++;
                      }
                    }
                  }
                  double rate = 100.0;
                  final total = approved + notApproved;
                  if (total > 0) {
                    rate = (approved / total) * 100;
                  }
                  return _buildBigNumberCard('Taxa de Validação', '${rate.toStringAsFixed(1).replaceAll('.', ',')}%', Icons.fact_check, Colors.teal, 'Aprovação');
                },
              ),
              // 6. Mensagens Não Lidas (Real)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('support_chats').snapshots(),
                builder: (context, snapshot) {
                  int totalUnread = 0;
                  int activeChatsCount = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final unread = doc.data()['unreadCountAdmin'] ?? 0;
                      if (unread is num && unread > 0) {
                        totalUnread += unread.toInt();
                        activeChatsCount++;
                      }
                    }
                  }
                  return _buildBigNumberCard('Mensagens Não Lidas', '$totalUnread', Icons.chat_bubble_outline_rounded, Colors.blueGrey, '$activeChatsCount chats ativos');
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Row for Bar Chart and Pie Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bar Chart (Acompanhamento de Diárias) - MOCK
              Expanded(
                flex: 2,
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Acompanhamento de Diárias', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Comparativo dos últimos 7 dias', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 250,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMockBar('Sex 10/05', 0.52, 'R\$ 5.200'),
                            _buildMockBar('Sáb 11/05', 0.61, 'R\$ 6.100'),
                            _buildMockBar('Dom 12/05', 0.34, 'R\$ 3.400'),
                            _buildMockBar('Seg 13/05', 0.78, 'R\$ 7.800'),
                            _buildMockBar('Ter 14/05', 0.84, 'R\$ 8.400'),
                            _buildMockBar('Qua 15/05', 0.75, 'R\$ 7.500'),
                            _buildMockBar('Qui 16/05', 0.68, 'R\$ 6.800'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Pie Chart (Distribuição de Status) - MOCK
              Expanded(
                flex: 1,
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distribuição de Status das Diárias', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Em relação ao total dos últimos 7 dias', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 250,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 160,
                                height: 160,
                                child: CircularProgressIndicator(
                                  value: 0.838,
                                  strokeWidth: 24,
                                  backgroundColor: Colors.orange.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                ),
                              ),
                              const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text('R\$ 53.950', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLegendItem('Pagas', 'R\$ 45.200 (83,8%)', AppColors.primaryBlue),
                      const SizedBox(height: 8),
                      _buildLegendItem('Pendentes', 'R\$ 8.750 (16,2%)', Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Row for Tables and Line Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ranking de Lojas
              Expanded(
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ranking de Lojas (por valor pago)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildTableRow('1', 'Loja Centro', 'R\$ 9.850', '+18,6%'),
                      _buildTableRow('2', 'Loja Norte', 'R\$ 8.420', '+12,3%'),
                      _buildTableRow('3', 'Loja Sul', 'R\$ 7.240', '-3,2%'),
                      _buildTableRow('4', 'Loja Leste', 'R\$ 6.890', '+5,7%'),
                      _buildTableRow('5', 'Loja Oeste', 'R\$ 5.800', '+9,1%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Top Promotores
              Expanded(
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top Promotores (por valor pago)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildPromoterRow('João Silva', '18 Diárias', 'R\$ 4.650'),
                      _buildPromoterRow('Maria Santos', '16 Diárias', 'R\$ 4.120'),
                      _buildPromoterRow('Carlos Lima', '14 Diárias', 'R\$ 3.850'),
                      _buildPromoterRow('Ana Oliveira', '12 Diárias', 'R\$ 3.200'),
                      _buildPromoterRow('Pedro Costa', '11 Diárias', 'R\$ 2.950'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Taxa de Validação (Line Chart Mock)
              Expanded(
                child: PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Taxa de Validação', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Evolução da taxa de aprovação', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 150,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildMockLinePoint('88,0%', 0.6),
                            _buildMockLinePoint('87,5%', 0.55),
                            _buildMockLinePoint('85,2%', 0.4),
                            _buildMockLinePoint('90,1%', 0.75),
                            _buildMockLinePoint('91,3%', 0.8),
                            _buildMockLinePoint('92,0%', 0.85),
                            _buildMockLinePoint('92,6%', 0.9),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Sex 10/05', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          Text('Qui 16/05', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigNumberCard(String label, String value, IconData icon, Color color, String variation) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(variation, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMockBar(String label, double heightFactor, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: 30,
          height: 150 * heightFactor,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildMockLinePoint(String value, double heightFactor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        ),
        Container(
          width: 2,
          height: 100 * heightFactor,
          color: AppColors.success.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ],
        ),
        Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildTableRow(String rank, String name, String value, String variation) {
    final isNegative = variation.startsWith('-');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(rank, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              Text(name, style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          Row(
            children: [
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              Text(variation, style: TextStyle(color: isNegative ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoterRow(String name, String value, String money) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 12, backgroundColor: AppColors.lightBlue, child: Icon(Icons.person, size: 14, color: AppColors.primaryBlue)),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(color: AppColors.textPrimary)),
            ],
          ),
          Row(
            children: [
              Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 15),
              Text(money, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
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
