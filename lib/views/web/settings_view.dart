import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/premium_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String? _selectedProfile;
  int _currentTab = 0;
  bool _saving = false;
  
  final List<String> _allModules = [
    'Liquidez BI',
    'Cadastros',
    'Usuários',
    'Demandas',
    'Currículos',
    'Presença',
    'Financeiro',
    'Relatórios',
    'Mensagens',
    'Mensagens - Financeiro',
    'Mensagens - Operacional',
    'Mensagens - RH',
    'Mensagens - Suporte Técnico',
    'Configurações',
  ];

  // Permission state (Loaded dynamically)
  final Map<String, Map<String, bool>> _permissions = {};

  @override
  void initState() {
    super.initState();
    _resetPermissionsToDefault();
  }

  void _resetPermissionsToDefault() {
    setState(() {
      _permissions.clear();
      for (final m in _allModules) {
        _permissions[m] = {'visualizar': false, 'criar': false, 'editar': false, 'excluir': false};
      }
    });
  }

  Future<void> _loadPermissionsForProfile(String profile) async {
    if (profile == 'Admin') {
      // Admin has universal access
      setState(() {
        for (final m in _allModules) {
          _permissions[m] = {'visualizar': true, 'criar': true, 'editar': true, 'excluir': true};
        }
      });
      return;
    }
    
    try {
      final doc = await FirebaseFirestore.instance.collection('role_permissions').doc(profile).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final permsMap = data['permissions'] as Map<String, dynamic>?;
        if (permsMap != null) {
          final Map<String, Map<String, bool>> parsed = {};
          for (final m in _allModules) {
            final valMap = permsMap[m] as Map?;
            parsed[m] = {
              'visualizar': valMap?['visualizar'] == true,
              'criar': valMap?['criar'] == true,
              'editar': valMap?['editar'] == true,
              'excluir': valMap?['excluir'] == true,
            };
          }
          setState(() {
            _permissions.clear();
            _permissions.addAll(parsed);
          });
          return;
        }
      }
    } catch (e) {
      print('Erro ao carregar permissões: $e');
    }
    _resetPermissionsToDefault();
  }

  Future<void> _savePermissions() async {
    if (_selectedProfile == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('role_permissions').doc(_selectedProfile).set({
        'permissions': _permissions,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Permissões para o perfil "$_selectedProfile" salvas com sucesso!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar permissões: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configurar empresa', style: TextStyle(color: AppColors.primaryBlue, fontSize: 28, fontWeight: FontWeight.bold)),
        const Text('Customize o que vai ou não aparecer no menu e no aplicativo por usuário ou perfil', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 24),

        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              _buildTab(0, 'Configurar Usuário/Perfil'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Content
        Expanded(
          child: SingleChildScrollView(
            child: _buildUserConfig(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildUserConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seleção de Perfil/Usuário
        const Text('Selecione um Perfil ou Usuário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButton<String>(
            value: _selectedProfile,
            hint: const Text('Selecione...'),
            underline: const SizedBox(),
            isExpanded: true,
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedProfile = val);
                _loadPermissionsForProfile(val);
              }
            },
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text('Admin (Acesso Total)')),
              DropdownMenuItem(value: 'Suporte', child: Text('Suporte')),
              DropdownMenuItem(value: 'Financeiro', child: Text('Financeiro')),
              DropdownMenuItem(value: 'RH', child: Text('RH')),
              DropdownMenuItem(value: 'Trade', child: Text('Trade')),
              DropdownMenuItem(value: 'Prestador', child: Text('Prestador (App)')),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text('Permissões por Tela', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const Text('Defina o que este perfil pode fazer em cada módulo do sistema.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 16),

        // Tabela de Permissões
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            border: const TableBorder(horizontalInside: BorderSide(color: AppColors.cardBorder)),
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: AppColors.background),
                children: [
                  _buildTableHeader('Módulo / Tela'),
                  _buildTableHeader('Visualizar'),
                  _buildTableHeader('Cadastrar'),
                  _buildTableHeader('Editar'),
                  _buildTableHeader('Excluir'),
                ],
              ),
              // Rows
              ..._permissions.entries.map((entry) {
                final module = entry.key;
                final perms = entry.value;
                final isSubChat = module.startsWith('Mensagens -');
                return TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: isSubChat ? 32.0 : 16.0, top: 16.0, bottom: 16.0, right: 16.0),
                      child: Text(
                        module,
                        style: TextStyle(
                          fontWeight: isSubChat ? FontWeight.normal : FontWeight.bold,
                          color: isSubChat ? AppColors.textSecondary : AppColors.textPrimary,
                          fontSize: isSubChat ? 13 : 14,
                        ),
                      ),
                    ),
                    _buildCheckboxCell(module, 'visualizar', perms['visualizar']!),
                    isSubChat ? const SizedBox.shrink() : _buildCheckboxCell(module, 'criar', perms['criar']!),
                    isSubChat ? const SizedBox.shrink() : _buildCheckboxCell(module, 'editar', perms['editar']!),
                    isSubChat ? const SizedBox.shrink() : _buildCheckboxCell(module, 'excluir', perms['excluir']!),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Botão Salvar
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: (_selectedProfile == null || _saving) ? null : _savePermissions,
            icon: _saving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_saving ? 'Salvando...' : 'Salvar Permissões'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildCheckboxCell(String module, String action, bool value) {
    // Disable checkbox editing for Admin profile because Admin always has full access
    final isEditable = _selectedProfile != 'Admin' && _selectedProfile != null;
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Checkbox(
        value: value,
        activeColor: AppColors.primaryBlue,
        onChanged: isEditable ? (val) {
          setState(() {
            _permissions[module]![action] = val ?? false;
            
            // If checking any sub-chat topic visualization, implicitly check main Mensagens visualization!
            if (module.startsWith('Mensagens -') && action == 'visualizar' && val == true) {
              _permissions['Mensagens']!['visualizar'] = true;
            }
          });
        } : null,
      ),
    );
  }
}
