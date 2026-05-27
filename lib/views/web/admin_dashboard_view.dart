import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/register_models.dart';


import 'financial_module_view.dart';
import 'presence_control_view.dart';
import 'demands_management_view.dart';
import 'registers_management_view.dart';
import 'business_intelligence_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'users_management_view.dart';

import 'settings_view.dart';
import 'curriculum_search_view.dart';
import 'reports_view.dart';
import 'support_dashboard_view.dart';
import 'admission_letters_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => AdminDashboardViewState();
}

class AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedModule = 0;
  bool _sidebarOpen = false;
  AppUser? _currentUser;
  String _userName = 'Admin Central';
  String _userRole = 'Master Access';
  String? _activeChatCpf;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('admin_user_name') ?? 'Admin Central';
      _userRole = prefs.getString('admin_user_role') ?? 'Master Access';
    });
  }

  void switchToSupportChat(String cpf) {
    setState(() {
      _activeChatCpf = cpf;
      _selectedModule = 8; // Index corresponding to 'Mensagens'
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AppUser) {
      _currentUser = args;
    }
  }

  List<Widget> get _modules => [
    const BIContent(),
    const RegistersManagementView(),
    const UsersManagementView(),
    const DemandsManagementView(),
    const CurriculumSearchView(),
    const PresenceControlView(),
    const FinancialModuleView(),
    const ReportsView(),
    SupportDashboardView(initialChatCpf: _activeChatCpf),
    const AdmissionLettersView(),
    const SettingsView(),
  ];

  static bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      // Mobile: Drawer-based sidebar
      drawer: mobile ? _buildDrawer(context) : null,
      body: mobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
    );
  }

  /// Desktop: sidebar fixo + conteúdo
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebarContent(context, drawer: false),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.value<double>(context, mobile: 20, tablet: 32, desktop: 48),
              vertical: Responsive.value<double>(context, mobile: 20, tablet: 32, desktop: 40),
            ),
            child: _modules[_selectedModule],
          ),
        ),
      ],
    );
  }

  /// Mobile: AppBar + conteúdo (sidebar no drawer)
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Mobile top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 22),
              const SizedBox(width: 8),
              const Text('CHECKFAST', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text(_moduleLabel(_selectedModule), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // Content
        Expanded(
          child: Container(
            padding: EdgeInsets.all(Responsive.value<double>(context, mobile: 16, tablet: 20, desktop: 24)),
            child: _modules[_selectedModule],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: _buildSidebarContent(context, drawer: true),
    );
  }

  Widget _buildSidebarContent(BuildContext context, {required bool drawer}) {
    return Container(
      width: drawer ? double.infinity : 280,
      decoration: drawer
          ? null
          : const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.cardBorder))),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drawer) const SizedBox(height: 16),
          const Row(
            children: [
              Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 28),
              SizedBox(width: 10),
              Text('CHECKFAST', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 38),
            child: Text('ADMIN PANEL', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const SizedBox(height: 40),
          _buildMenuItem(context, 0, IconsaxPlusLinear.chart_21, 'Liquidez BI', drawer: drawer),
          _buildMenuItem(context, 1, IconsaxPlusLinear.folder_open, 'Cadastros', drawer: drawer),
          _buildMenuItem(context, 2, IconsaxPlusLinear.profile_2user, 'Usuários', drawer: drawer),
          _buildMenuItem(context, 3, IconsaxPlusLinear.task_square, 'Demandas', drawer: drawer),
          _buildMenuItem(context, 4, IconsaxPlusLinear.personalcard, 'Currículos', drawer: drawer),
          _buildMenuItem(context, 5, IconsaxPlusLinear.radar, 'Presença', drawer: drawer),
          _buildMenuItem(context, 6, IconsaxPlusLinear.wallet_check, 'Financeiro', drawer: drawer),
          _buildMenuItem(context, 7, IconsaxPlusLinear.document_text, 'Relatórios', drawer: drawer),
          _buildMenuItem(context, 8, IconsaxPlusLinear.message_2, 'Mensagens', drawer: drawer),
          _buildMenuItem(context, 9, IconsaxPlusLinear.document_favorite, 'Cartas', drawer: drawer),
          _buildMenuItem(context, 10, IconsaxPlusLinear.setting_4, 'Configurações', drawer: drawer),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18, 
                  backgroundColor: AppColors.primaryBlue, 
                  child: Text(
                    (_userName.isNotEmpty ? _userName : 'A')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_userName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_userRole, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)
                    ]
                  ),
                )
              ]
            )


          ),
          const SizedBox(height: 12),
          // Botão de Sair (Logout)
           SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('admin_user_name');
                await prefs.remove('admin_user_role');
                Navigator.pushReplacementNamed(context, '/megapromo');
              },
              icon: const Icon(IconsaxPlusLinear.logout, color: AppColors.error, size: 20),
              label: const Text('Sair do Sistema', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

        ],
      ),
    );
  }

  String _moduleLabel(int index) {
    const labels = ['Liquidez BI', 'Cadastros', 'Usuários', 'Demandas', 'Currículos', 'Presença', 'Financeiro', 'Relatórios', 'Mensagens', 'Cartas', 'Configurações'];
    return index < labels.length ? labels[index] : '';
  }

  Widget _buildMenuItem(BuildContext context, int index, IconData icon, String label, {required bool drawer}) {
    bool selected = _selectedModule == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: () {
          setState(() => _selectedModule = index);
          if (drawer) Navigator.pop(context);
        },
        leading: Icon(icon, color: selected ? AppColors.primaryBlue : AppColors.textSecondary, size: 22),
        title: Text(label, style: TextStyle(
          color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14
        )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: selected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.transparent,
        dense: true,
      ),
    );
  }
}
