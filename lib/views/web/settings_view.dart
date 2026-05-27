import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String? _selectedProfile;
  int _currentTab = 0;
  
  // Permission state (Mock)
  final Map<String, Map<String, bool>> _permissions = {
    'Cadastros': {'visualizar': true, 'criar': false, 'editar': false, 'excluir': false},
    'Demandas': {'visualizar': true, 'criar': true, 'editar': false, 'excluir': false},
    'Usuários': {'visualizar': false, 'criar': false, 'editar': false, 'excluir': false},
    'Financeiro': {'visualizar': false, 'criar': false, 'editar': false, 'excluir': false},
  };

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
              _buildTab(0, 'Configurar Usuário'),
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

  // --- ABA 1: CONFIGURAR USUÁRIO ---
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
            onChanged: (val) => setState(() => _selectedProfile = val),
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
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
              0: FlexColumnWidth(2),
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
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(module, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    _buildCheckboxCell(module, 'visualizar', perms['visualizar']!),
                    _buildCheckboxCell(module, 'criar', perms['criar']!),
                    _buildCheckboxCell(module, 'editar', perms['editar']!),
                    _buildCheckboxCell(module, 'excluir', perms['excluir']!),
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
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salvar Permissões', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Checkbox(
        value: value,
        activeColor: AppColors.primaryBlue,
        onChanged: (val) {
          setState(() {
            _permissions[module]![action] = val ?? false;
          });
        },
      ),
    );
  }


  Widget _buildSwitchTile(String title, bool value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Switch(
        value: value,
        activeColor: AppColors.primaryBlue,
        onChanged: (val) {},
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: initialValue),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
