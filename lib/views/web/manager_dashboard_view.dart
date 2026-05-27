import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';
import '../../models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManagerDashboardView extends StatefulWidget {
  const ManagerDashboardView({super.key});

  @override
  State<ManagerDashboardView> createState() => _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends State<ManagerDashboardView>
    with SingleTickerProviderStateMixin {
  final _api = RegisterService();

  late TabController _tabController;

  // Dados do gerente logado
  String _managerName = '';
  String _managerRole = '';
  String _managerStoreId = '';

  // Dados da loja vinculada
  AppStore? _store;
  AppBandeira? _bandeira;
  List<AppDemand> _storeDemands = [];
  List<AppEPIDelivery> _epiDeliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getString('manager_store_id') ?? '';
    setState(() {
      _managerName = prefs.getString('manager_user_name') ?? 'Gerente';
      _managerRole = prefs.getString('manager_user_role') ?? 'Gerente de Loja';
      _managerStoreId = storeId;
    });
    await _loadStoreData(storeId);
  }

  Future<void> _loadStoreData(String storeId) async {
    if (storeId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final stores = await _api.getStores();
      final bandeiras = await _api.getBandeiras();
      final demands = await _api.getDemands();
      final epis = await _api.getEPIDeliveries();

      final store = stores.cast<AppStore?>().firstWhere(
        (s) => s?.id == storeId,
        orElse: () => null,
      );

      AppBandeira? bandeira;
      if (store != null && store.bandeiraId.isNotEmpty) {
        bandeira = bandeiras.cast<AppBandeira?>().firstWhere(
          (b) => b?.id == store.bandeiraId,
          orElse: () => null,
        );
      }

      final storeDemands = demands.where((d) => d.storeId == storeId).toList();
      final storeEpis = epis.where((e) => e.storeId == storeId).toList();

      setState(() {
        _store = store;
        _bandeira = bandeira;
        _storeDemands = storeDemands;
        _epiDeliveries = storeEpis;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('manager_user_id');
    await prefs.remove('manager_user_name');
    await prefs.remove('manager_user_role');
    await prefs.remove('manager_store_id');
    if (mounted) Navigator.pushReplacementNamed(context, '/gerente');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _managerStoreId.isEmpty
              ? _buildNoStoreScreen()
              : _buildDashboard(),
    );
  }

  Widget _buildNoStoreScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconsaxPlusLinear.buildings_2, size: 80, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma loja vinculada',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Seu perfil não possui uma loja associada.\nContate o administrador do sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7A9BB5), fontSize: 14),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(IconsaxPlusLinear.logout, color: Colors.white60),
              label: const Text('Sair', style: TextStyle(color: Colors.white60)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Row(
      children: [
        // Sidebar compacta
        _buildSidebar(),
        // Conteúdo principal
        Expanded(
          child: Column(
            children: [
              _buildTopBar(),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(IconsaxPlusLinear.chart_square, size: 18), text: 'Visão Geral'),
                  Tab(icon: Icon(IconsaxPlusLinear.task_square, size: 18), text: 'Demandas'),
                  Tab(icon: Icon(IconsaxPlusLinear.shield_tick, size: 18), text: 'EPIs Entregues'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildDemandsTab(),
                    _buildEPITab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: const Color(0xFF0D1B2A),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF00BFFF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(IconsaxPlusLinear.buildings_2, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CheckFast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text('Portal Gerente', style: TextStyle(color: Color(0xFF7A9BB5), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Informações da loja vinculada
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2D4A6A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LOJA VINCULADA', style: TextStyle(color: Color(0xFF7A9BB5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  _store?.name ?? 'Carregando...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_bandeira != null) ...[
                  const SizedBox(height: 4),
                  Text(_bandeira!.name, style: const TextStyle(color: Color(0xFF7A9BB5), fontSize: 11)),
                ],
                if (_store != null && _store!.city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(IconsaxPlusLinear.location, color: Color(0xFF7A9BB5), size: 12),
                      const SizedBox(width: 4),
                      Text('${_store!.city} / ${_store!.state}', style: const TextStyle(color: Color(0xFF7A9BB5), fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),

          // Info do usuário + logout
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    (_managerName.isNotEmpty ? _managerName[0] : 'G').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_managerName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_managerRole, style: const TextStyle(color: Color(0xFF7A9BB5), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _logout,
              icon: const Icon(IconsaxPlusLinear.logout, color: Colors.redAccent, size: 16),
              label: const Text('Sair', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 13)),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $_managerName 👋',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Text(
                  'Gerenciando: ${_store?.name ?? "Loja não vinculada"}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ===================== ABA 1: VISÃO GERAL =====================
  Widget _buildOverviewTab() {
    final openDemands = _storeDemands.where((d) => d.status == 'ABERTAS' || d.status == 'EM ANDAMENTO').length;
    final finishedDemands = _storeDemands.where((d) => d.status == 'FINALIZADAS').length;
    final totalEpis = _epiDeliveries.fold<int>(0, (sum, e) => sum + e.quantity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumo da Loja', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Dados atualizados em tempo real da sua loja.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          // KPI Cards
          Row(
            children: [
              Expanded(child: _buildKPICard('Demandas Abertas', '$openDemands', IconsaxPlusLinear.task_square, AppColors.primaryBlue)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPICard('Demandas Finalizadas', '$finishedDemands', IconsaxPlusLinear.tick_circle, AppColors.success)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPICard('Total de Demandas', '${_storeDemands.length}', IconsaxPlusLinear.calendar, AppColors.warning)),
              const SizedBox(width: 16),
              Expanded(child: _buildKPICard('EPIs Entregues', '$totalEpis un', IconsaxPlusLinear.shield_tick, const Color(0xFF7C3AED))),
            ],
          ),
          const SizedBox(height: 32),

          // Dados da Loja
          if (_store != null) ...[
            const Text('Dados da Loja', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildInfoRow(IconsaxPlusLinear.buildings_2, 'Nome', _store!.name),
                  _buildInfoRow(IconsaxPlusLinear.global, 'Bandeira', _bandeira?.name ?? _store!.bandeiraId),
                  _buildInfoRow(IconsaxPlusLinear.location, 'Endereço', '${_store!.logradouro}${_store!.numero.isNotEmpty ? ", ${_store!.numero}" : ""} - ${_store!.bairro}, ${_store!.city} / ${_store!.state}'),
                  _buildInfoRow(IconsaxPlusLinear.document_text, 'CNPJ', _store!.cnpj.isNotEmpty ? _store!.cnpj : 'Não informado'),
                  _buildInfoRow(IconsaxPlusLinear.activity, 'Status', _store!.status),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ===================== ABA 2: DEMANDAS =====================
  Widget _buildDemandsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demandas da Loja (${_storeDemands.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text('Apenas demandas vinculadas a esta loja.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          Expanded(
            child: _storeDemands.isEmpty
                ? _buildEmptyState('Nenhuma demanda encontrada para esta loja.', IconsaxPlusLinear.task_square)
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        // Cabeçalho
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('FUNÇÃO / PAPEL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                              Expanded(flex: 2, child: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                              Expanded(flex: 2, child: Text('HORÁRIO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                              Expanded(flex: 2, child: Text('PROMOTOR', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                              Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                            ],
                          ),
                        ),
                        // Linhas
                        Expanded(
                          child: ListView.separated(
                            itemCount: _storeDemands.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                            itemBuilder: (context, index) {
                              final d = _storeDemands[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(d.role, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                                    Expanded(flex: 2, child: Text(d.date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                                    Expanded(flex: 2, child: Text(d.timeRange, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        d.assignedPromoter?.isNotEmpty == true ? d.assignedPromoter! : '—',
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: _buildStatusBadge(d.status),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'FINALIZADAS':
        color = AppColors.success;
        break;
      case 'EM ANDAMENTO':
        color = AppColors.primaryBlue;
        break;
      case 'ABERTAS':
        color = AppColors.warning;
        break;
      case 'CANCELADA':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ===================== ABA 3: EPIs =====================
  Widget _buildEPITab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EPIs Entregues (${_epiDeliveries.length} registros)',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text('Histórico de equipamentos de proteção entregues nesta loja.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _epiDeliveries.isEmpty
                ? _buildEmptyState('Nenhum EPI registrado para esta loja.', IconsaxPlusLinear.shield_tick)
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(flex: 3, child: Text('EPI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                              Expanded(flex: 2, child: Text('DATA DE ENTREGA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                              Expanded(flex: 2, child: Text('QTD ENTREGUE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _epiDeliveries.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                            itemBuilder: (context, index) {
                              final e = _epiDeliveries[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(e.epi, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                    Expanded(flex: 2, child: Text(e.deliveryDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${e.quantity} un', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
