import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../models/app_models.dart';
import '../../models/register_models.dart';
import '../../core/services/register_service.dart';
import 'widgets/create_demand_modal.dart';

class DemandsManagementView extends StatefulWidget {
  const DemandsManagementView({super.key});

  @override
  State<DemandsManagementView> createState() => _DemandsManagementViewState();
}

class _DemandsManagementViewState extends State<DemandsManagementView> {
  final _api = RegisterService();

  // Search & Filters State
  String _searchQuery = '';
  String _filterClient = 'Todos';
  String _filterProject = 'Todos';
  String _filterRole = 'Todos';
  String _filterPriority = 'Todas';
  bool _filtersExpanded = false;

  // Mass Actions Selection
  final Set<String> _selectedDemandIds = {};

  // Vínculo & Realocação State
  int _activeTab = 0;
  AppDemand? _selectedDemandForVinculo;
  int _vinculoSubTab = 0;
  String _promoterSearchQuery = '';
  final ScrollController _horizontalDemandScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalDemandScrollController.dispose();
    super.dispose();
  }

  Future<void> _cleanDuplicates(BuildContext context) async {
    // Mostrar loading de análise
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryBlue),
                SizedBox(height: 16),
                Text('Analisando base de demandas...', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final allDemands = await _api.getDemands();
      
      // Fechar o loading de análise
      if (context.mounted) Navigator.pop(context);

      // Função de timestamp robusta
      int getTimestamp(String id) {
        final clean = id.replaceAll(RegExp(r'\D+'), '_');
        final parts = clean.split('_').where((s) => s.isNotEmpty).toList();
        for (var part in parts) {
          if (part.length >= 12) {
            final val = int.tryParse(part);
            if (val != null) return val;
          }
        }
        return 0;
      }

      // Agrupar demandas por storeId, role, data e horário
      final Map<String, List<AppDemand>> groups = {};
      for (var d in allDemands) {
        final storeKey = d.storeId ?? d.storeName;
        final key = "${storeKey}_${d.role}_${d.date}_${d.timeRange}";
        groups.putIfAbsent(key, () => []).add(d);
      }

      final List<AppDemand> duplicatesToDelete = [];

      for (var list in groups.values) {
        if (list.length > 1) {
          // Ordenar pelo timestamp do ID de forma ascendente
          list.sort((a, b) => getTimestamp(a.id).compareTo(getTimestamp(b.id)));
          
          // O último é o mais recente (mantido), os anteriores são deletados
          duplicatesToDelete.addAll(list.sublist(0, list.length - 1));
        }
      }

      if (duplicatesToDelete.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma demanda duplicada foi detectada.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }

      // Mostrar diálogo de confirmação
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Limpar Demandas Duplicadas', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Text(
            'Detectamos ${duplicatesToDelete.length} demandas duplicadas de um total de ${allDemands.length} cadastradas.\n\n'
            'Deseja remover as ${duplicatesToDelete.length} duplicadas e manter apenas a última/mais recente de cada loja?',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('REMOVER DUPLICADAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Mostrar loading de exclusão
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.error),
                  SizedBox(height: 16),
                  Text('Removendo duplicadas da nuvem...', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      );

      // Deletar duplicadas
      for (var d in duplicatesToDelete) {
        await _api.deleteDemand(d.id);
      }

      // Fechar loading de exclusão
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${duplicatesToDelete.length} demandas duplicadas foram removidas com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Tenta fechar qualquer loading aberto em caso de erro
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao analisar base: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _clearActiveDemands(BuildContext context) async {
    // Mostrar loading de análise
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryBlue),
                SizedBox(height: 16),
                Text('Analisando base de demandas...', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final allDemands = await _api.getDemands();
      
      // Fechar o loading de análise
      if (context.mounted) Navigator.pop(context);

      final activeDemands = allDemands.where((d) => d.status == 'ABERTAS').toList();

      if (activeDemands.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma demanda ativa (aberta) foi encontrada.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }

      // Mostrar diálogo de confirmação
      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Excluir Demandas Ativas', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          content: Text(
            'Detectamos ${activeDemands.length} demandas ativas (abertas) no sistema.\n\n'
            'Deseja remover permanentemente todas as ${activeDemands.length} demandas ativas? Esta ação é irreversível.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('EXCLUIR TODAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Mostrar loading de exclusão
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.error),
                  SizedBox(height: 16),
                  Text('Removendo demandas ativas da nuvem...', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      );

      // Deletar ativas
      for (var d in activeDemands) {
        await _api.deleteDemand(d.id);
      }

      // Fechar loading de exclusão
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${activeDemands.length} demandas ativas foram removidas com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao analisar/excluir demandas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Ações em Massa
  Future<void> _bulkDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Excluir Demandas em Massa', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Text('Tem certeza que deseja excluir permanentemente as ${_selectedDemandIds.length} demandas selecionadas? Esta ação é irreversível.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.error)),
    );

    try {
      for (var id in _selectedDemandIds) {
        await _api.deleteDemand(id);
      }
      setState(() {
        _selectedDemandIds.clear();
      });
      if (context.mounted) {
        Navigator.pop(context); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demandas excluídas em massa com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir demandas: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _bulkChangeStatus(BuildContext context, List<AppDemand> allDemands) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: Colors.white,
        title: const Text('Alterar Status das Demandas Selecionadas', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        children: ['RASCUNHO', 'ABERTAS', 'PREENCHIDAS', 'EM ANDAMENTO', 'FINALIZADAS'].map((s) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, s),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
          ),
        )).toList(),
      ),
    );

    if (newStatus == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      for (var id in _selectedDemandIds) {
        final d = allDemands.firstWhere((dem) => dem.id == id);
        final updated = AppDemand(
          id: d.id,
          clientId: d.clientId,
          projectId: d.projectId,
          storeId: d.storeId,
          roleId: d.roleId,
          storeName: d.storeName,
          network: d.network,
          address: d.address,
          role: d.role,
          distance: d.distance,
          timeRange: d.timeRange,
          value: d.value,
          date: d.date,
          urgency: d.urgency,
          status: newStatus,
          assignedPromoter: d.assignedPromoter,
          clientName: d.clientName,
          projectName: d.projectName,
          totalVagas: d.totalVagas,
          filledVagas: d.filledVagas,
          entryTime: d.entryTime,
          exitTime: d.exitTime,
          requiresCheckIn: d.requiresCheckIn,
          requiresCheckOut: d.requiresCheckOut,
          requiresPhoto: d.requiresPhoto,
          requiresLocation: d.requiresLocation,
          allowedRadius: d.allowedRadius,
          maxPromoterDistance: d.maxPromoterDistance,
          instructions: d.instructions,
          priority: d.priority,
          questionnaire: d.questionnaire,
          requiredActivity: d.requiredActivity,
          stepByStep: d.stepByStep,
          minTime: d.minTime,
          dressCode: d.dressCode,
          requiredDocuments: d.requiredDocuments,
          latitude: d.latitude,
          longitude: d.longitude,
        );
        await _api.saveDemand(updated);
      }
      setState(() {
        _selectedDemandIds.clear();
      });
      if (context.mounted) {
        Navigator.pop(context); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status das demandas alterado com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao alterar status: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ── Atualizar valor da diária em lote ─────────────────────────────────────
  Future<void> _bulkUpdateValue(BuildContext context, List<AppDemand> allDemands) async {
    final valueController = TextEditingController();
    final newValue = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Atualizar Valor da Diária', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informe o novo valor de diária para as ${_selectedDemandIds.isEmpty ? "todas as" : _selectedDemandIds.length.toString()} demandas selecionadas.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: valueController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                  hintText: '150.00',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta ação atualiza apenas as demandas selecionadas na lista.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(valueController.text.replaceAll(',', '.'));
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ATUALIZAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    valueController.dispose();

    if (newValue == null) return;

    // Choose targets: selected items or (if none selected) ask about all ABERTAS
    List<AppDemand> targets;
    if (_selectedDemandIds.isNotEmpty) {
      targets = allDemands.where((d) => _selectedDemandIds.contains(d.id)).toList();
    } else {
      targets = allDemands.where((d) => d.status == 'ABERTAS').toList();
    }

    if (targets.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma demanda encontrada para atualizar.'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      for (final d in targets) {
        await FirebaseFirestore.instance
            .collection('demands')
            .doc(d.id)
            .update({'value': newValue});
      }
      setState(() => _selectedDemandIds.clear());
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('R\$ ${newValue.toStringAsFixed(2)} aplicado em ${targets.length} demanda(s)!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar valor: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppDemand>>(
      stream: _api.getDemandsStream(),
      builder: (context, demandsSnapshot) {
        if (demandsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }
        
        final allDemands = demandsSnapshot.data ?? [];

        // Safely update the selected demand details
        if (_selectedDemandForVinculo != null) {
          final found = allDemands.where((d) => d.id == _selectedDemandForVinculo!.id).toList();
          if (found.isNotEmpty) {
            _selectedDemandForVinculo = found.first;
          } else {
            _selectedDemandForVinculo = null;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, usersSnapshot) {
            if (usersSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
            }
            
            final userDocs = usersSnapshot.data?.docs ?? [];
            final Map<String, Map<String, dynamic>> promoterMap = {};
            for (var doc in userDocs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['type'] == 'prestador' || data['role'] == 'worker' || data['role'] == 'prestador') {
                promoterMap[doc.id] = data;
              }
            }

            // 1. Extrair filtros dinamicamente da lista
            final Set<String> clients = {'Todos'};
            final Set<String> projects = {'Todos'};
            final Set<String> roles = {'Todos'};
            for (var d in allDemands) {
              if (d.clientName != null) clients.add(d.clientName!);
              if (d.projectName != null) projects.add(d.projectName!);
              roles.add(d.role);
            }

            // 2. Aplicar busca e filtros
            final List<AppDemand> filteredDemands = allDemands.where((d) {
              final matchesSearch = d.storeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  d.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (d.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                  (d.projectName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
              
              final matchesClient = _filterClient == 'Todos' || d.clientName == _filterClient;
              final matchesProject = _filterProject == 'Todos' || d.projectName == _filterProject;
              final matchesRole = _filterRole == 'Todos' || d.role == _filterRole;
              final matchesPriority = _filterPriority == 'Todas' || d.priority == _filterPriority;

              return matchesSearch && matchesClient && matchesProject && matchesRole && matchesPriority;
            }).toList();

            // 3. Agrupamento por status (para o Kanban)
            int countRascunho = filteredDemands.where((d) => d.status == 'RASCUNHO').length;
            int countAbertas = filteredDemands.where((d) => d.status == 'ABERTAS').length;
            int countPreenchidas = filteredDemands.where((d) => d.status == 'PREENCHIDAS').length;
            int countAndamento = filteredDemands.where((d) => d.status == 'EM ANDAMENTO').length;
            int countFinalizadas = filteredDemands.where((d) => d.status == 'FINALIZADAS').length;

            // 4. Seletor de Filtros Avançados
            final filterPanel = AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _filtersExpanded ? 110 : 0,
              margin: EdgeInsets.only(bottom: _filtersExpanded ? 24 : 0),
              padding: _filtersExpanded ? const EdgeInsets.all(20) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _filtersExpanded 
                  ? Row(
                      children: [
                        // Cliente
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CLIENTE', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _filterClient,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() => _filterClient = val ?? 'Todos'),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Projeto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PROJETO', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _filterProject,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: projects.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() => _filterProject = val ?? 'Todos'),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Função
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('FUNÇÃO / CARGO', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _filterRole,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() => _filterRole = val ?? 'Todos'),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Prioridade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRIORIDADE', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _filterPriority,
                                isDense: true,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: ['Todas', 'Alta', 'Média', 'Baixa'].map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (val) => setState(() => _filterPriority = val ?? 'Todas'),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Limpar Filtros
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                          tooltip: 'Limpar Filtros',
                          onPressed: () {
                            setState(() {
                              _filterClient = 'Todos';
                              _filterProject = 'Todos';
                              _filterRole = 'Todos';
                              _filterPriority = 'Todas';
                              _searchQuery = '';
                            });
                          },
                        )
                      ],
                    )
                  : const SizedBox.shrink(),
            );

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    PremiumHeader(
                      title: 'Gestão de Demandas', 
                      subtitle: 'Painel operacional de acompanhamento de vagas.',
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () => _cleanDuplicates(context),
                          icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 20),
                          label: const Text('LIMPAR DUPLICADAS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                        ),
                        const SizedBox(width: 15),
                        OutlinedButton.icon(
                          onPressed: () => _clearActiveDemands(context),
                          icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 20),
                          label: const Text('EXCLUIR ATIVAS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                        ),
                        const SizedBox(width: 15),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await showDialog(
                              context: context, 
                              builder: (context) => const Center(child: CreateDemandModal()),
                            );
                          },
                          icon: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 20),
                          label: const Text('NOVA DEMANDA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue, 
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // TAB SELECTOR (Kanban vs Vínculo & Realocação)
                    _buildTabSelector(),
                    
                    if (_activeTab == 0) ...[
                      // BARRA DE PESQUISA E FILTROS (Kanban)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: const InputDecoration(
                                  hintText: 'Buscar diária por nome, função, cliente ou projeto...',
                                  prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, color: AppColors.textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                            icon: Icon(_filtersExpanded ? IconsaxPlusBold.filter : IconsaxPlusLinear.filter, color: AppColors.primaryBlue, size: 20),
                            label: Text(_filtersExpanded ? 'FECHAR FILTROS' : 'FILTROS AVANÇADOS', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryBlue)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryBlue),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      filterPanel,
                      
                      // KANBAN Columns
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildKanbanColumn('RASCUNHO', countRascunho, AppColors.textSecondary, filteredDemands.where((d) => d.status == 'RASCUNHO').toList()),
                              const SizedBox(width: 20),
                              _buildKanbanColumn('ABERTAS', countAbertas, AppColors.warning, filteredDemands.where((d) => d.status == 'ABERTAS').toList()),
                              const SizedBox(width: 20),
                              _buildKanbanColumn('PREENCHIDAS', countPreenchidas, Colors.purpleAccent, filteredDemands.where((d) => d.status == 'PREENCHIDAS').toList()),
                              const SizedBox(width: 20),
                              _buildKanbanColumn('EM ANDAMENTO', countAndamento, AppColors.primaryBlue, filteredDemands.where((d) => d.status == 'EM ANDAMENTO').toList()),
                              const SizedBox(width: 20),
                              _buildKanbanColumn('FINALIZADAS', countFinalizadas, AppColors.success, filteredDemands.where((d) => d.status == 'FINALIZADAS').toList()),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_activeTab == 1) ...[
                      // VÍNCULO & REALOCAÇÃO Tab Layout
                      if (_selectedDemandForVinculo != null) ...[
                        // Dedicated Vinculo Details Screen (3 columns fullscreen-like, hiding search/horizontal list)
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedDemandForVinculo = null;
                                });
                              },
                              icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
                              label: const Text('VOLTAR PARA LISTA DE LOJAS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryBlue),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Gestão de Vínculo: ${_selectedDemandForVinculo!.storeName} (${_selectedDemandForVinculo!.role})',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quadro Esquerdo: Detalhes da Demanda Selecionada
                              Expanded(
                                flex: 3,
                                child: _buildDemandDetailsColumn(_selectedDemandForVinculo!),
                              ),
                              const SizedBox(width: 16),
                              // Quadro do Meio: Candidatos Inscritos (Numerados)
                              Expanded(
                                flex: 4,
                                child: _buildCandidatesColumn(_selectedDemandForVinculo!, promoterMap),
                              ),
                              const SizedBox(width: 16),
                              // Quadro Direito: Promotores Próximos (Raio até 20km)
                              Expanded(
                                flex: 4,
                                child: _buildNearbyPromotersColumn(_selectedDemandForVinculo!, promoterMap),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // BARRA DE PESQUISA E FILTROS (Vínculo & Realocação)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: TextField(
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar demanda por nome ou cargo...',
                                    prefixIcon: Icon(IconsaxPlusLinear.search_normal_1, color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                              icon: Icon(_filtersExpanded ? IconsaxPlusBold.filter : IconsaxPlusLinear.filter, color: AppColors.primaryBlue, size: 20),
                              label: Text(_filtersExpanded ? 'FECHAR FILTROS' : 'FILTROS AVANÇADOS', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryBlue)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryBlue),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        filterPanel,
                        const SizedBox(height: 12),
                        
                        // Lista Horizontal de Lojas/Demandas
                        _buildHorizontalDemandList(filteredDemands),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _buildEmptyState('Selecione uma demanda na lista acima para iniciar a gestão de vínculo.'),
                        ),
                      ],
                    ] else ...[
                      // Cronograma view
                      if (_selectedDemandForVinculo == null)
                        Expanded(
                          child: Center(
                            child: Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.av_timer_rounded, size: 48, color: AppColors.primaryBlue),
                                    const SizedBox(height: 16),
                                    const Text('Cronograma da Vaga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Selecione uma vaga no Kanban (clicando no ícone do cronômetro)\nou no menu Vínculo & Realocação para visualizar sua cronologia.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () => setState(() => _activeTab = 0),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                                      child: const Text('IR PARA KANBAN', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: VacancyChronology(
                            demand: _selectedDemandForVinculo!,
                            promoterMap: promoterMap,
                          ),
                        ),
                    ],
                  ],
                ),
                
                // FLOAT BAR DE AÇÕES EM MASSA (Somente no Kanban)
                if (_activeTab == 0 && _selectedDemandIds.isNotEmpty)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Card(
                      color: Colors.white,
                      elevation: 12,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder, width: 1.5)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                '${_selectedDemandIds.length} selecionadas',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryBlue, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: () => _bulkChangeStatus(context, allDemands),
                              icon: const Icon(IconsaxPlusLinear.arrow_swap_horizontal, size: 18),
                              label: const Text('ALTERAR STATUS EM MASSA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _bulkUpdateValue(context, allDemands),
                              icon: const Icon(IconsaxPlusLinear.money, size: 18),
                              label: const Text('ATUALIZAR VALOR DA DIÁRIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => _bulkDelete(context),
                              icon: const Icon(IconsaxPlusLinear.trash, size: 18),
                              label: const Text('EXCLUIR EM MASSA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => setState(() => _selectedDemandIds.clear()),
                              child: const Text('CANCELAR SELEÇÃO', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
        );
      }
    );
  }

  // --- VÍNCULO & REALOCAÇÃO HELPER METHODS ---

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton(0, 'Visão Geral / Kanban', IconsaxPlusLinear.kanban),
          _buildTabButton(1, 'Vínculo & Realocação', IconsaxPlusLinear.profile_2user),
          _buildTabButton(2, 'Cronograma da Vaga', IconsaxPlusLinear.routing),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTabSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          _buildSubTabButton(0, 'Candidatos Inscritos'),
          const SizedBox(width: 20),
          _buildSubTabButton(1, 'Promotores Próximos (Raio 15km)'),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String title) {
    final isSelected = _vinculoSubTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _vinculoSubTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDemandVinculoList(List<AppDemand> demands) {
    if (demands.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('Nenhuma demanda encontrada.', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: demands.length,
        itemBuilder: (context, idx) {
          final demand = demands[idx];
          final isSelected = _selectedDemandForVinculo?.id == demand.id;
          final double progress = demand.totalVagas > 0 ? demand.filledVagas / demand.totalVagas : 0;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            color: isSelected ? AppColors.primaryBlue.withOpacity(0.03) : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedDemandForVinculo = demand;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demand.storeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${demand.role} • ${demand.clientName ?? ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${demand.date} • ${demand.timeRange}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${demand.filledVagas}/${demand.totalVagas}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1 ? AppColors.success : AppColors.primaryBlue,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVinculoDetailsPane(AppDemand demand, Map<String, Map<String, dynamic>> promoterMap) {
    final double progress = demand.totalVagas > 0 ? demand.filledVagas / demand.totalVagas : 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Demand info card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        demand.status,
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${demand.filledVagas}/${demand.totalVagas} vagas preenchidas',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  demand.storeName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Endereço: ${demand.address}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoBadge(IconsaxPlusLinear.profile, demand.role),
                    const SizedBox(width: 12),
                    _buildInfoBadge(IconsaxPlusLinear.calendar, demand.date),
                    const SizedBox(width: 12),
                    _buildInfoBadge(IconsaxPlusLinear.timer_1, demand.timeRange),
                    const SizedBox(width: 12),
                    _buildInfoBadge(Icons.attach_money, 'R\$ ${demand.value.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1 ? AppColors.success : AppColors.primaryBlue,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Sub-tabs
        _buildSubTabSelector(),
        
        // Sub-tab content
        Expanded(
          child: SingleChildScrollView(
            child: _vinculoSubTab == 0
                ? _buildCandidatosTab(demand, promoterMap)
                : _buildPromotoresProximosTab(demand, promoterMap),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Map<String, dynamic> getCurriculumData(Map<String, dynamic> userData) {
    try {
      final cvStr = userData['curriculum_completo_dados'] as String?;
      if (cvStr != null && cvStr.isNotEmpty) {
        return jsonDecode(cvStr);
      }
    } catch (_) {}
    return {};
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    const c = math.cos;
    final a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;
    switch (status) {
      case 'inscricao_enviada':
        bg = AppColors.warning.withOpacity(0.1);
        fg = AppColors.warning;
        text = 'Inscrito';
        break;
      case 'tarefa_aprovada':
        bg = AppColors.success.withOpacity(0.1);
        fg = AppColors.success;
        text = 'Vinculado';
        break;
      case 'nao_aprovada':
        bg = AppColors.error.withOpacity(0.1);
        fg = AppColors.error;
        text = 'Recusado';
        break;
      default:
        bg = AppColors.textSecondary.withOpacity(0.1);
        fg = AppColors.textSecondary;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _verDetalhesCurriculo(AppUser promoter) {
    Map<String, dynamic> cv = {};
    if (promoter.curriculumCompletoDados != null) {
      try {
        cv = jsonDecode(promoter.curriculumCompletoDados!);
      } catch (e) {
        // Failed decoding
      }
    }

    final personal = cv['dados_pessoais'] ?? {};
    final docs = cv['documentacao'] ?? {};
    final disp = cv['disponibilidade'] ?? {};
    final prof = cv['dados_profissionais'] ?? {};
    final escolar = cv['escolaridade'] ?? {};
    final redes = cv['redes_flags'] ?? {};
    final trade = cv['trade_flags'] ?? {};
    final marcas = cv['marcas_selecionadas'] as List? ?? [];
    final score = cv['rh_score'] ?? 5.0;
    final feedback = cv['rh_feedback'] ?? 'Sem observações corporativas.';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 900,
            height: 800,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                      child: Text(
                        promoter.name.isNotEmpty ? promoter.name[0].toUpperCase() : 'P',
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promoter.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
                          Text('${promoter.role.isNotEmpty ? promoter.role : 'Prestador'} • ${personal['cidade'] ?? 'Não informado'} - ${personal['estado'] ?? 'SP'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.success, size: 18),
                          const SizedBox(width: 4),
                          Text('Score RH: $score', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppColors.cardBorder),
                
                // Content Tab list
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick highlights
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildModalInfoCard('Resumo Profissional', promoter.curriculumResumo ?? 'Sem resumo cadastrado.'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: _buildModalInfoCard('Contato e Redes', 
                                '📧 ${promoter.email}\n'
                                '📱 ${personal['whatsapp'] ?? 'Não informado'}\n'
                                '🔗 LinkedIn: ${personal['linkedin'] ?? 'Não cadastrado'}\n'
                                '📸 Instagram: ${personal['instagram'] ?? 'Não cadastrado'}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Dados Pessoais & Documentos
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildModalSectionCard('Dados Pessoais', [
                                _buildKeyValue('Nome Social', personal['nome_social'] ?? '-'),
                                _buildKeyValue('Idade', personal['idade'] ?? '-'),
                                _buildKeyValue('Sexo', personal['sexo'] ?? '-'),
                                _buildKeyValue('RG', personal['rg'] ?? '-'),
                                _buildKeyValue('CPF', promoter.id),
                                _buildKeyValue('Endereço', '${personal['rua'] ?? ''}, ${personal['bairro'] ?? ''} - CEP: ${personal['cep'] ?? ''}'),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModalSectionCard('Documentação & Veículo', [
                                _buildKeyValue('CNH Categoria', docs['cnh_categoria'] ?? 'Não possui'),
                                _buildKeyValue('Validade CNH', docs['cnh_validade'] ?? '-'),
                                _buildKeyValue('Veículo Próprio', docs['veiculo_proprio'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Possui Carro', docs['carro'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Possui Moto', docs['moto'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Chave Pix', docs['chave_pix'] ?? '-'),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Profissional & Disponibilidade
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildModalSectionCard('Dados Profissionais', [
                                _buildKeyValue('Cargo Atual', prof['cargo_atual'] ?? '-'),
                                _buildKeyValue('Último Cargo', prof['ultimo_cargo'] ?? '-'),
                                _buildKeyValue('Experiência', prof['tempo_experiencia'] ?? '-'),
                                _buildKeyValue('Pretensão Salarial', prof['pretensao_salarial'] ?? '-'),
                                _buildKeyValue('Escolaridade', escolar['grau'] ?? '-'),
                                _buildKeyValue('Curso/Habilitação', '${escolar['curso'] ?? ''} (${escolar['status'] ?? ''})'),
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModalSectionCard('Disponibilidade de Trabalho', [
                                _buildKeyValue('Horário', disp['horarios'] ?? '-'),
                                _buildKeyValue('Raio Deslocamento', '${disp['raio'] ?? 20} KM'),
                                _buildKeyValue('Disponibilidade Imediata', disp['imediata'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Finais de Semana', disp['finais_semana'] == true ? 'Sim' : 'Não'),
                                _buildKeyValue('Aceita CLT / PJ / Freelancer', '${disp['clt'] == true ? 'CLT ' : ''}${disp['pj'] == true ? 'PJ ' : ''}${disp['freelancer'] == true ? 'Freelancer' : ''}'),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 3: Experiências por Redes, Marcas e Habilidades
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildModalSectionCard('Marcas Preferidas', [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: marcas.map((m) => Chip(
                                    label: Text(m.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                                    backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )).toList(),
                                )
                              ]),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModalSectionCard('Experiência em Redes', [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: redes.entries.where((e) => e.value == true).map((e) => Chip(
                                    label: Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                    backgroundColor: Colors.purple.withOpacity(0.08),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )).toList(),
                                )
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section 4: Experiências Detalhadas & RH Feedback
                        _buildModalInfoCard('Histórico de Experiências Profissionais', promoter.curriculumExperiencias ?? 'Nenhum histórico detalhado inserido.'),
                        const SizedBox(height: 16),
                        _buildModalInfoCard('Avaliação da Agência / RH', feedback),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                const Divider(height: 32, color: AppColors.cardBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      child: const Text('FECHAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSendMessageDialog(context, promoter.id, promoter.name);
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text('ENVIAR MENSAGEM', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSendMessageDialog(BuildContext context, String cpf, String name) {
    final TextEditingController messageController = TextEditingController();
    String selectedTopicId = 'financeiro';
    final List<Map<String, String>> topics = [
      {'id': 'financeiro', 'title': 'Financeiro'},
      {'id': 'operacional', 'title': 'Operacional'},
      {'id': 'rh', 'title': 'Recursos Humanos (RH)'},
      {'id': 'suporte_tecnico', 'title': 'Suporte Técnico'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Enviar Mensagem para $name', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selecione o Canal de Suporte:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTopicId,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: topics.map((t) {
                            return DropdownMenuItem<String>(
                              value: t['id'],
                              child: Text(t['title']!, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedTopicId = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Mensagem:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Digite aqui a mensagem que o prestador receberá em seu painel...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        fillColor: AppColors.background,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = messageController.text.trim();
                    if (text.isEmpty) return;

                    final now = DateTime.now().toIso8601String();
                    final docId = '${cpf}_$selectedTopicId';
                    final topicTitle = topics.firstWhere((t) => t['id'] == selectedTopicId)['title']!;

                    try {
                      // 1. Add to messages subcollection
                      await FirebaseFirestore.instance
                          .collection('support_chats')
                          .doc(docId)
                          .collection('messages')
                          .add({
                        'senderId': 'admin',
                        'senderName': 'Suporte CheckFast',
                        'senderRole': 'admin',
                        'text': text,
                        'createdAt': now,
                        'read': false,
                      });

                      // 2. Set/Update support_chats doc
                      await FirebaseFirestore.instance
                          .collection('support_chats')
                          .doc(docId)
                          .set({
                        'chatId': docId,
                        'promoterCpf': cpf,
                        'promoterName': name,
                        'topic': topicTitle,
                        'lastMessage': text,
                        'lastMessageTime': now,
                        'lastSenderRole': 'admin',
                        'unreadCountPromoter': FieldValue.increment(1),
                        'updatedAt': now,
                      }, SetOptions(merge: true));

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Mensagem enviada com sucesso para $name!'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao enviar mensagem: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ENVIAR MENSAGEM', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModalInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildModalSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$key: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidatosTab(AppDemand demand, Map<String, Map<String, dynamic>> promoterMap) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').where('demandId', isEqualTo: demand.id).snapshots(),
      builder: (context, appSnapshot) {
        if (appSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
        }
        final apps = appSnapshot.data?.docs ?? [];
        if (apps.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                children: [
                  Icon(IconsaxPlusLinear.profile_remove, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text('Nenhum candidato inscrito para esta demanda.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final appDoc = apps[index];
            final appData = appDoc.data() as Map<String, dynamic>;
            final String promoterCpf = appData['promoterCpf'] ?? '';
            final String appStatus = appData['status'] ?? 'inscricao_enviada';
            
            final promoterData = promoterMap[promoterCpf];
            final String name = promoterData?['name'] ?? 'Promotor ($promoterCpf)';
            final cv = promoterData != null ? getCurriculumData(promoterData) : {};
            final String whatsapp = cv['dados_pessoais']?['whatsapp'] ?? '';
            final double userLat = cv['dados_pessoais']?['latitude'] != null ? (cv['dados_pessoais']?['latitude'] as num).toDouble() : 0.0;
            final double userLon = cv['dados_pessoais']?['longitude'] != null ? (cv['dados_pessoais']?['longitude'] as num).toDouble() : 0.0;
            
            double distance = 99999.0;
            if (userLat != 0.0 && userLon != 0.0 && demand.latitude != null && demand.longitude != null && demand.latitude != 0.0 && demand.longitude != 0.0) {
              distance = _calculateDistance(userLat, userLon, demand.latitude!, demand.longitude!);
            }
            
            final String distanceText = distance < 9999 ? '${distance.toStringAsFixed(1)} km de distância da loja' : 'Sem coordenadas de localização';
            
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          final userMap = Map<String, dynamic>.from(promoterData ?? {});
                          userMap['id'] = promoterCpf;
                          userMap['name'] = name;
                          userMap['email'] = promoterData?['email'] ?? '';
                          final promoterObj = AppUser.fromMap(userMap);
                          _verDetalhesCurriculo(promoterObj);
                        },
                        hoverColor: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name, 
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 14, 
                                    color: AppColors.primaryBlue, 
                                    decoration: TextDecoration.underline
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildStatusBadge(appStatus),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(distanceText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            if (whatsapp.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(whatsapp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (appStatus == 'inscricao_enviada') ...[
                      ElevatedButton(
                        onPressed: () => _aprovarInscricao(context, appDoc.id, name, demand),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('APROVAR & VINCULAR'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _recusarInscricao(context, appDoc.id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('RECUSAR'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
                        onPressed: () => _showSendMessageDialog(context, promoterCpf, name),
                        tooltip: 'Enviar Mensagem',
                      ),
                    ] else if (appStatus == 'tarefa_aprovada') ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          SizedBox(width: 6),
                          Text('Vinculado', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text('DESVINCULAR'),
                        onPressed: () => _desvincularPromotor(context, appDoc.id, name, demand),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
                        onPressed: () => _showSendMessageDialog(context, promoterCpf, name),
                        tooltip: 'Enviar Mensagem',
                      ),
                    ] else ...[
                      Text(appStatus.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
                        onPressed: () => _showSendMessageDialog(context, promoterCpf, name),
                        tooltip: 'Enviar Mensagem',
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPromotoresProximosTab(AppDemand demand, Map<String, Map<String, dynamic>> promoterMap) {
    final nearbyPromoters = <Map<String, dynamic>>[];
    final otherPromoters = <Map<String, dynamic>>[];
    
    final hasCoords = demand.latitude != null && demand.longitude != null && demand.latitude != 0.0 && demand.longitude != 0.0;
    
    promoterMap.forEach((cpf, promoter) {
      final name = promoter['name'] ?? '';
      final matchesSearch = name.toLowerCase().contains(_promoterSearchQuery.toLowerCase()) || cpf.contains(_promoterSearchQuery);
      if (!matchesSearch) return;
      
      final cv = getCurriculumData(promoter);
      final double userLat = cv['dados_pessoais']?['latitude'] != null ? (cv['dados_pessoais']?['latitude'] as num).toDouble() : 0.0;
      final double userLon = cv['dados_pessoais']?['longitude'] != null ? (cv['dados_pessoais']?['longitude'] as num).toDouble() : 0.0;
      
      double distance = 99999.0;
      if (hasCoords && userLat != 0.0 && userLon != 0.0) {
        distance = _calculateDistance(userLat, userLon, demand.latitude!, demand.longitude!);
      }
      
      final info = {
        'cpf': cpf,
        'name': name,
        'distance': distance,
        'whatsapp': cv['dados_pessoais']?['whatsapp'] ?? '',
        'hasCoords': userLat != 0.0 && userLon != 0.0,
        'rawData': promoter,
      };
      
      if (hasCoords && distance <= 15.0) {
        nearbyPromoters.add(info);
      } else {
        otherPromoters.add(info);
      }
    });
    
    nearbyPromoters.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    otherPromoters.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (val) => setState(() => _promoterSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Buscar por nome ou CPF do promotor...',
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 20),
        
        if (!hasCoords)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Esta demanda não possui coordenadas de geolocalização válidas para calcular a proximidade. Abaixo estão listados todos os promotores.',
                    style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          
        if (hasCoords) ...[
          const Text(
            'Promotores Próximos (até 15 km)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          if (nearbyPromoters.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nenhum promotor com coordenadas cadastradas num raio de 15 km.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...nearbyPromoters.map((p) => _buildPromoterRow(p, demand, isNearby: true)),
          const SizedBox(height: 24),
        ],
        
        Text(
          hasCoords ? 'Outros Promotores' : 'Lista de Promotores',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (otherPromoters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Nenhum outro promotor encontrado.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ...otherPromoters.map((p) => _buildPromoterRow(p, demand, isNearby: false)),
      ],
    );
  }

  Widget _buildPromoterRow(Map<String, dynamic> p, AppDemand demand, {required bool isNearby}) {
    final String cpf = p['cpf'];
    final String name = p['name'];
    final double distance = p['distance'];
    final String whatsapp = p['whatsapp'];
    final bool hasCoords = p['hasCoords'];
    final promoterData = p['rawData'] as Map<String, dynamic>?;
    
    final distanceText = hasCoords && distance < 9999
        ? '${distance.toStringAsFixed(1)} km de distância'
        : 'Sem localização';
        
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  final userMap = Map<String, dynamic>.from(promoterData ?? {});
                  userMap['id'] = cpf;
                  userMap['name'] = name;
                  userMap['email'] = promoterData?['email'] ?? '';
                  final promoterObj = AppUser.fromMap(userMap);
                  _verDetalhesCurriculo(promoterObj);
                },
                hoverColor: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 14, 
                        color: AppColors.primaryBlue, 
                        decoration: TextDecoration.underline
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: isNearby ? AppColors.success : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: TextStyle(
                            color: isNearby ? AppColors.success : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isNearby ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (whatsapp.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(whatsapp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _forcarVinculo(context, cpf, name, demand),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('FORÇAR VÍNCULO'),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
              onPressed: () => _showSendMessageDialog(context, cpf, name),
              tooltip: 'Enviar Mensagem',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aprovarInscricao(BuildContext context, String applicationId, String promoterName, AppDemand demand) async {
    try {
      // 1. Atualiza status da candidatura para tarefa_aprovada
      await FirebaseFirestore.instance.collection('applications').doc(applicationId).update({
        'status': 'tarefa_aprovada',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 2. Atualiza a demanda: incrementa filledVagas e define assignedPromoter
      final newFilled = demand.filledVagas + 1;
      final newStatus = newFilled >= demand.totalVagas ? 'PREENCHIDAS' : demand.status;
      
      await FirebaseFirestore.instance.collection('demands').doc(demand.id).update({
        'filledVagas': newFilled,
        'assignedPromoter': promoterName,
        'status': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$promoterName vinculado com sucesso!'), backgroundColor: AppColors.success),
      );
      
      setState(() {
        _selectedDemandForVinculo = AppDemand(
          id: demand.id,
          clientId: demand.clientId,
          projectId: demand.projectId,
          storeId: demand.storeId,
          roleId: demand.roleId,
          storeName: demand.storeName,
          network: demand.network,
          address: demand.address,
          role: demand.role,
          distance: demand.distance,
          timeRange: demand.timeRange,
          value: demand.value,
          date: demand.date,
          urgency: demand.urgency,
          status: newStatus,
          assignedPromoter: promoterName,
          clientName: demand.clientName,
          projectName: demand.projectName,
          totalVagas: demand.totalVagas,
          filledVagas: newFilled,
          latitude: demand.latitude,
          longitude: demand.longitude,
          questionnaire: demand.questionnaire,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao vincular promotor: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _recusarInscricao(BuildContext context, String applicationId) async {
    try {
      await FirebaseFirestore.instance.collection('applications').doc(applicationId).update({
        'status': 'nao_aprovada',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscrição recusada.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao recusar inscrição: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _desvincularPromotor(BuildContext context, String applicationId, String promoterName, AppDemand demand) async {
    try {
      // 1. Atualiza status da candidatura de volta para 'inscricao_enviada'
      await FirebaseFirestore.instance.collection('applications').doc(applicationId).update({
        'status': 'inscricao_enviada',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // 2. Decrementa filledVagas na demanda e limpa assignedPromoter
      final newFilled = math.max(0, demand.filledVagas - 1);
      final newStatus = newFilled < demand.totalVagas ? 'ABERTAS' : demand.status;
      
      await FirebaseFirestore.instance.collection('demands').doc(demand.id).update({
        'filledVagas': newFilled,
        'assignedPromoter': null,
        'status': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$promoterName desvinculado com sucesso!'), backgroundColor: AppColors.success),
      );

      setState(() {
        _selectedDemandForVinculo = AppDemand(
          id: demand.id,
          clientId: demand.clientId,
          projectId: demand.projectId,
          storeId: demand.storeId,
          roleId: demand.roleId,
          storeName: demand.storeName,
          network: demand.network,
          address: demand.address,
          role: demand.role,
          distance: demand.distance,
          timeRange: demand.timeRange,
          value: demand.value,
          date: demand.date,
          urgency: demand.urgency,
          status: newStatus,
          assignedPromoter: null,
          clientName: demand.clientName,
          projectName: demand.projectName,
          totalVagas: demand.totalVagas,
          filledVagas: newFilled,
          latitude: demand.latitude,
          longitude: demand.longitude,
          questionnaire: demand.questionnaire,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao desvincular promotor: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _forcarVinculo(BuildContext context, String cpf, String name, AppDemand demand) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // 1. Criar novo documento na coleção applications
      final docRef = FirebaseFirestore.instance.collection('applications').doc();
      await docRef.set({
        'id': docRef.id,
        'promoterCpf': cpf,
        'demandId': demand.id,
        'storeName': demand.storeName,
        'network': demand.network,
        'address': demand.address,
        'role': demand.role,
        'date': demand.date,
        'timeRange': demand.timeRange,
        'value': demand.value,
        'status': 'tarefa_aprovada',
        'submittedAt': now,
        'updatedAt': now,
        'latitude': demand.latitude ?? -23.5275,
        'longitude': demand.longitude ?? -46.6853,
        'questionnaireAnswers': '{}',
      });

      // 2. Atualizar a demanda
      final newFilled = demand.filledVagas + 1;
      final newStatus = newFilled >= demand.totalVagas ? 'PREENCHIDAS' : demand.status;
      
      await FirebaseFirestore.instance.collection('demands').doc(demand.id).update({
        'filledVagas': newFilled,
        'assignedPromoter': name,
        'status': newStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vínculo forçado com sucesso para $name!'), backgroundColor: AppColors.success),
      );

      setState(() {
        _selectedDemandForVinculo = AppDemand(
          id: demand.id,
          clientId: demand.clientId,
          projectId: demand.projectId,
          storeId: demand.storeId,
          roleId: demand.roleId,
          storeName: demand.storeName,
          network: demand.network,
          address: demand.address,
          role: demand.role,
          distance: demand.distance,
          timeRange: demand.timeRange,
          value: demand.value,
          date: demand.date,
          urgency: demand.urgency,
          status: newStatus,
          assignedPromoter: name,
          clientName: demand.clientName,
          projectName: demand.projectName,
          totalVagas: demand.totalVagas,
          filledVagas: newFilled,
          latitude: demand.latitude,
          longitude: demand.longitude,
          questionnaire: demand.questionnaire,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao forçar vínculo: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildKanbanColumn(String title, int count, Color color, List<AppDemand> colDemands) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                child: Text(count.toString(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: colDemands.isEmpty 
            ? Center(child: Text('Nenhuma demanda\npara esta etapa.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)))
            : ListView.builder(
                itemCount: colDemands.length,
                itemBuilder: (context, i) => _buildKanbanCard(colDemands[i]),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(AppDemand demand) {
    double progress = demand.totalVagas > 0 ? demand.filledVagas / demand.totalVagas : 0;
    final isSelected = _selectedDemandIds.contains(demand.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder, width: isSelected ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Clique para editar
          showDialog(
            context: context,
            builder: (context) => Center(child: EditDemandModal(demand: demand)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox de Seleção em Massa + Nome
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedDemandIds.add(demand.id);
                        } else {
                          _selectedDemandIds.remove(demand.id);
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      demand.storeName, 
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (demand.priority == 'Alta')
                    const Icon(IconsaxPlusBold.info_circle, color: AppColors.error, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              Text('${demand.clientName ?? 'S/C'} | ${demand.projectName ?? 'S/P'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(IconsaxPlusLinear.profile, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 8),
                  Text(demand.role, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${demand.filledVagas}/${demand.totalVagas}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(progress == 1 ? AppColors.success : AppColors.primaryBlue),
                  minHeight: 6,
                ),
              ),
              if (demand.assignedPromoter != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(radius: 10, backgroundColor: AppColors.background, child: Icon(Icons.person, size: 12, color: AppColors.primaryBlue)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        demand.assignedPromoter!,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.av_timer_rounded, color: AppColors.primaryBlue, size: 18),
                      tooltip: 'Ver Cronograma da Vaga',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _selectedDemandForVinculo = demand;
                          _activeTab = 2;
                        });
                      },
                    ),
                  ],
                )
              ] else ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.av_timer_rounded, color: AppColors.primaryBlue, size: 18),
                      tooltip: 'Ver Cronograma da Vaga',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _selectedDemandForVinculo = demand;
                          _activeTab = 2;
                        });
                      },
                    ),
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalDemandList(List<AppDemand> demands) {
    if (demands.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Text('Nenhuma demanda encontrada.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SizedBox(
      height: 140,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Scrollbar(
          controller: _horizontalDemandScrollController,
          thumbVisibility: true,
          child: ListView.builder(
            controller: _horizontalDemandScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: demands.length,
            itemBuilder: (context, idx) {
              final demand = demands[idx];
              final isSelected = _selectedDemandForVinculo?.id == demand.id;
              final double progress = demand.totalVagas > 0 ? demand.filledVagas / demand.totalVagas : 0;
              return Container(
                width: 310,
                margin: const EdgeInsets.only(right: 14, bottom: 12, top: 4),
                child: Card(
                  elevation: isSelected ? 4 : 0,
                  shadowColor: AppColors.primaryBlue.withOpacity(0.1),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  color: isSelected ? AppColors.primaryBlue.withOpacity(0.04) : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDemandForVinculo = demand;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            demand.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${demand.role} • ${demand.clientName ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${demand.date}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${demand.filledVagas}/${demand.totalVagas} vagas',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress == 1 ? AppColors.success : AppColors.primaryBlue,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(IconsaxPlusLinear.profile_2user, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemandDetailsColumn(AppDemand demand) {
    final double progress = demand.totalVagas > 0 ? demand.filledVagas / demand.totalVagas : 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DETALHES DA DEMANDA',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primaryBlue, letterSpacing: 0.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                demand.status,
                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              demand.storeName,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Cliente: ${demand.clientName ?? 'Não informado'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 12),
            _buildDetailItem(IconsaxPlusLinear.map, 'Endereço', demand.address),
            _buildDetailItem(IconsaxPlusLinear.profile, 'Função/Cargo', demand.role),
            _buildDetailItem(IconsaxPlusLinear.calendar, 'Data', demand.date),
            _buildDetailItem(IconsaxPlusLinear.timer_1, 'Horário', demand.timeRange),
            _buildDetailItem(Icons.attach_money, 'Valor Diária', 'R\$ ${demand.value.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vagas preenchidas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                ),
                Text(
                  '${demand.filledVagas}/${demand.totalVagas}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress == 1 ? AppColors.success : AppColors.primaryBlue,
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCandidatesColumn(AppDemand demand, Map<String, Map<String, dynamic>> promoterMap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CANDIDATOS INSCRITOS',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primaryBlue, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('applications').where('demandId', isEqualTo: demand.id).snapshots(),
              builder: (context, appSnapshot) {
                if (appSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                }
                final apps = appSnapshot.data?.docs ?? [];
                if (apps.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IconsaxPlusLinear.profile_remove, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('Nenhum candidato inscrito.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final appDoc = apps[index];
                    final appData = appDoc.data() as Map<String, dynamic>;
                    final String promoterCpf = appData['promoterCpf'] ?? '';
                    final String appStatus = appData['status'] ?? 'inscricao_enviada';
                    
                    final promoterData = promoterMap[promoterCpf];
                    final String name = promoterData?['name'] ?? 'Promotor ($promoterCpf)';
                    final cv = promoterData != null ? getCurriculumData(promoterData) : {};
                    final String whatsapp = cv['dados_pessoais']?['whatsapp'] ?? '';
                    
                    // Prioritize root fields
                    final String city = promoterData?['address_city'] ?? promoterData?['address_cidade'] ?? cv['dados_pessoais']?['cidade'] ?? '';
                    final String state = promoterData?['address_uf'] ?? cv['dados_pessoais']?['estado'] ?? 'SP';
                    
                    final double userLat = cv['dados_pessoais']?['latitude'] != null ? (cv['dados_pessoais']?['latitude'] as num).toDouble() : 0.0;
                    final double userLon = cv['dados_pessoais']?['longitude'] != null ? (cv['dados_pessoais']?['longitude'] as num).toDouble() : 0.0;
                    
                    double distance = 99999.0;
                    if (userLat != 0.0 && userLon != 0.0 && demand.latitude != null && demand.longitude != null && demand.latitude != 0.0 && demand.longitude != 0.0) {
                      distance = _calculateDistance(userLat, userLon, demand.latitude!, demand.longitude!);
                    }
                    
                    final String distanceText = distance < 9999 ? '${distance.toStringAsFixed(1)} km' : 'Sem local';
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Numbered circle badge
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          final userMap = Map<String, dynamic>.from(promoterData ?? {});
                                          userMap['id'] = promoterCpf;
                                          userMap['name'] = name;
                                          userMap['email'] = promoterData?['email'] ?? '';
                                          final promoterObj = AppUser.fromMap(userMap);
                                          _verDetalhesCurriculo(promoterObj);
                                        },
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.primaryBlue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📍 ${city.isNotEmpty ? city : 'Guarulhos'} - $state',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 2),
                                          Text(distanceText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                          if (whatsapp.isNotEmpty) ...[
                                            const SizedBox(width: 10),
                                            const Icon(Icons.phone_outlined, size: 12, color: AppColors.textSecondary),
                                            const SizedBox(width: 2),
                                            Text(whatsapp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(appStatus),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue, size: 18),
                                  onPressed: () => _showSendMessageDialog(context, promoterCpf, name),
                                  tooltip: 'Enviar Mensagem',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 12),
                                if (appStatus == 'inscricao_enviada') ...[
                                  ElevatedButton(
                                    onPressed: () => _aprovarInscricao(context, appDoc.id, name, demand),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('APROVAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _recusarInscricao(context, appDoc.id),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error),
                                      foregroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('RECUSAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ] else if (appStatus == 'tarefa_aprovada') ...[
                                  OutlinedButton(
                                    onPressed: () => _desvincularPromotor(context, appDoc.id, name, demand),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error),
                                      foregroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    child: const Text('DESVINCULAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPromotersColumn(AppDemand demand, Map<String, Map<String, dynamic>> promoterMap) {
    final nearbyPromoters = <Map<String, dynamic>>[];
    final otherPromoters = <Map<String, dynamic>>[];
    
    final hasCoords = demand.latitude != null && demand.longitude != null && demand.latitude != 0.0 && demand.longitude != 0.0;
    
    promoterMap.forEach((cpf, promoter) {
      final name = promoter['name'] ?? '';
      final matchesSearch = name.toLowerCase().contains(_promoterSearchQuery.toLowerCase()) || cpf.contains(_promoterSearchQuery);
      if (!matchesSearch) return;
      
      final cv = getCurriculumData(promoter);
      final double userLat = cv['dados_pessoais']?['latitude'] != null ? (cv['dados_pessoais']?['latitude'] as num).toDouble() : 0.0;
      final double userLon = cv['dados_pessoais']?['longitude'] != null ? (cv['dados_pessoais']?['longitude'] as num).toDouble() : 0.0;
      
      double distance = 99999.0;
      if (hasCoords && userLat != 0.0 && userLon != 0.0) {
        distance = _calculateDistance(userLat, userLon, demand.latitude!, demand.longitude!);
      }
      
      final info = {
        'cpf': cpf,
        'name': name,
        'distance': distance,
        'whatsapp': cv['dados_pessoais']?['whatsapp'] ?? '',
        'hasCoords': userLat != 0.0 && userLon != 0.0,
        'rawData': promoter,
      };
      
      if (hasCoords && distance <= 20.0) {
        nearbyPromoters.add(info);
      } else {
        otherPromoters.add(info);
      }
    });
    
    nearbyPromoters.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    otherPromoters.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PROMOTORES PRÓXIMOS (ATÉ 20KM)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primaryBlue, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${nearbyPromoters.length} perto',
                  style: const TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search input
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _promoterSearchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou CPF...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!hasCoords)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demanda sem coordenadas válidas. Listando todos os promotores.',
                      style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                if (hasCoords) ...[
                  if (nearbyPromoters.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Nenhum promotor num raio de 30 km.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...nearbyPromoters.map((p) => _buildPromoterCard(p, demand, isNearby: true)),
                  const SizedBox(height: 16),
                  const Text(
                    'OUTROS PROMOTORES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                ],
                if (otherPromoters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Nenhum outro promotor encontrado.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...otherPromoters.map((p) => _buildPromoterCard(p, demand, isNearby: false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoterCard(Map<String, dynamic> p, AppDemand demand, {required bool isNearby}) {
    final String cpf = p['cpf'];
    final String name = p['name'];
    final double distance = p['distance'];
    final String whatsapp = p['whatsapp'];
    final bool hasCoords = p['hasCoords'];
    final promoterData = p['rawData'] as Map<String, dynamic>?;
    
    // Prioritize root fields
    final String city = promoterData?['address_city'] ?? promoterData?['address_cidade'] ?? '';
    final String state = promoterData?['address_uf'] ?? 'SP';
    
    final distanceText = hasCoords && distance < 9999
        ? '${distance.toStringAsFixed(1)} km'
        : 'Sem local';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          final userMap = Map<String, dynamic>.from(promoterData ?? {});
                          userMap['id'] = cpf;
                          userMap['name'] = name;
                          userMap['email'] = promoterData?['email'] ?? '';
                          final promoterObj = AppUser.fromMap(userMap);
                          _verDetalhesCurriculo(promoterObj);
                        },
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primaryBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${city.isNotEmpty ? city : 'Guarulhos'} - $state',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: isNearby ? AppColors.success : AppColors.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            distanceText,
                            style: TextStyle(
                              color: isNearby ? AppColors.success : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isNearby ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (whatsapp.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.phone_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text(whatsapp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue, size: 18),
                  onPressed: () => _showSendMessageDialog(context, cpf, name),
                  tooltip: 'Enviar Mensagem',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _forcarVinculo(context, cpf, name, demand),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('FORÇAR VÍNCULO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}

// ================= EDIT DEMAND MODAL =================
class EditDemandModal extends StatefulWidget {
  final AppDemand demand;
  const EditDemandModal({super.key, required this.demand});

  @override
  State<EditDemandModal> createState() => _EditDemandModalState();
}

class QuestionControllerGroup {
  final TextEditingController sectionController;
  final TextEditingController textController;
  String curriculumMapping;
  final List<TextEditingController> optionControllers;
  final List<TextEditingController> pointControllers;

  QuestionControllerGroup({
    required this.sectionController,
    required this.textController,
    required this.curriculumMapping,
    required this.optionControllers,
    required this.pointControllers,
  });

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> options = [];
    for (int i = 0; i < optionControllers.length; i++) {
      options.add({
        'text': optionControllers[i].text,
        'points': int.tryParse(pointControllers[i].text) ?? 0,
      });
    }
    return {
      'sectionTitle': sectionController.text,
      'questionText': textController.text,
      'responseType': 'Dropdown',
      'curriculumMapping': curriculumMapping,
      'options': options,
    };
  }

  void dispose() {
    sectionController.dispose();
    textController.dispose();
    for (var c in optionControllers) {
      c.dispose();
    }
    for (var c in pointControllers) {
      c.dispose();
    }
  }
}

class _EditDemandModalState extends State<EditDemandModal> {
  final _api = RegisterService();

  late final TextEditingController _storeNameController;
  late final TextEditingController _roleController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _projectNameController;
  late final TextEditingController _valueController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeRangeController;
  late final TextEditingController _totalVagasController;
  late final TextEditingController _filledVagasController;
  late final TextEditingController _promoterController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _activityController;
  late final TextEditingController _stepByStepController;
  late final TextEditingController _dressController;
  late final TextEditingController _docsController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late String _status;
  late String _priority;
  late double _maxPromoterDistance;
  List<QuestionControllerGroup> _questionnaireControllers = [];

  final List<String> _mappingOptions = [
    'Nenhum',
    'documentacao/mei',
    'documentacao/veiculo_proprio',
    'disponibilidade/imediata',
    'disponibilidade/finais_semana',
    'disponibilidade/viagens',
    'trade_flags/Reposição',
    'trade_flags/Degustação',
    'trade_flags/Abordagem',
    'trade_flags/Auditoria',
    'trade_flags/Pesquisa',
  ];

  void _initQuestionnaire(List<dynamic> initialData) {
    for (var qc in _questionnaireControllers) {
      qc.dispose();
    }
    _questionnaireControllers = [];
    for (var q in initialData) {
      final opts = q['options'] as List? ?? [];
      List<TextEditingController> optConts = [];
      List<TextEditingController> ptConts = [];
      for (var o in opts) {
        optConts.add(TextEditingController(text: o['text']?.toString() ?? ''));
        ptConts.add(TextEditingController(text: o['points']?.toString() ?? '0'));
      }
      _questionnaireControllers.add(QuestionControllerGroup(
        sectionController: TextEditingController(text: q['sectionTitle']?.toString() ?? ''),
        textController: TextEditingController(text: q['questionText']?.toString() ?? ''),
        curriculumMapping: q['curriculumMapping']?.toString() ?? 'Nenhum',
        optionControllers: optConts,
        pointControllers: ptConts,
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    final d = widget.demand;
    _storeNameController = TextEditingController(text: d.storeName);
    _roleController = TextEditingController(text: d.role);
    _clientNameController = TextEditingController(text: d.clientName ?? '');
    _projectNameController = TextEditingController(text: d.projectName ?? '');
    _valueController = TextEditingController(text: d.value.toStringAsFixed(2));
    _dateController = TextEditingController(text: d.date);
    _timeRangeController = TextEditingController(text: d.timeRange);
    _totalVagasController = TextEditingController(text: d.totalVagas.toString());
    _filledVagasController = TextEditingController(text: d.filledVagas.toString());
    _promoterController = TextEditingController(text: d.assignedPromoter ?? '');
    _instructionsController = TextEditingController(text: d.instructions ?? '');
    _activityController = TextEditingController(text: d.requiredActivity ?? '');
    _stepByStepController = TextEditingController(text: d.stepByStep ?? '');
    _dressController = TextEditingController(text: d.dressCode ?? '');
    _docsController = TextEditingController(text: d.requiredDocuments ?? '');
    _latController = TextEditingController(text: d.latitude?.toString() ?? '0.0');
    _lngController = TextEditingController(text: d.longitude?.toString() ?? '0.0');

    _status = d.status;
    _priority = d.priority;
    _maxPromoterDistance = d.maxPromoterDistance;
    _initQuestionnaire(d.questionnaire);
  }

  @override
  void dispose() {
    for (var qc in _questionnaireControllers) {
      qc.dispose();
    }
    _storeNameController.dispose();
    _roleController.dispose();
    _clientNameController.dispose();
    _projectNameController.dispose();
    _valueController.dispose();
    _dateController.dispose();
    _timeRangeController.dispose();
    _totalVagasController.dispose();
    _filledVagasController.dispose();
    _promoterController.dispose();
    _instructionsController.dispose();
    _activityController.dispose();
    _stepByStepController.dispose();
    _dressController.dispose();
    _docsController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      final updated = AppDemand(
        id: widget.demand.id,
        clientId: widget.demand.clientId,
        projectId: widget.demand.projectId,
        storeId: widget.demand.storeId,
        roleId: widget.demand.roleId,
        storeName: _storeNameController.text,
        network: widget.demand.network,
        address: widget.demand.address,
        role: _roleController.text,
        distance: widget.demand.distance,
        timeRange: _timeRangeController.text,
        value: double.tryParse(_valueController.text.replaceAll(',', '.')) ?? widget.demand.value,
        date: _dateController.text,
        urgency: widget.demand.urgency,
        status: _status,
        assignedPromoter: _promoterController.text.isEmpty ? null : _promoterController.text,
        clientName: _clientNameController.text.isEmpty ? null : _clientNameController.text,
        projectName: _projectNameController.text.isEmpty ? null : _projectNameController.text,
        totalVagas: int.tryParse(_totalVagasController.text) ?? widget.demand.totalVagas,
        filledVagas: int.tryParse(_filledVagasController.text) ?? widget.demand.filledVagas,
        entryTime: widget.demand.entryTime,
        exitTime: widget.demand.exitTime,
        requiresCheckIn: widget.demand.requiresCheckIn,
        requiresCheckOut: widget.demand.requiresCheckOut,
        requiresPhoto: widget.demand.requiresPhoto,
        requiresLocation: widget.demand.requiresLocation,
        allowedRadius: widget.demand.allowedRadius,
        maxPromoterDistance: _maxPromoterDistance,
        instructions: _instructionsController.text,
        priority: _priority,
        questionnaire: const [],
        requiredActivity: _activityController.text,
        stepByStep: _stepByStepController.text,
        minTime: widget.demand.minTime,
        dressCode: _dressController.text,
        requiredDocuments: _docsController.text,
        latitude: double.tryParse(_latController.text) ?? widget.demand.latitude,
        longitude: double.tryParse(_lngController.text) ?? widget.demand.longitude,
      );

      await _api.saveDemand(updated);
      
      if (mounted) {
        Navigator.pop(context); // fecha loading
        Navigator.pop(context); // fecha modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demanda atualizada com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar alterações: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteDemand() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Excluir Demanda', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text('Tem certeza que deseja excluir esta demanda definitivamente? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.error)),
    );

    try {
      await _api.deleteDemand(widget.demand.id);
      if (mounted) {
        Navigator.pop(context); // fecha loading
        Navigator.pop(context); // fecha modal de edição
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demanda excluída com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 800,
        height: 650,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EDITAR DETALHES DA DEMANDA', style: TextStyle(color: AppColors.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('ID: ${widget.demand.id}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            // Scrollable Content Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔹 IDENTIFICAÇÃO DA VAGA', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Nome do Estabelecimento', _storeNameController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Função / Cargo', _roleController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Cliente', _clientNameController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Projeto', _projectNameController)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('🔹 DATA, VALOR E CONDIÇÕES', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Data (ex: 18/05)', _dateController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Horário (ex: 08:00 - 17:00)', _timeRangeController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Valor Diária (R\$)', _valueController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Total de Vagas', _totalVagasController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Vagas Preenchidas', _filledVagasController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Promotor Vinculado', _promoterController)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS DA VAGA', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _status,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                items: ['RASCUNHO', 'ABERTAS', 'PREENCHIDAS', 'EM ANDAMENTO', 'FINALIZADAS'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                onChanged: (val) => setState(() => _status = val ?? 'ABERTAS'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PRIORIDADE', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _priority,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                items: ['Alta', 'Média', 'Baixa'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                onChanged: (val) => setState(() => _priority = val ?? 'Média'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DISTÂNCIA MÁX. PRESTADOR', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<double>(
                                value: _maxPromoterDistance,
                                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                items: const [
                                  DropdownMenuItem(value: 10.0, child: Text('Até 10 km')),
                                  DropdownMenuItem(value: 15.0, child: Text('Até 15 km')),
                                  DropdownMenuItem(value: 20.0, child: Text('Até 20 km')),
                                  DropdownMenuItem(value: 50.0, child: Text('Até 50 km')),
                                  DropdownMenuItem(value: 99999.0, child: Text('Sem limite')),
                                ],
                                onChanged: (val) => setState(() => _maxPromoterDistance = val ?? 99999.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('🔹 INSTRUÇÕES E ATIVIDADES DO PRESTADOR', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField('Instruções Gerais', _instructionsController, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField('Atividade Requerida', _activityController, maxLines: 2),
                    const SizedBox(height: 16),
                    _buildTextField('Passo a Passo da Operação', _stepByStepController, maxLines: 3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Código de Vestimenta (Dresscode)', _dressController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Documentos Exigidos', _docsController)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('🔹 GEOLOCALIZAÇÃO DO ESTABELECIMENTO (COORDENADAS)', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Latitude', _latController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Longitude', _lngController)),
                      ],
                    ),
                    const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            
            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _deleteDemand,
                    icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 18),
                    label: const Text('EXCLUIR VAGA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

}

class VacancyChronology extends StatefulWidget {
  final AppDemand demand;
  final Map<String, Map<String, dynamic>> promoterMap;

  const VacancyChronology({
    super.key,
    required this.demand,
    required this.promoterMap,
  });

  @override
  State<VacancyChronology> createState() => _VacancyChronologyState();
}

class _VacancyChronologyState extends State<VacancyChronology> {
  int _selectedStep = 1;
  final _leftScrollCtrl = ScrollController();
  final _rightScrollCtrl = ScrollController();
  final Set<String> _selectedAppIds = {};

  @override
  void dispose() {
    _leftScrollCtrl.dispose();
    _rightScrollCtrl.dispose();
    super.dispose();
  }

  void _printLetterFromData(Map<String, dynamic> letter) {
    final String formattedDate = DateFormat("dd/MM/yyyy").format(DateTime.now());
    final String title = letter['title'] ?? 'CARTA DE APRESENTAÇÃO';
    final String type = letter['type'] ?? 'diarias';
    final String promoterName = letter['promoterName'] ?? '';
    final String promoterCpfFormatted = letter['promoterCpfFormatted'] ?? letter['promoterCpf'] ?? '';
    final String storeName = letter['storeName'] ?? '';
    final String expiresAt = letter['expiresAt'] != null
        ? DateFormat("dd/MM/yyyy").format(DateTime.parse(letter['expiresAt']))
        : '';
    final int validityDays = type == 'treinamento' ? 1 : 3;

    final String printHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title — $promoterName</title>
  <style>
    @media print {
      body {
        margin: 0;
        padding: 1.5cm;
        font-family: Arial, sans-serif;
        color: #000000;
        background-color: #ffffff;
      }
      .no-print {
        display: none;
      }
    }
    body {
      padding: 2cm;
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      line-height: 1.5;
      color: #000000;
    }
    .header-container {
      display: flex;
      justify-content: flex-end;
      margin-bottom: 0.5cm;
    }
    .logo-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      width: 95px;
      height: 95px;
      border: 3.5px solid #E37A24;
      border-radius: 50%;
      font-family: 'Arial Black', Impact, sans-serif;
    }
    .logo-cart {
      color: #E37A24;
      font-size: 20px;
      margin-bottom: 2px;
      line-height: 1;
    }
    .logo-text-1 {
      color: #E37A24;
      font-size: 9px;
      font-weight: 900;
      text-align: center;
      margin: 1px 0;
      letter-spacing: 0.3px;
    }
    .logo-text-2 {
      color: #1A3C70;
      font-size: 6.5px;
      font-weight: 900;
      text-align: center;
      letter-spacing: 0.2px;
    }
    .letter-title {
      text-align: center;
      font-weight: bold;
      font-size: 16px;
      margin-top: 1cm;
      margin-bottom: 1cm;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: #1A3C70;
      border-bottom: 2px solid #E37A24;
      padding-bottom: 8px;
    }
    .recipient {
      margin-bottom: 0.8cm;
      font-size: 14px;
    }
    .recipient p {
      margin: 0;
    }
    .recipient .salutation {
      margin-top: 15px;
    }
    .body-content {
      font-size: 14px;
      text-align: justify;
    }
    .body-content p {
      margin-top: 0;
      margin-bottom: 1.2em;
    }
    .body-content p.indent {
      text-indent: 2.5em;
    }
    .bottom-section {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-top: 1.2cm;
    }
    .date-location {
      font-size: 14px;
      margin-top: 15px;
    }
    .stamp-box {
      border: 2px solid #5d2596;
      padding: 8px 12px;
      width: 250px;
      text-align: center;
      font-family: Arial, sans-serif;
      font-size: 8.5px;
      color: #5d2596;
      border-radius: 3px;
      line-height: 1.3;
    }
    .stamp-box strong {
      font-size: 11px;
      display: block;
      margin-bottom: 4px;
      letter-spacing: 0.5px;
    }
    .signature-area {
      margin-top: 1.8cm;
      text-align: center;
    }
    .signature-line {
      width: 350px;
      border-top: 1.2px solid #000000;
      margin: 0 auto 5px auto;
    }
    .signature-title {
      font-size: 12px;
      text-transform: uppercase;
      font-weight: bold;
      color: #333333;
      line-height: 1.4;
    }
  </style>
</head>
<body>
  <div class="header-container">
    <div class="logo-container">
      <div class="logo-cart">🛒</div>
      <div class="logo-text-1">MEGA PROMO</div>
      <div class="logo-text-2">MERCHANDISING</div>
    </div>
  </div>
  
  <div class="letter-title">
    $title
  </div>

  <div class="recipient">
    <p>Ao</p>
    <p><strong>$storeName</strong></p>
    <p class="salutation">Prezados Senhores,</p>
  </div>
  <div class="body-content">
    <p class="indent">A empresa <strong>MEGA WORLD SERVICOS DE TERCEIRIZACAO E MARKETING LTDA</strong>, vem por meio desta, comunicar que o(a) nosso(a) prestador(a) de serviço autônomo(a) Sr.(a) <strong>$promoterName</strong>, portador(a) do CPF <strong>$promoterCpfFormatted</strong>, está devidamente autorizado(a) e alocado(a) nesta unidade para realizar as atividades de ${type == 'treinamento' ? 'Treinamento Obrigatório Frente de Caixa' : 'Operações de Frente de Caixa / Diárias de Atendimento'}.</p>
    
    <p class="indent"><strong>Informações de Segurança e Treinamento:</strong> Declaramos que o referido prestador participou do treinamento referente ao uso do(s) EPI(s) e às Normas de Segurança do Trabalho, estando ciente do uso obrigatório dos Equipamentos de Proteção Individual, conforme Lei n.º 514, de 22/12/77, artigo 157.</p>
    
    <p class="indent"><strong>Validade do Documento:</strong> Esta carta possui finalidade exclusiva de credenciamento operacional e tem validade improrrogável de <strong>$validityDays dia(s)</strong> a partir da data de emissão, vencendo impreterivelmente em <strong>$expiresAt</strong>.</p>
    
    <p class="indent">Declaramos que o referido autônomo exercerá exclusivamente suas atividades comerciais de forma independente, não possuindo qualquer vínculo empregatício com a empresa de V.S.a., sendo de inteira responsabilidade da MEGA WORLD todos os encargos trabalhistas, previdenciários ou securitários que venham a incidir.</p>
    
    <p>Sendo o que nos apresenta, subscrevemo-nos</p>
    <p>Atenciosamente,</p>
  </div>
  
  <div class="bottom-section">
    <div class="date-location">
      São Paulo, $formattedDate
    </div>
    <div class="stamp-box">
      <strong>60.970.093/0001-09</strong>
      MEGA WORLD SERVIÇOS DE TERCEIRIZAÇÃO E MARKETING LTDA<br><br>
      Endereço: AV MARCOS PENTEADO DE ULHOA RODRIGUES, 939 - TAMBORÉ, BARUERI / SP
    </div>
  </div>
  
  <div class="signature-area">
    <div class="signature-line"></div>
    <div class="signature-title">MEGA WORLD SERVIÇOS DE TERCEIRIZAÇÃO E MARKETING LTDA</div>
  </div>
  
  <script>
    window.onload = function() {
      window.print();
    }
  </script>
</body>
</html>
''';

    final blob = html.Blob([printHtml], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _transitionApplicants(List<QueryDocumentSnapshot> appsToTransition, String targetStatus) async {
    final batch = FirebaseFirestore.instance.batch();
    int newApprovals = 0;

    for (var app in appsToTransition) {
      final appData = app.data() as Map<String, dynamic>;
      final currentStatus = appData['status'] ?? '';
      final String cpf = appData['promoterCpf'] ?? '';

      if (currentStatus != targetStatus) {
        batch.update(app.reference, {'status': targetStatus});
        if (targetStatus == 'aprovado' && currentStatus != 'aprovado' && currentStatus != 'selecionado') {
          newApprovals++;
        }

        final promoter = widget.promoterMap[cpf];
        final promoterName = promoter?['name'] ?? '';
        final promoterCpfFormatted = promoter?['id'] ?? cpf;
        final type = targetStatus == 'treinamento' ? 'treinamento' : 'diarias';

        final letterRef = FirebaseFirestore.instance.collection('letters').doc("${widget.demand.id}_${cpf}_$type");
        batch.set(letterRef, {
          'demandId': widget.demand.id,
          'promoterCpf': cpf,
          'promoterName': promoterName,
          'promoterCpfFormatted': promoterCpfFormatted,
          'storeName': widget.demand.storeName,
          'type': type,
          'title': type == 'treinamento' ? 'CARTA DE APRESENTAÇÃO - TREINAMENTO' : 'CARTA DE APRESENTAÇÃO - DIÁRIAS',
          'createdAt': DateTime.now().toIso8601String(),
          'expiresAt': DateTime.now().add(Duration(days: type == 'treinamento' ? 1 : 3)).toIso8601String(),
        });
      }
    }

    if (newApprovals > 0) {
      final newFilled = (widget.demand.filledVagas + newApprovals).clamp(0, widget.demand.totalVagas);
      final demandStatus = (newFilled >= widget.demand.totalVagas) ? 'PREENCHIDAS' : widget.demand.status;
      batch.update(FirebaseFirestore.instance.collection('demands').doc(widget.demand.id), {
        'filledVagas': newFilled,
        'status': demandStatus,
      });
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('demandId', isEqualTo: widget.demand.id)
          .snapshots(),
      builder: (context, snapshot) {
        final apps = snapshot.data?.docs ?? [];
        final totalApplicants = apps.length;
        
        int bioCount = 0;
        int trainingCompleteCount = 0;
        int approvedCount = 0;

        for (var doc in apps) {
          final data = doc.data() as Map<String, dynamic>;
          final String cpf = data['promoterCpf'] ?? '';
          final status = data['status'] ?? '';
          
          if (status == 'aprovado' || status == 'selecionado') {
            approvedCount++;
          }
          final promoter = widget.promoterMap[cpf];
          if (promoter != null) {
            final cv = promoter['curriculumResumo'] ?? promoter['curriculumCompletoDados'];
            if (cv != null) bioCount++;
            final finishedTraining = promoter['trainingCompleted'] == true || status == 'aprovado';
            if (finishedTraining) trainingCompleteCount++;
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('letters')
              .where('demandId', isEqualTo: widget.demand.id)
              .snapshots(),
          builder: (context, lettersSnapshot) {
            final lettersDocs = lettersSnapshot.data?.docs ?? [];
            final Map<String, Map<String, dynamic>> letterMap = {};
            for (var doc in lettersDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final cpf = data['promoterCpf'] ?? '';
              final type = data['type'] ?? '';
              letterMap["${cpf}_${type}"] = data;
            }

            final steps = [
              _ChronologyStep(
                title: 'Abertura da Vaga',
                subtitle: 'Publicada em ${widget.demand.date}',
                icon: IconsaxPlusLinear.add_square,
                status: _StepStatus.completed,
                details: _buildAberturaDetails(),
              ),
              _ChronologyStep(
                title: 'Captação & Cadastros',
                subtitle: '$totalApplicants candidatos interessados',
                icon: IconsaxPlusLinear.people,
                status: totalApplicants > 0 ? _StepStatus.completed : _StepStatus.active,
                details: _buildCaptacaoDetails(totalApplicants, apps),
              ),
              _ChronologyStep(
                title: 'Carta de Apresentação',
                subtitle: '$bioCount apresentações recebidas',
                icon: IconsaxPlusLinear.document_text,
                status: bioCount > 0 ? _StepStatus.completed : _StepStatus.active,
                details: _buildCartaDetails(bioCount, apps),
              ),
              _ChronologyStep(
                title: 'Treinamento Obrigatório',
                subtitle: '$trainingCompleteCount concluíram o treinamento',
                icon: IconsaxPlusLinear.teacher,
                status: trainingCompleteCount > 0 ? _StepStatus.completed : _StepStatus.active,
                details: _buildTreinamentoDetails(trainingCompleteCount, apps, letterMap),
              ),
              _ChronologyStep(
                title: 'Aptos para Iniciar',
                subtitle: '$approvedCount selecionados na triagem',
                icon: IconsaxPlusLinear.shield_search,
                status: approvedCount == widget.demand.totalVagas && approvedCount > 0
                    ? _StepStatus.completed 
                    : (approvedCount > 0 ? _StepStatus.active : _StepStatus.locked),
                details: _buildAptosDetails(approvedCount, apps, letterMap),
              ),
              _ChronologyStep(
                title: 'Na Loja no Dia',
                subtitle: widget.demand.status == 'EM ANDAMENTO' || widget.demand.status == 'FINALIZADAS'
                    ? 'Check-in validado com sucesso'
                    : 'Aguardando data da diária',
                icon: IconsaxPlusLinear.gps,
                status: widget.demand.status == 'EM ANDAMENTO' || widget.demand.status == 'FINALIZADAS'
                    ? _StepStatus.completed
                    : _StepStatus.locked,
                details: _buildPresencaDetails(apps),
              ),
              _ChronologyStep(
                title: 'Ação Realizada',
                subtitle: widget.demand.status == 'FINALIZADAS'
                    ? 'Relatório final homologado'
                    : 'Aguardando término do serviço',
                icon: IconsaxPlusLinear.task,
                status: widget.demand.status == 'FINALIZADAS' 
                    ? _StepStatus.completed 
                    : _StepStatus.locked,
                details: _buildAcaoDetails(),
              ),
            ];

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 380,
                    child: Scrollbar(
                      controller: _leftScrollCtrl,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _leftScrollCtrl,
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CRONOLOGIA DA VAGA - ${widget.demand.storeName.toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.textPrimary, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Acompanhe o funil de contratação e as etapas logísticas.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: steps.length,
                              itemBuilder: (context, index) {
                                final step = steps[index];
                                final isSelected = _selectedStep == index;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedStep = index;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? AppColors.primaryBlue.withOpacity(0.04) 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected 
                                            ? AppColors.primaryBlue.withOpacity(0.15) 
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _buildStatusBadge(step.status),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                step.title,
                                                style: TextStyle(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                  fontSize: 13,
                                                  color: isSelected 
                                                      ? AppColors.primaryBlue 
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                step.subtitle,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          step.icon,
                                          size: 18,
                                          color: isSelected 
                                              ? AppColors.primaryBlue 
                                              : AppColors.textSecondary.withOpacity(0.6),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Container(width: 1, color: AppColors.cardBorder),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Scrollbar(
                      controller: _rightScrollCtrl,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _rightScrollCtrl,
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Icon(steps[_selectedStep].icon, color: AppColors.primaryBlue),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Detalhes: ${steps[_selectedStep].title}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            steps[_selectedStep].details,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(_StepStatus status) {
    switch (status) {
      case _StepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        );
      case _StepStatus.active:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryBlue, width: 2),
          ),
          child: const Center(
            child: SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
          ),
        );
      case _StepStatus.locked:
      default:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
          child: const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 14),
        );
    }
  }

  Widget _buildAberturaDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Estabelecimento', widget.demand.storeName),
        _buildInfoRow('Função/Cargo', widget.demand.role),
        _buildInfoRow('Cliente parceiro', widget.demand.clientName ?? 'Não especificado'),
        _buildInfoRow('Data da diária', widget.demand.date),
        _buildInfoRow('Horário programado', widget.demand.timeRange),
        _buildInfoRow('Valor da diária', 'R\$ ${widget.demand.value.toStringAsFixed(2)}'),
        _buildInfoRow('Prioridade operacional', widget.demand.priority),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vaga registrada e ativa na nuvem. Candidatos na proximidade já receberam alertas push.',
                  style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptacaoDetails(int total, List<QueryDocumentSnapshot> apps) {
    if (apps.isEmpty) {
      return _buildSubEmptyState('Nenhum candidato interessado nesta vaga até o momento.');
    }

    final allChecked = apps.every((app) => _selectedAppIds.contains(app.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: allChecked,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedAppIds.addAll(apps.map((app) => app.id));
                    } else {
                      _selectedAppIds.clear();
                    }
                  });
                },
              ),
              const Text(
                'Selecionar Todos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _selectedAppIds.isEmpty
                    ? null
                    : () async {
                        final selectedApps = apps.where((app) => _selectedAppIds.contains(app.id)).toList();
                        await _transitionApplicants(selectedApps, 'treinamento');
                        setState(() {
                          _selectedAppIds.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Candidatos enviados para treinamento e cartas de 1 dia geradas.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                icon: const Icon(IconsaxPlusLinear.teacher, size: 14, color: Colors.white),
                label: const Text('ENVIAR PARA TREINAMENTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _selectedAppIds.isEmpty
                    ? null
                    : () async {
                        final selectedApps = apps.where((app) => _selectedAppIds.contains(app.id)).toList();
                        await _transitionApplicants(selectedApps, 'aprovado');
                        setState(() {
                          _selectedAppIds.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Candidatos aprovados direto e cartas de diária de 3 dias geradas.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                icon: const Icon(Icons.verified, size: 14, color: Colors.white),
                label: const Text('APROVAR DIRETO (APTO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final app = apps[index];
            final appData = app.data() as Map<String, dynamic>;
            final String cpf = appData['promoterCpf'] ?? '';
            final String currentStatus = appData['status'] ?? '';
            final isSelected = _selectedAppIds.contains(app.id);

            final promoter = widget.promoterMap[cpf];
            if (promoter == null) return const SizedBox.shrink();

            final String name = promoter['name'] ?? '';
            final bool hasGoldSeal = promoter['trainingCompleted'] == true || promoter['atacadaoExperience'] == true;

            return Card(
              color: Colors.white,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.cardBorder)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedAppIds.add(app.id);
                          } else {
                            _selectedAppIds.remove(app.id);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.background,
                      child: Icon(Icons.person, color: AppColors.primaryBlue, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              if (hasGoldSeal) ...[
                                const SizedBox(width: 6),
                                Tooltip(
                                  message: 'Selo Dourado: Treinamento ou Vivência Atacadão concluído',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      border: Border.all(color: Colors.amber[700]!, width: 1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.stars, color: Colors.amber[800], size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Selo Dourado',
                                          style: TextStyle(color: Colors.amber[900], fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status atual: ${currentStatus.toUpperCase()}',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: currentStatus == 'treinamento'
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(IconsaxPlusBold.teacher, color: Colors.white, size: 16),
                            )
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(IconsaxPlusLinear.teacher, color: AppColors.primaryBlue, size: 16),
                            ),
                      tooltip: 'Enviar para Treinamento',
                      onPressed: () async {
                        await _transitionApplicants([app], 'treinamento');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name enviado para treinamento (carta de 1 dia gerada).'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: (currentStatus == 'aprovado' || currentStatus == 'selecionado')
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified, color: Colors.white, size: 16),
                            )
                          : Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_outlined, color: AppColors.success, size: 16),
                            ),
                      tooltip: 'Aprovar Direto (Apto)',
                      onPressed: () async {
                        await _transitionApplicants([app], 'aprovado');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name aprovado direto (carta de diárias de 3 dias gerada).'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCartaDetails(int count, List<QueryDocumentSnapshot> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recebimento de Carta de Apresentação ($count)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        if (count == 0)
          _buildSubEmptyState('Nenhuma carta ou resumo de apresentação recebido ainda.')
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final appData = apps[index].data() as Map<String, dynamic>;
                final String cpf = appData['promoterCpf'] ?? '';
                final promoter = widget.promoterMap[cpf];
                if (promoter == null) return const SizedBox.shrink();
                final cv = getCurriculumData(promoter);
                final resumo = promoter['curriculumResumo'] ?? cv['dados_pessoais']?['resumo'] ?? 'Apresentação curta enviada.';

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.cardBorder)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 12, backgroundColor: AppColors.background, child: Icon(Icons.person, size: 12, color: AppColors.primaryBlue)),
                            const SizedBox(width: 10),
                            Text(promoter['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '"$resumo"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTreinamentoDetails(int count, List<QueryDocumentSnapshot> apps, Map<String, Map<String, dynamic>> letterMap) {
    final trainingApps = apps.where((app) {
      final appData = app.data() as Map<String, dynamic>;
      final status = appData['status'] ?? '';
      return status == 'treinamento' || status == 'aprovado' || status == 'selecionado';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Módulos de Treinamento Obrigatório Concluídos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        if (trainingApps.isEmpty)
          _buildSubEmptyState('Nenhum candidato em treinamento ou aprovado.')
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: trainingApps.length,
              itemBuilder: (context, index) {
                final app = trainingApps[index];
                final appData = app.data() as Map<String, dynamic>;
                final String cpf = appData['promoterCpf'] ?? '';
                final promoter = widget.promoterMap[cpf];
                if (promoter == null) return const SizedBox.shrink();
                final isComplete = promoter['trainingCompleted'] == true || appData['status'] == 'aprovado';

                final letter = letterMap["${cpf}_treinamento"];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(promoter['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  isComplete ? '100% Concluído' : '0% - Pendente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isComplete ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: isComplete ? AppColors.success : AppColors.warning,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (letter != null)
                        ElevatedButton.icon(
                          onPressed: () => _printLetterFromData(letter),
                          icon: const Icon(Icons.print, size: 14, color: Colors.white),
                          label: const Text('IMPRIMIR CARTA', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, elevation: 0),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAptosDetails(int approvedCount, List<QueryDocumentSnapshot> apps, Map<String, Map<String, dynamic>> letterMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prestadores Selecionados para Iniciar a Ação',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        if (approvedCount == 0)
          _buildSubEmptyState('Nenhum candidato aprovado ou alocado nesta vaga ainda.')
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final appData = apps[index].data() as Map<String, dynamic>;
                final String cpf = appData['promoterCpf'] ?? '';
                final promoter = widget.promoterMap[cpf];
                if (promoter == null) return const SizedBox.shrink();
                final isApproved = appData['status'] == 'aprovado' || appData['status'] == 'selecionado';
                if (!isApproved) return const SizedBox.shrink();

                final letter = letterMap["${cpf}_diarias"];

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.primaryBlue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promoter['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: const Text('ALOCADO', style: TextStyle(color: AppColors.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        if (letter != null)
                          ElevatedButton.icon(
                            onPressed: () => _printLetterFromData(letter),
                            icon: const Icon(Icons.print, size: 14, color: Colors.white),
                            label: const Text('IMPRIMIR CARTA', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, elevation: 0),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPresencaDetails(List<QueryDocumentSnapshot> apps) {
    final linkedApps = apps.where((app) {
      final appData = app.data() as Map<String, dynamic>;
      final status = appData['status'] ?? '';
      final checkInTime = appData['checkInTime'] ?? '';
      return status == 'aprovado' || status == 'selecionado' || status == 'em_andamento' || status == 'em_analise' || checkInTime.toString().isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Check-in Exigido', widget.demand.requiresCheckIn == false ? 'Não' : 'Sim'),
        _buildInfoRow('Raio de tolerância GPS', '${widget.demand.allowedRadius ?? 200} metros'),
        _buildInfoRow('Exigência de Foto da fachada', widget.demand.requiresPhoto == false ? 'Não' : 'Sim'),
        const SizedBox(height: 24),
        const Text(
          'Registro de Presença em Tempo Real',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        if (linkedApps.isEmpty)
          _buildSubEmptyState('Nenhum promotor alocado ou presente nesta vaga ainda.')
        else
          SizedBox(
            height: 350,
            child: ListView.builder(
              itemCount: linkedApps.length,
              itemBuilder: (context, index) {
                final appData = linkedApps[index].data() as Map<String, dynamic>;
                final String cpf = appData['promoterCpf'] ?? '';
                final promoter = widget.promoterMap[cpf];
                if (promoter == null) return const SizedBox.shrink();

                final checkInTime = appData['checkInTime'] ?? '';
                final checkOutTime = appData['checkOutTime'] ?? '';
                final status = appData['status'] ?? '';

                Color statusColor;
                String statusText;
                IconData statusIcon;

                if (checkOutTime.toString().isNotEmpty) {
                  statusColor = Colors.blue;
                  statusText = 'Checkout Realizado';
                  statusIcon = Icons.logout;
                } else if (checkInTime.toString().isNotEmpty || status == 'em_andamento') {
                  statusColor = Colors.green;
                  statusText = 'Em Loja (Checked-in)';
                  statusIcon = Icons.login;
                } else {
                  statusColor = Colors.red;
                  statusText = 'Check-in Pendente';
                  statusIcon = Icons.timer_outlined;
                }

                String formattedCheckIn = '';
                if (checkInTime.toString().isNotEmpty) {
                  try {
                    formattedCheckIn = DateFormat("HH:mm").format(DateTime.parse(checkInTime));
                  } catch (_) {
                    formattedCheckIn = checkInTime.toString();
                  }
                }

                String formattedCheckOut = '';
                if (checkOutTime.toString().isNotEmpty) {
                  try {
                    formattedCheckOut = DateFormat("HH:mm").format(DateTime.parse(checkOutTime));
                  } catch (_) {
                    formattedCheckOut = checkOutTime.toString();
                  }
                }

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.cardBorder)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promoter['name'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (formattedCheckIn.isNotEmpty)
                              Text('Check-in: $formattedCheckIn', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            if (formattedCheckOut.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('Check-out: $formattedCheckOut', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAcaoDetails() {
    final hasReport = widget.demand.status == 'FINALIZADAS';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Instruções de Execução', widget.demand.instructions ?? 'Padrão de reposição'),
        _buildInfoRow('Atividades obrigatórias', widget.demand.requiredActivity ?? 'Registro fotográfico das gôndolas'),
        const SizedBox(height: 24),
        const Text(
          'Status do Relatório de Campo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        if (hasReport)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    const Text('AÇÃO HOMOLOGADA & FINALIZADA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'O promotor alocado concluiu as atividades obrigatórias, preencheu a pesquisa de campo e realizou o check-out. O saldo foi liberado para pagamento e a demanda está finalizada.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4),
                ),
              ],
            ),
          )
        else ...[
          _buildSubEmptyState('Aguardando a conclusão dos serviços na loja ou homologação.'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
              );
              try {
                await FirebaseFirestore.instance
                    .collection('demands')
                    .doc(widget.demand.id)
                    .update({'status': 'FINALIZADAS'});
                if (context.mounted) {
                  Navigator.pop(context); // Fechar loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demanda finalizada com sucesso!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao finalizar demanda: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
            label: const Text('FINALIZAR AÇÃO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubEmptyState(String msg) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        msg,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }

  Map<String, dynamic> getCurriculumData(Map<String, dynamic> promoter) {
    if (promoter['curriculumCompletoDados'] != null) {
      try {
        return jsonDecode(promoter['curriculumCompletoDados'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }
}

class _ChronologyStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final _StepStatus status;
  final Widget details;

  const _ChronologyStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.details,
  });
}

enum _StepStatus { completed, active, locked }

class CustomHistogram extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const CustomHistogram({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    double maxValue = values.isEmpty ? 1.0 : values.reduce(math.max);
    if (maxValue == 0) maxValue = 1.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (idx) {
        final val = values[idx];
        final label = labels[idx];
        final pct = val / maxValue;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              val.toInt().toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 120 * pct,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, Colors.cyanAccent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        );
      }),
    );
  }
}