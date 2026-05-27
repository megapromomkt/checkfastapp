import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';
import '../../models/app_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RedeDashboardView extends StatefulWidget {
  const RedeDashboardView({super.key});
  @override
  State<RedeDashboardView> createState() => _RedeDashboardViewState();
}

class _RedeDashboardViewState extends State<RedeDashboardView> with SingleTickerProviderStateMixin {
  final _api = RegisterService();
  late TabController _tabController;

  String _userName = '';
  String _userRole = '';
  String _storeId = '';
  String _regional = '';
  List<String> _storeIds = [];
  bool _isRegional = false;

  AppStore? _store;
  List<AppStore> _regionalStores = [];
  List<AppBandeira> _bandeiras = [];
  List<AppDemand> _demands = [];
  List<AppEPIDelivery> _epis = [];
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
    final storeId = prefs.getString('rede_store_id') ?? '';
    final regional = prefs.getString('rede_regional') ?? '';
    final storeIds = prefs.getStringList('rede_store_ids') ?? [];
    final role = prefs.getString('rede_user_role') ?? '';
    final isRegional = role == 'Regional';

    setState(() {
      _userName = prefs.getString('rede_user_name') ?? '';
      _userRole = role;
      _storeId = storeId;
      _regional = regional;
      _storeIds = storeIds;
      _isRegional = isRegional;
    });
    await _loadData(storeId, regional, storeIds, isRegional);
  }

  Future<void> _loadData(String storeId, String regional, List<String> storeIds, bool isRegional) async {
    try {
      final stores = await _api.getStores();
      final bandeiras = await _api.getBandeiras();
      final demands = await _api.getDemands();
      final epis = await _api.getEPIDeliveries();

      List<AppStore> filteredStores = [];
      List<AppDemand> filteredDemands = [];
      List<AppEPIDelivery> filteredEpis = [];

      if (isRegional) {
        // Regional vê todas as lojas da sua regional
        if (regional.isNotEmpty) {
          filteredStores = stores.where((s) => s.regional.toLowerCase() == regional.toLowerCase()).toList();
        } else if (storeIds.isNotEmpty) {
          filteredStores = stores.where((s) => storeIds.contains(s.id)).toList();
        }
        final ids = filteredStores.map((s) => s.id).toSet();
        filteredDemands = demands.where((d) => d.storeId != null && ids.contains(d.storeId)).toList();
        filteredEpis = epis.where((e) => ids.contains(e.storeId)).toList();
      } else {
        // Líder vê apenas a loja vinculada
        final store = stores.cast<AppStore?>().firstWhere((s) => s?.id == storeId, orElse: () => null);
        if (store != null) filteredStores = [store];
        filteredDemands = demands.where((d) => d.storeId == storeId).toList();
        filteredEpis = epis.where((e) => e.storeId == storeId).toList();
      }

      setState(() {
        _store = filteredStores.isNotEmpty ? filteredStores.first : null;
        _regionalStores = filteredStores;
        _bandeiras = bandeiras;
        _demands = filteredDemands;
        _epis = filteredEpis;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['rede_user_id', 'rede_user_name', 'rede_user_role', 'rede_store_id', 'rede_regional']) {
      await prefs.remove(key);
    }
    if (mounted) Navigator.pushReplacementNamed(context, '/rede');
  }

  String _getBandeiraName(String bandeiraId) {
    return _bandeiras.cast<AppBandeira?>().firstWhere((b) => b?.id == bandeiraId, orElse: () => null)?.name ?? bandeiraId;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFFF0F4F8), body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)));
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryBlue,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: [
                      Tab(icon: const Icon(IconsaxPlusLinear.chart_square, size: 18), text: _isRegional ? 'Visão Regional' : 'Visão Geral'),
                      Tab(icon: const Icon(IconsaxPlusLinear.buildings_2, size: 18), text: _isRegional ? 'Lojas (${_regionalStores.length})' : 'Demandas'),
                      const Tab(icon: Icon(IconsaxPlusLinear.shield_tick, size: 18), text: 'EPIs'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _isRegional ? _buildStoresTab() : _buildDemandsTab(),
                      _buildEPITab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final isRegional = _isRegional;
    return Container(
      width: 230,
      color: const Color(0xFF0A1628),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0066FF), Color(0xFF00BFFF)]), borderRadius: BorderRadius.circular(10)),
                child: const Icon(IconsaxPlusLinear.global, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CheckFast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  Text(isRegional ? 'Ambiente Regional' : 'Ambiente Rede', style: const TextStyle(color: Color(0xFF6B8CAD), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Badge de perfil
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isRegional ? const Color(0xFF7C3AED) : AppColors.primaryBlue).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (isRegional ? const Color(0xFF7C3AED) : AppColors.primaryBlue).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(isRegional ? IconsaxPlusLinear.map : IconsaxPlusLinear.profile_2user,
                    color: isRegional ? const Color(0xFF7C3AED) : AppColors.primaryBlue, size: 14),
                const SizedBox(width: 8),
                Flexible(child: Text(_userRole, style: TextStyle(color: isRegional ? const Color(0xFF7C3AED) : AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info de escopo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF111F35), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1E3A5F))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isRegional ? 'REGIONAL' : 'LOJA VINCULADA', style: const TextStyle(color: Color(0xFF6B8CAD), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  isRegional ? (_regional.isNotEmpty ? _regional : '${_regionalStores.length} lojas') : (_store?.name ?? 'Não vinculada'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                if (isRegional) ...[
                  const SizedBox(height: 4),
                  Text('${_regionalStores.length} lojas na regional', style: const TextStyle(color: Color(0xFF6B8CAD), fontSize: 11)),
                ] else if (_store != null && _store!.city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('${_store!.city} / ${_store!.state}', style: const TextStyle(color: Color(0xFF6B8CAD), fontSize: 11)),
                ],
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF111F35), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: AppColors.primaryBlue, child: Text((_userName.isNotEmpty ? _userName[0] : 'R').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(_userRole, style: const TextStyle(color: Color(0xFF6B8CAD), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
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
              style: TextButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.cardBorder))),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Olá, $_userName 👋', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(_isRegional ? 'Regional: ${_regional.isNotEmpty ? _regional : "Configurar regional"}' : 'Loja: ${_store?.name ?? "Não vinculada"}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ])),
          Text(DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(DateTime.now()), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final open = _demands.where((d) => d.status == 'ABERTAS' || d.status == 'EM ANDAMENTO').length;
    final done = _demands.where((d) => d.status == 'FINALIZADAS').length;
    final totalEpis = _epis.fold<int>(0, (s, e) => s + e.quantity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isRegional ? 'Visão Regional' : 'Visão Geral da Loja', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(_isRegional ? 'Dados consolidados das ${_regionalStores.length} lojas da sua regional.' : 'Dados operacionais da sua loja.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _kpi('Lojas', '${_regionalStores.length}', IconsaxPlusLinear.buildings_2, AppColors.primaryBlue)),
            const SizedBox(width: 16),
            Expanded(child: _kpi('Demandas Abertas', '$open', IconsaxPlusLinear.task_square, AppColors.warning)),
            const SizedBox(width: 16),
            Expanded(child: _kpi('Finalizadas', '$done', IconsaxPlusLinear.tick_circle, AppColors.success)),
            const SizedBox(width: 16),
            Expanded(child: _kpi('EPIs Entregues', '$totalEpis un', IconsaxPlusLinear.shield_tick, const Color(0xFF7C3AED))),
          ]),
        ],
      ),
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 16),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStoresTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Lojas da Regional (${_regionalStores.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Regional: ${_regional.isNotEmpty ? _regional : "Todas as lojas vinculadas"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 20),
        Expanded(
          child: _regionalStores.isEmpty
              ? _empty('Nenhuma loja encontrada para esta regional.', IconsaxPlusLinear.buildings_2)
              : ListView.separated(
                  itemCount: _regionalStores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final s = _regionalStores[i];
                    final storeDemands = _demands.where((d) => d.storeId == s.id).length;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                      child: Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(IconsaxPlusLinear.buildings_2, color: AppColors.primaryBlue, size: 20)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                          Text('${_getBandeiraName(s.bandeiraId)} • ${s.city} / ${s.state}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('$storeDemands', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primaryBlue)),
                          const Text('demandas', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildDemandsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Demandas da Loja (${_demands.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        Expanded(
          child: _demands.isEmpty
              ? _empty('Nenhuma demanda encontrada.', IconsaxPlusLinear.task_square)
              : Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('FUNÇÃO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                        Expanded(flex: 2, child: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                        Expanded(flex: 2, child: Text('HORÁRIO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                        Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                      ]),
                    ),
                    Expanded(child: ListView.separated(
                      itemCount: _demands.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (context, i) {
                        final d = _demands[i];
                        Color sc = AppColors.textSecondary;
                        if (d.status == 'FINALIZADAS') sc = AppColors.success;
                        else if (d.status == 'EM ANDAMENTO') sc = AppColors.primaryBlue;
                        else if (d.status == 'ABERTAS') sc = AppColors.warning;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(children: [
                            Expanded(flex: 3, child: Text(d.role, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                            Expanded(flex: 2, child: Text(d.date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                            Expanded(flex: 2, child: Text(d.timeRange, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                            Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(d.status, style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.bold)))),
                          ]),
                        );
                      },
                    )),
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _buildEPITab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EPIs Entregues (${_epis.length} registros)', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        Expanded(
          child: _epis.isEmpty
              ? _empty('Nenhum EPI registrado.', IconsaxPlusLinear.shield_tick)
              : Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                      child: const Row(children: [
                        Expanded(flex: 3, child: Text('EPI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                        Expanded(flex: 3, child: Text('LOJA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                        Expanded(flex: 2, child: Text('DATA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                        Expanded(flex: 1, child: Text('QTD', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11))),
                      ]),
                    ),
                    Expanded(child: ListView.separated(
                      itemCount: _epis.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                      itemBuilder: (context, i) {
                        final e = _epis[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(children: [
                            Expanded(flex: 3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.08), borderRadius: BorderRadius.circular(6)), child: Text(e.epi, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12)))),
                            Expanded(flex: 3, child: Text(e.storeName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                            Expanded(flex: 2, child: Text(e.deliveryDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                            Expanded(flex: 1, child: Text('${e.quantity}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                          ]),
                        );
                      },
                    )),
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _empty(String msg, IconData icon) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
    const SizedBox(height: 16),
    Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
  ]));
}
