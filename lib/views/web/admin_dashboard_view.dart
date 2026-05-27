import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../core/constants/premium_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/register_models.dart';

import '../../core/data/test_database.dart';
import 'financial_module_view.dart';
import 'presence_control_view.dart';
import 'demands_management_view.dart';
import 'registers_management_view.dart';
import 'business_intelligence_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'users_management_view.dart';

import 'settings_view.dart';
import 'curriculum_search_view.dart';
import 'reports_view.dart';
import 'support_dashboard_view.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => AdminDashboardViewState();
}

class AdminDashboardViewState extends State<AdminDashboardView> {
  String? _initialChatCpf;

  void switchToSupportChat(String cpf) {
    setState(() {
      _initialChatCpf = cpf;
      _selectedModule = 8; // Index of SupportDashboardView (Mensagens)
      _sidebarExpanded = false;
    });
  }

  int _selectedModule = 0;
  bool _sidebarOpen = false;
  bool _sidebarExpanded = false; // Desktop sidebar starts collapsed
  AppUser? _currentUser;
  String _userName = 'Admin Central';
  String _userRole = 'Master Access';

  Map<String, Map<String, bool>> _rolePermissions = {};
  bool _permissionsLoaded = false;
  StreamSubscription? _permissionsSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _permissionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('admin_user_name') ?? prefs.getString('user_name') ?? 'Admin Central';
      _userRole = prefs.getString('admin_user_role') ?? prefs.getString('user_role') ?? 'Master Access';
    });
    _listenToPermissions();
  }

  void _setFallbackPermissions(String role) {
    final Map<String, Map<String, bool>> parsed = {};
    final lowerRole = role.toLowerCase();
    
    if (lowerRole.contains('suporte')) {
      parsed['Mensagens'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens - Suporte Técnico'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens - Operacional'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Currículos'] = {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false};
      parsed['Cadastros'] = {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false};
      parsed['Usuários'] = {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false};
      parsed['Demandas'] = {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false};
      parsed['Presença'] = {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false};
      parsed['Relatórios'] = {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false};
    } else if (lowerRole.contains('rh') || lowerRole.contains('recursos')) {
      parsed['Currículos'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens - RH'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Cadastros'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': false};
      parsed['Demandas'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': false};
      parsed['Relatórios'] = {'visualizar': true, 'criar': true, 'editar': false, 'excluir': false};
    } else if (lowerRole.contains('financeiro')) {
      parsed['Financeiro'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Relatórios'] = {'visualizar': true, 'criar': true, 'editar': false, 'excluir': false};
      parsed['Mensagens'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens - Financeiro'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
    } else if (lowerRole.contains('trade')) {
      parsed['Demandas'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
      parsed['Mensagens - Operacional'] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
    }
    
    setState(() {
      _rolePermissions = parsed;
      _permissionsLoaded = true;
    });
    _ensureSelectedTabAllowed();
  }

  void _listenToPermissions() {
    _permissionsSubscription?.cancel();
    final role = _userRole;
    if (role == 'Master Access' || role == 'Admin') {
      setState(() {
        _permissionsLoaded = true;
      });
      return;
    }
    _permissionsSubscription = FirebaseFirestore.instance
        .collection('role_permissions')
        .doc(role)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final permsMap = data['permissions'] as Map<String, dynamic>?;
        if (permsMap != null) {
          final Map<String, Map<String, bool>> parsed = {};
          permsMap.forEach((key, val) {
            if (val is Map) {
              parsed[key] = {
                'visualizar': val['visualizar'] == true,
                'criar': val['criar'] == true,
                'editar': val['editar'] == true,
                'excluir': val['excluir'] == true,
              };
            }
          });
          if (mounted) {
            setState(() {
              _rolePermissions = parsed;
              _permissionsLoaded = true;
            });
            _ensureSelectedTabAllowed();
          }
        } else {
          if (mounted) {
            _setFallbackPermissions(role);
          }
        }
      } else {
        if (mounted) {
          _setFallbackPermissions(role);
        }
      }
    });
  }

  bool _hasPermission(String module, String action) {
    if (_userRole == 'Master Access' || _userRole == 'Admin') {
      return true;
    }
    if (!_permissionsLoaded) return true; // Let it render during initial load
    final modPerm = _rolePermissions[module];
    if (modPerm != null) {
      return modPerm[action] == true;
    }
    return false;
  }

  void _ensureSelectedTabAllowed() {
    if (!_hasPermission(_moduleLabel(_selectedModule), 'visualizar')) {
      for (int i = 0; i < 10; i++) {
        if (_hasPermission(_moduleLabel(i), 'visualizar')) {
          setState(() {
            _selectedModule = i;
          });
          break;
        }
      }
    }
  }

  bool _canAccessTopic(String? topic, String userRole) {
    final roleLower = userRole.toLowerCase();
    if (roleLower.contains('master') || roleLower.contains('admin') ||
        roleLower.contains('diretor') || roleLower.contains('gerente')) {
      return true;
    }
    final topicLower = (topic ?? '').toLowerCase();
    if (topicLower.contains('financeiro')) return _hasPermission('Mensagens - Financeiro', 'visualizar');
    if (topicLower.contains('operacional')) return _hasPermission('Mensagens - Operacional', 'visualizar');
    if (topicLower.contains('rh') || topicLower.contains('recursos') || topicLower.contains('humanos')) {
      return _hasPermission('Mensagens - RH', 'visualizar');
    }
    if (topicLower.contains('suporte') || topicLower.contains('tecnico') || topicLower.contains('técnico')) {
      return _hasPermission('Mensagens - Suporte Técnico', 'visualizar');
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AppUser) {
      _currentUser = args;
    }
  }

  final List<Widget> _modules = [
    const BIContent(),
    const RegistersManagementView(),
    const UsersManagementView(),
    const DemandsManagementView(),
    const CurriculumSearchView(),
    const PresenceControlView(),
    const FinancialModuleView(),
    const ReportsView(),
    const SupportDashboardView(),
    const SettingsView(),
  ];

  Widget _getSelectedModuleWidget() {
    if (_selectedModule == 8) {
      return SupportDashboardView(initialChatCpf: _initialChatCpf);
    }
    return _modules[_selectedModule];
  }

  static bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: mobile ? _buildDrawer(context) : null,
      body: mobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userRole,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              (_userName.isNotEmpty ? _userName : 'A')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 24,
            width: 1,
            color: AppColors.cardBorder,
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Sair do Sistema',
            child: IconButton(
              icon: const Icon(IconsaxPlusLinear.logout, color: AppColors.error, size: 20),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/megapromo');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        _buildSidebarContent(context, drawer: false),
        Expanded(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.value<double>(context, mobile: 20, tablet: 32, desktop: 48),
                    vertical: Responsive.value<double>(context, mobile: 20, tablet: 32, desktop: 40),
                  ),
                  child: _getSelectedModuleWidget(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      (_userName.isNotEmpty ? _userName : 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(IconsaxPlusLinear.logout, color: AppColors.error, size: 18),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/megapromo');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(Responsive.value<double>(context, mobile: 16, tablet: 20, desktop: 24)),
            child: _getSelectedModuleWidget(),
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('support_chats').snapshots(),
      builder: (context, snapshot) {
        int unreadMessagesCount = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final d = doc.data();
            final topic = d['topic'] ?? '';
            if (_canAccessTopic(topic, _userRole)) {
              unreadMessagesCount += (d['unreadCountAdmin'] ?? 0) as int;
            }
          }
        }

        final expanded = drawer || _sidebarExpanded;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: drawer ? double.infinity : (expanded ? 280 : 85),
          decoration: drawer
              ? null
              : const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(right: BorderSide(color: AppColors.cardBorder))),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (drawer) const SizedBox(height: 16),
              // Top Logo and Collapse/Expand button
              Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                children: [
                  if (expanded) ...[
                    const Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 28),
                    const SizedBox(width: 8),
                    const Text('CHECKFAST', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                  if (!drawer)
                    IconButton(
                      icon: Icon(
                        expanded ? Icons.keyboard_arrow_left_rounded : Icons.menu_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _sidebarExpanded = !_sidebarExpanded;
                        });
                      },
                    ),
                ],
              ),
              if (expanded) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 36, top: 2),
                  child: Text('ADMIN PANEL', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ),
              ],
              const SizedBox(height: 35),
              
              // Menu Items (Filtered by permission)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(context, 0, IconsaxPlusLinear.chart_21, 'Liquidez BI', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 1, IconsaxPlusLinear.folder_open, 'Cadastros', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 2, IconsaxPlusLinear.profile_2user, 'Usuários', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 3, IconsaxPlusLinear.task_square, 'Demandas', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 4, IconsaxPlusLinear.personalcard, 'Currículos', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 5, IconsaxPlusLinear.radar, 'Presença', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 6, IconsaxPlusLinear.wallet_check, 'Financeiro', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 7, IconsaxPlusLinear.document_text, 'Relatórios', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 8, IconsaxPlusLinear.message_2, 'Mensagens', unreadMessagesCount, drawer: drawer),
                    _buildMenuItem(context, 9, IconsaxPlusLinear.setting_4, 'Configurações', unreadMessagesCount, drawer: drawer),
                  ],
                ),
              ),

              // Removed profile box and logout button from here (now at top right of screen)
            ],
          ),
        );
      }
    );
  }

  String _moduleLabel(int index) {
    const labels = ['Liquidez BI', 'Cadastros', 'Usuários', 'Demandas', 'Currículos', 'Presença', 'Financeiro', 'Relatórios', 'Mensagens', 'Configurações'];
    return index < labels.length ? labels[index] : '';
  }

  Widget _buildMenuItem(BuildContext context, int index, IconData icon, String label, int unreadCount, {required bool drawer}) {
    // Check view permission
    if (!_hasPermission(label, 'visualizar')) {
      return const SizedBox.shrink();
    }

    final bool selected = _selectedModule == index;
    final bool expanded = drawer || _sidebarExpanded;

    Widget leadingIcon = Icon(icon, color: selected ? AppColors.primaryBlue : AppColors.textSecondary, size: 22);
    if (index == 8 && unreadCount > 0) {
      leadingIcon = Badge(
        label: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.error,
        child: leadingIcon,
      );
    }

    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Tooltip(
          message: label,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedModule = index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: leadingIcon),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedModule = index;
            _sidebarExpanded = false; // Collapse desktop sidebar automatically
          });
          if (drawer) Navigator.pop(context);
        },
        leading: leadingIcon,
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
