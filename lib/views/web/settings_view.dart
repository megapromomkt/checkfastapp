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

  // Promoter settings state
  bool _enforceGeolocation = true;
  List<String> _bypassCpfs = ['43221002874'];
  bool _enforcePhoto = true;
  bool _allowGallery = false;
  final TextEditingController _bypassCpfsController = TextEditingController();
  bool _loadingPromoterSettings = false;
  bool _savingPromoterSettings = false;

  @override
  void initState() {
    super.initState();
    _resetPermissionsToDefault();
    _loadPromoterSettings();
  }

  @override
  void dispose() {
    _bypassCpfsController.dispose();
    super.dispose();
  }

  Future<void> _loadPromoterSettings() async {
    setState(() => _loadingPromoterSettings = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('promoter_settings').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _enforceGeolocation = data['enforceGeolocation'] ?? true;
          _enforcePhoto = data['enforcePhoto'] ?? true;
          _allowGallery = data['allowGallery'] ?? false;
          final cpfs = List<String>.from(data['bypassCpfs'] ?? []);
          _bypassCpfs = cpfs.isEmpty ? ['43221002874'] : cpfs;
          _bypassCpfsController.text = _bypassCpfs.join('\n');
        });
      } else {
        setState(() {
          _bypassCpfsController.text = _bypassCpfs.join('\n');
        });
      }
    } catch (e) {
      print('Erro ao carregar configurações do prestador: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingPromoterSettings = false);
      }
    }
  }

  Future<void> _savePromoterSettings() async {
    setState(() => _savingPromoterSettings = true);
    try {
      final lines = _bypassCpfsController.text.split('\n');
      final cpfs = lines
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('app_settings').doc('promoter_settings').set({
        'enforceGeolocation': _enforceGeolocation,
        'enforcePhoto': _enforcePhoto,
        'allowGallery': _allowGallery,
        'bypassCpfs': cpfs,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      setState(() {
        _bypassCpfs = cpfs;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✨ Configurações do prestador salvas com sucesso!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar configurações: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingPromoterSettings = false);
      }
    }
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
              _buildTab(1, 'Configurações do Prestador'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Content
        Expanded(
          child: SingleChildScrollView(
            child: _currentTab == 0 ? _buildUserConfig() : _buildPrestadorConfig(),
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

  Widget _buildPrestadorConfig() {
    if (_loadingPromoterSettings) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(IconsaxPlusBold.location, color: AppColors.primaryBlue, size: 24),
                  SizedBox(width: 12),
                  Text('Geolocalização (GPS)', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Defina as regras de validação por proximidade do ponto de check-in e check-out.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exigir Geolocalização', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('O prestador deve estar a menos de 200m da loja para realizar check-in e check-out.', style: TextStyle(fontSize: 12)),
                activeColor: AppColors.primaryBlue,
                value: _enforceGeolocation,
                onChanged: (val) {
                  setState(() {
                    _enforceGeolocation = val;
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.cardBorder),
              ),
              const Text('CPFs com Bypass (Isenção da Trava)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              const Text('Estes usuários poderão realizar o check-in/out de qualquer local. Insira um CPF por linha.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: _bypassCpfsController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'ex: 43221002874\nex: 12345678900',
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PremiumCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(IconsaxPlusBold.camera, color: AppColors.primaryBlue, size: 24),
                  SizedBox(width: 12),
                  Text('Regras de Comprovação por Foto', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Configure as exigências de registro fotográfico no ponto digital.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exigir Foto no Ponto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('O prestador é obrigado a capturar foto para registrar entrada ou saída.', style: TextStyle(fontSize: 12)),
                activeColor: AppColors.primaryBlue,
                value: _enforcePhoto,
                onChanged: (val) {
                  setState(() {
                    _enforcePhoto = val;
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.cardBorder),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Permitir Envio da Galeria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Quando desativado, o prestador só poderá tirar foto em tempo real usando a câmera do dispositivo.', style: TextStyle(fontSize: 12)),
                activeColor: AppColors.primaryBlue,
                value: _allowGallery,
                onChanged: (val) {
                  setState(() {
                    _allowGallery = val;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: _savingPromoterSettings ? null : _savePromoterSettings,
            icon: _savingPromoterSettings
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(_savingPromoterSettings ? 'Salvando...' : 'Salvar Configurações'),
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
}
