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

class BIContent extends StatefulWidget {
  const BIContent({super.key});

  @override
  State<BIContent> createState() => _BIContentState();
}

class _BIContentState extends State<BIContent> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _appsStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _storesStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _chatsStream;

  @override
  void initState() {
    super.initState();
    _appsStream = FirebaseFirestore.instance.collection('applications').snapshots();
    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
    _storesStream = FirebaseFirestore.instance.collection('stores').snapshots();
    _chatsStream = FirebaseFirestore.instance.collection('support_chats').snapshots();
  }

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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _appsStream,
      builder: (context, appsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _usersStream,
          builder: (context, usersSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _storesStream,
              builder: (context, storesSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _chatsStream,
                  builder: (context, chatsSnapshot) {
                    if (appsSnapshot.connectionState == ConnectionState.waiting ||
                        usersSnapshot.connectionState == ConnectionState.waiting ||
                        storesSnapshot.connectionState == ConnectionState.waiting ||
                        chatsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      );
                    }

                    final appsDocs = appsSnapshot.data?.docs ?? [];
                    final usersDocs = usersSnapshot.data?.docs ?? [];
                    final storesDocs = storesSnapshot.data?.docs ?? [];
                    final chatsDocs = chatsSnapshot.data?.docs ?? [];

                    // 1. Big Numbers:
                    // Diárias Pagas
                    double paidTotal = 0;
                    // Diárias Pendentes
                    double pendingTotal = 0;
                    // Taxa de Validação (approved / (approved + notApproved))
                    int approvedCount = 0;
                    int notApprovedCount = 0;

                    for (var doc in appsDocs) {
                      final data = doc.data();
                      final status = data['status'] ?? '';
                      final valNum = data['value'];
                      double val = 0.0;
                      if (valNum is num) {
                        val = valNum.toDouble();
                      }

                      if (status == 'pago') {
                        paidTotal += val;
                        approvedCount++;
                      } else if (status == 'liberado_pagamento') {
                        pendingTotal += val;
                        approvedCount++;
                      } else if (status == 'nao_aprovada') {
                        notApprovedCount++;
                      }
                    }

                    double validationRate = 100.0;
                    final totalVal = approvedCount + notApprovedCount;
                    if (totalVal > 0) {
                      validationRate = (approvedCount / totalVal) * 100;
                    }

                    // Lojas Ativas
                    final storesCount = storesDocs.length;

                    // Cadastros Prestador (users where type == 'prestador')
                    int promoterCount = 0;
                    final Map<String, String> promoterNames = {};
                    for (var doc in usersDocs) {
                      final data = doc.data();
                      final type = data['type'] ?? '';
                      if (type == 'prestador') {
                        promoterCount++;
                      }
                      final name = data['name'] ?? '';
                      if (name.isNotEmpty) {
                        promoterNames[doc.id] = name;
                      }
                    }

                    // Mensagens não lidas
                    int totalUnreadChats = 0;
                    int activeChatsCount = 0;
                    for (var doc in chatsDocs) {
                      final unread = doc.data()['unreadCountAdmin'] ?? 0;
                      if (unread is num && unread > 0) {
                        totalUnreadChats += unread.toInt();
                        activeChatsCount++;
                      }
                    }

                    // 2. Bar Chart & Pie Chart & validation rates over last 7 days:
                    final now = DateTime.now();
                    final List<DateTime> last7Days = List.generate(7, (i) {
                      return DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
                    });

                    // Helper to check if two DateTimes are the same calendar day
                    bool isSameDay(DateTime d1, DateTime d2) {
                      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
                    }

                    // Date parsing helper
                    DateTime? parseAppDate(Map<String, dynamic> data) {
                      final subAt = data['submittedAt'];
                      if (subAt is String) {
                        try {
                          return DateTime.parse(subAt);
                        } catch (_) {}
                      }
                      final updAt = data['updatedAt'];
                      if (updAt is String) {
                        try {
                          return DateTime.parse(updAt);
                        } catch (_) {}
                      }
                      return null;
                    }

                    // Bar Chart data (sums for last 7 days)
                    final List<double> dailySums = List.filled(7, 0.0);
                    final List<String> dailyLabels = List.filled(7, '');

                    // Pie Chart data (Pagas vs Pendentes in last 7 days)
                    double paid7Days = 0.0;
                    double pending7Days = 0.0;

                    // Validation Rate over last 7 days
                    final List<int> dailyApproved = List.filled(7, 0);
                    final List<int> dailyNotApproved = List.filled(7, 0);

                    for (var doc in appsDocs) {
                      final data = doc.data();
                      final appDate = parseAppDate(data);
                      if (appDate == null) continue;

                      final status = data['status'] ?? '';
                      final valNum = data['value'];
                      double val = 0.0;
                      if (valNum is num) {
                        val = valNum.toDouble();
                      }

                      // Check if it's within the last 7 days
                      for (int i = 0; i < 7; i++) {
                        if (isSameDay(appDate, last7Days[i])) {
                          // Bar chart aggregates active statuses
                          if (status == 'pago' ||
                              status == 'liberado_pagamento' ||
                              status == 'em_analise' ||
                              status == 'tarefa_aprovada' ||
                              status == 'em_andamento') {
                            dailySums[i] += val;
                          }

                          // Pie chart aggregates last 7 days paid vs pending
                          if (status == 'pago') {
                            paid7Days += val;
                          } else if (status == 'liberado_pagamento' ||
                                     status == 'em_analise' ||
                                     status == 'tarefa_aprovada' ||
                                     status == 'em_andamento') {
                            pending7Days += val;
                          }

                          // Validation rates daily
                          if (status == 'pago' || status == 'liberado_pagamento') {
                            dailyApproved[i]++;
                          } else if (status == 'nao_aprovada') {
                            dailyNotApproved[i]++;
                          }
                          break;
                        }
                      }
                    }

                    // Labels for Bar Chart
                    const weekdays = {
                      DateTime.monday: 'Seg',
                      DateTime.tuesday: 'Ter',
                      DateTime.wednesday: 'Qua',
                      DateTime.thursday: 'Qui',
                      DateTime.friday: 'Sex',
                      DateTime.saturday: 'Sáb',
                      DateTime.sunday: 'Dom',
                    };

                    for (int i = 0; i < 7; i++) {
                      final dt = last7Days[i];
                      final dayStr = dt.day.toString().padLeft(2, '0');
                      final monthStr = dt.month.toString().padLeft(2, '0');
                      final dayName = weekdays[dt.weekday] ?? '';
                      dailyLabels[i] = '$dayName $dayStr/$monthStr';
                    }

                    // Normalize Bar Chart heights
                    double maxDailySum = 0.0;
                    for (var sum in dailySums) {
                      if (sum > maxDailySum) {
                        maxDailySum = sum;
                      }
                    }

                    // 3. Pie Chart distributions
                    final totalPie = paid7Days + pending7Days;
                    final pieProgressVal = totalPie > 0 ? paid7Days / totalPie : 0.0;

                    // 4. Ranking de Lojas (all time paid value, and comparison with past 7 days)
                    final Map<String, double> storeTotalPaid = {};
                    final Map<String, double> storeCurrentWeekPaid = {};
                    final Map<String, double> storePreviousWeekPaid = {};

                    final dtStartCurrent = last7Days[0]; // 6 days ago start
                    final dtStartPrevious = dtStartCurrent.subtract(const Duration(days: 7));

                    for (var doc in appsDocs) {
                      final data = doc.data();
                      final status = data['status'] ?? '';
                      if (status != 'pago') continue;

                      final storeName = data['storeName'] ?? 'Outra Loja';
                      final valNum = data['value'];
                      double val = 0.0;
                      if (valNum is num) {
                        val = valNum.toDouble();
                      }

                      storeTotalPaid[storeName] = (storeTotalPaid[storeName] ?? 0.0) + val;

                      final appDate = parseAppDate(data);
                      if (appDate != null) {
                        if (appDate.isAfter(dtStartCurrent) || isSameDay(appDate, dtStartCurrent)) {
                          storeCurrentWeekPaid[storeName] = (storeCurrentWeekPaid[storeName] ?? 0.0) + val;
                        } else if (appDate.isAfter(dtStartPrevious) && appDate.isBefore(dtStartCurrent)) {
                          storePreviousWeekPaid[storeName] = (storePreviousWeekPaid[storeName] ?? 0.0) + val;
                        }
                      }
                    }

                    final sortedStores = storeTotalPaid.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    // 5. Top Promotores (all time paid value)
                    final Map<String, double> promoterTotalPaid = {};
                    final Map<String, int> promoterPaidCount = {};

                    for (var doc in appsDocs) {
                      final data = doc.data();
                      final status = data['status'] ?? '';
                      if (status != 'pago') continue;

                      final cpf = data['promoterCpf'] ?? '';
                      if (cpf.isEmpty) continue;

                      final valNum = data['value'];
                      double val = 0.0;
                      if (valNum is num) {
                        val = valNum.toDouble();
                      }

                      promoterTotalPaid[cpf] = (promoterTotalPaid[cpf] ?? 0.0) + val;
                      promoterPaidCount[cpf] = (promoterPaidCount[cpf] ?? 0) + 1;
                    }

                    final sortedPromoters = promoterTotalPaid.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    // 6. Validation Rate Line chart points
                    final List<String> dailyValidationRates = List.filled(7, '');
                    final List<double> dailyRateFactors = List.filled(7, 0.0);

                    for (int i = 0; i < 7; i++) {
                      final appCount = dailyApproved[i] + dailyNotApproved[i];
                      double rate = 100.0;
                      if (appCount > 0) {
                        rate = (dailyApproved[i] / appCount) * 100;
                      }
                      dailyValidationRates[i] = '${rate.toStringAsFixed(1).replaceAll('.', ',')}%';
                      dailyRateFactors[i] = rate / 100.0;
                    }

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
                              _buildBigNumberCard('Diárias Pagas', _formatCurrency(paidTotal), Icons.payments, AppColors.success, 'Pago'),
                              _buildBigNumberCard('Lojas Ativas', '$storesCount', Icons.storefront, AppColors.primaryBlue, 'Cadastradas'),
                              _buildBigNumberCard('Cadastros Prestador', '$promoterCount', Icons.people, AppColors.warning, 'Total'),
                              _buildBigNumberCard('Diárias Pendentes', _formatCurrency(pendingTotal), Icons.hourglass_empty, Colors.purple, 'Em liberação'),
                              _buildBigNumberCard('Taxa de Validação', '${validationRate.toStringAsFixed(1).replaceAll('.', ',')}%', Icons.fact_check, Colors.teal, 'Aprovação'),
                              _buildBigNumberCard('Mensagens Não Lidas', '$totalUnreadChats', Icons.chat_bubble_outline_rounded, Colors.blueGrey, '$activeChatsCount chats ativos'),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Row for Bar Chart and Pie Chart
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bar Chart (Acompanhamento de Diárias)
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
                                          children: List.generate(7, (index) {
                                            final sum = dailySums[index];
                                            final label = dailyLabels[index];
                                            final factor = maxDailySum > 0 ? sum / maxDailySum : 0.0;
                                            return _buildMockBar(label, factor, _formatCurrency(sum));
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Pie Chart (Distribuição de Status)
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
                                                  value: pieProgressVal,
                                                  strokeWidth: 24,
                                                  backgroundColor: Colors.orange.withOpacity(0.2),
                                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                                ),
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text('Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                                  Text(_formatCurrency(totalPie), style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildLegendItem('Pagas', '${_formatCurrency(paid7Days)} (${totalPie > 0 ? (paid7Days / totalPie * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0'}%)', AppColors.primaryBlue),
                                      const SizedBox(height: 8),
                                      _buildLegendItem('Pendentes', '${_formatCurrency(pending7Days)} (${totalPie > 0 ? (pending7Days / totalPie * 100).toStringAsFixed(1).replaceAll('.', ',') : '0,0'}%)', Colors.orange),
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
                                      if (sortedStores.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.0),
                                          child: Center(child: Text('Nenhum dado de pagamento disponível', style: TextStyle(color: AppColors.textSecondary))),
                                        )
                                      else
                                        ...List.generate(sortedStores.take(5).length, (index) {
                                          final entry = sortedStores[index];
                                          final storeName = entry.key;
                                          final totalValue = entry.value;

                                          final currentWeek = storeCurrentWeekPaid[storeName] ?? 0.0;
                                          final previousWeek = storePreviousWeekPaid[storeName] ?? 0.0;

                                          String variationStr = '+0,0%';
                                          if (previousWeek == 0.0) {
                                            if (currentWeek > 0.0) {
                                              variationStr = '+100,0%';
                                            }
                                          } else {
                                            final varPercent = ((currentWeek - previousWeek) / previousWeek) * 100;
                                            final formatted = varPercent.toStringAsFixed(1).replaceAll('.', ',');
                                            variationStr = varPercent >= 0 ? '+$formatted%' : '$formatted%';
                                          }

                                          return _buildTableRow('${index + 1}', storeName, _formatCurrency(totalValue), variationStr);
                                        }),
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
                                      if (sortedPromoters.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 20.0),
                                          child: Center(child: Text('Nenhum dado de pagamento disponível', style: TextStyle(color: AppColors.textSecondary))),
                                        )
                                      else
                                        ...List.generate(sortedPromoters.take(5).length, (index) {
                                          final entry = sortedPromoters[index];
                                          final cpf = entry.key;
                                          final totalValue = entry.value;
                                          final count = promoterPaidCount[cpf] ?? 0;
                                          
                                          // Resolve promoter name
                                          final promoterName = promoterNames[cpf] ?? 'Promotor (${cpf.substring(0, cpf.length.clamp(0, 3))}...)';

                                          return _buildPromoterRow(promoterName, '$count ${count == 1 ? 'Diária' : 'Diárias'}', _formatCurrency(totalValue));
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Taxa de Validação (Line Chart)
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
                                          children: List.generate(7, (index) {
                                            final rateStr = dailyValidationRates[index];
                                            final factor = dailyRateFactors[index];
                                            return _buildMockLinePoint(rateStr, factor);
                                          }),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(dailyLabels.first, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                          Text(dailyLabels.last, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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
                  },
                );
              },
            );
          },
        );
      },
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
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
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
