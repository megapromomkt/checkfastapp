import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';
import '../../models/app_models.dart';
import 'package:excel/excel.dart' as exc;
import 'dart:html' as html;
import 'package:intl/intl.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final _api = RegisterService();

  // Relatório Selecionado
  String _selectedReportType = 'Entrega de EPI';

  // Estados e Listas
  List<AppEPIDelivery> _deliveries = [];
  List<AppEPIDelivery> _filteredDeliveries = [];
  List<AppBandeira> _bandeiras = [];
  List<AppStore> _stores = [];
  
  // Relatório de Demandas
  List<AppDemand> _demands = [];
  List<AppDemand> _filteredDemands = [];
  List<Map<String, dynamic>> _applications = [];
  Map<String, String> _promoterNames = {};
  
  bool _loading = true;

  // Filtros
  String _filterBandeiraId = 'Todas';
  String _filterStoreId = 'Todas';
  String _filterEPI = 'Todos';
  DateTimeRange? _filterDateRange;

  // Lista fixa de EPIs
  final List<String> _epiList = [
    'Bota',
    'Jaleco',
    'Luvas',
    'Óculos de Proteção',
    'Protetor Auricular',
    'Máscara',
    'Capacete',
    'Colete'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final bandeiras = await _api.getBandeiras();
      final stores = await _api.getStores();
      final deliveries = await _api.getEPIDeliveries();
      
      // Load Demands
      final demandsSnapshot = await FirebaseFirestore.instance.collection('demands').get();
      final demands = demandsSnapshot.docs.map((doc) => AppDemand.fromMap(doc.data()..['id'] = doc.id)).toList();

      // Load Applications
      final appsSnapshot = await FirebaseFirestore.instance.collection('applications').get();
      final applications = appsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Load Promoter users to resolve names
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('type', isEqualTo: 'prestador')
          .get();
      final Map<String, String> promoterNames = {};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        promoterNames[doc.id] = data['name'] ?? '';
      }

      setState(() {
        _bandeiras = bandeiras;
        _stores = stores;
        _deliveries = deliveries;
        _demands = demands;
        _applications = applications;
        _promoterNames = promoterNames;
        _applyFilters();
      });
    } catch (e) {
      print('Erro ao carregar relatórios: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDeliveries = _deliveries.where((d) {
        final matchesBandeira = _filterBandeiraId == 'Todas' || d.bandeiraId == _filterBandeiraId;
        final matchesStore = _filterStoreId == 'Todas' || d.storeId == _filterStoreId;
        final matchesEPI = _filterEPI == 'Todos' || d.epi == _filterEPI;
        
        bool matchesDate = true;
        if (_filterDateRange != null) {
          try {
            final date = DateFormat('dd/MM/yyyy').parse(d.deliveryDate);
            matchesDate = date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
                          date.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
          } catch (_) {
            matchesDate = false;
          }
        }
        
        return matchesBandeira && matchesStore && matchesEPI && matchesDate;
      }).toList();

      _filteredDemands = _demands.where((d) {
        final matchesStore = _filterStoreId == 'Todas' || d.storeId == _filterStoreId;
        
        bool matchesBandeira = true;
        if (_filterBandeiraId != 'Todas') {
          final store = _stores.firstWhere((s) => s.id == d.storeId, orElse: () => AppStore(id: '', name: '', clientId: '', bandeiraId: ''));
          matchesBandeira = store.bandeiraId == _filterBandeiraId;
        }

        bool matchesDate = true;
        if (_filterDateRange != null) {
          try {
            final date = DateFormat('dd/MM/yyyy').parse(d.date);
            matchesDate = date.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
                          date.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
          } catch (_) {
            matchesDate = false;
          }
        }

        return matchesStore && matchesBandeira && matchesDate;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _filterBandeiraId = 'Todas';
      _filterStoreId = 'Todas';
      _filterEPI = 'Todos';
      _filterDateRange = null;
      _applyFilters();
    });
  }

  // Ação de exportar XLS usando a biblioteca Excel
  void _exportToXLS() {
    try {
      var excel = exc.Excel.createExcel();
      
      if (_selectedReportType == 'Entrega de EPI') {
        exc.Sheet sheetObject = excel['Entrega de EPI'];
        excel.setDefaultSheet('Entrega de EPI');

        // Adicionar cabeçalho
        sheetObject.appendRow([
          exc.TextCellValue('Bandeira'),
          exc.TextCellValue('Loja'),
          exc.TextCellValue('EPI'),
          exc.TextCellValue('Data da entrega'),
          exc.TextCellValue('Qtd entregue'),
        ]);

        // Adicionar dados
        for (var d in _filteredDeliveries) {
          sheetObject.appendRow([
            exc.TextCellValue(d.bandeiraName),
            exc.TextCellValue(d.storeName),
            exc.TextCellValue(d.epi),
            exc.TextCellValue(d.deliveryDate),
            exc.IntCellValue(d.quantity),
          ]);
        }
      } else if (_selectedReportType == 'Demandas') {
        exc.Sheet sheetObject = excel['Demandas e Prestadores'];
        excel.setDefaultSheet('Demandas e Prestadores');

        // Adicionar cabeçalho
        sheetObject.appendRow([
          exc.TextCellValue('Loja'),
          exc.TextCellValue('Rede/Bandeira'),
          exc.TextCellValue('Cargo/Função'),
          exc.TextCellValue('Data'),
          exc.TextCellValue('Valor Diária'),
          exc.TextCellValue('Total Vagas'),
          exc.TextCellValue('Vagas Preenchidas'),
          exc.TextCellValue('Prestador Vinculado'),
          exc.TextCellValue('CPF do Prestador'),
          exc.TextCellValue('Status do Vínculo'),
        ]);

        // Adicionar dados
        for (var d in _filteredDemands) {
          final demandApps = _applications.where((app) => app['demandId'] == d.id).toList();

          if (demandApps.isEmpty) {
            sheetObject.appendRow([
              exc.TextCellValue(d.storeName),
              exc.TextCellValue(d.network),
              exc.TextCellValue(d.role),
              exc.TextCellValue(d.date),
              exc.DoubleCellValue(d.value),
              exc.IntCellValue(d.totalVagas),
              exc.IntCellValue(d.filledVagas),
              exc.TextCellValue('Nenhum'),
              exc.TextCellValue(''),
              exc.TextCellValue(''),
            ]);
          } else {
            for (var app in demandApps) {
              final cpf = app['promoterCpf'] ?? '';
              final name = _promoterNames[cpf] ?? 'CPF: $cpf';
              final status = app['status'] ?? 'pendente';

              sheetObject.appendRow([
                exc.TextCellValue(d.storeName),
                exc.TextCellValue(d.network),
                exc.TextCellValue(d.role),
                exc.TextCellValue(d.date),
                exc.DoubleCellValue(d.value),
                exc.IntCellValue(d.totalVagas),
                exc.IntCellValue(d.filledVagas),
                exc.TextCellValue(name),
                exc.TextCellValue(cpf),
                exc.TextCellValue(status.toUpperCase()),
              ]);
            }
          }
        }
      }

      // Codificar e descarregar arquivo
      var fileBytes = excel.save();
      if (fileBytes != null) {
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final fileName = _selectedReportType == 'Entrega de EPI'
            ? 'Relatorio_Entrega_EPI_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx'
            : _selectedReportType == 'Demandas'
                ? 'Relatorio_Demandas_e_Prestadores_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx'
                : 'Relatorio_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx';
            
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Relatório exportado em XLS com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar planilha: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _deleteDelivery(AppEPIDelivery delivery) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Deseja excluir a entrega de ${delivery.quantity}x ${delivery.epi} para a loja ${delivery.storeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('EXCLUIR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.deleteEPIDelivery(delivery.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro removido!'), backgroundColor: AppColors.success),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao deletar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumHeader(
              title: 'Central de Relatórios',
              subtitle: 'Extraia informações operacionais da plataforma em tempo real.',
            ),
            const SizedBox(height: 20),
            
            // Seletor de Tipo de Relatório
            _buildReportTypeSelector(),
            const SizedBox(height: 24),
            
            // Corpo dinâmico baseado no tipo selecionado
            Expanded(
              child: _loading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                  : _selectedReportType == 'Entrega de EPI'
                      ? _buildEPIDeliveryReportContent()
                      : _selectedReportType == 'Demandas'
                          ? _buildDemandsReportContent()
                          : _buildUnderConstructionContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.document_text, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 16),
          const Text(
            'Selecione o Relatório:', 
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 15)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedReportType,
                dropdownColor: Colors.white,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: 'Entrega de EPI', child: Text('Relatório de Entrega de EPI')),
                  DropdownMenuItem(value: 'Demandas', child: Text('Relatório de Demandas e Prestadores')),
                  DropdownMenuItem(value: 'Auditoria de Fotos', child: Text('Auditoria de Fotos e Gôndolas (Em breve)')),
                  DropdownMenuItem(value: 'Produtividade de Rotas', child: Text('Produtividade e Rotas de Promotores (Em breve)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedReportType = val;
                      _clearFilters();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderConstructionContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconsaxPlusLinear.timer_1, size: 72, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Este relatório estará disponível em breve.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Estamos preparando novos cruzamentos de dados para você.',
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEPIDeliveryReportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha de Ferramentas (Toolbar)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Entrega de EPI (${_filteredDeliveries.length} registros)',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _exportToXLS,
                  icon: const Icon(IconsaxPlusLinear.document_download, size: 18),
                  label: const Text('Exportar em XLS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddEPIDeliveryDialog,
                  icon: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 18),
                  label: const Text('Incluir Dados', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Seção de Filtros
        _buildEPIDeliveryFilters(),
        const SizedBox(height: 20),
        
        // Tabela Visual
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              children: [
                // Cabeçalhos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('BANDEIRA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 4, child: Text('LOJA / ESTABELECIMENTO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 3, child: Text('EPI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 2, child: Text('DATA DE ENTREGA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 2, child: Text('QTD ENTREGUE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      SizedBox(width: 50), // Coluna para Ações
                    ],
                  ),
                ),
                
                // Registros
                Expanded(
                  child: _filteredDeliveries.isEmpty
                      ? const Center(child: Text('Nenhum registro de EPI encontrado com os filtros atuais.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))
                      : ListView.separated(
                          itemCount: _filteredDeliveries.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.cardBorder),
                          itemBuilder: (context, index) {
                            final d = _filteredDeliveries[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Row(
                                children: [
                                  // Bandeira
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      d.bandeiraName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                                    ),
                                  ),
                                  // Loja
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      d.storeName,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    ),
                                  ),
                                  // EPI Tag
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          d.epi,
                                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Data da entrega
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      d.deliveryDate,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  ),
                                  // Qtd entregue
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${d.quantity} un',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                                    ),
                                  ),
                                  // Ações
                                  SizedBox(
                                    width: 50,
                                    child: IconButton(
                                      icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 18),
                                      onPressed: () => _deleteDelivery(d),
                                      tooltip: 'Excluir registro',
                                    ),
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
    );
  }

  Widget _buildEPIDeliveryFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bandeira Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BANDEIRA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
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
                          value: _filterBandeiraId,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: [
                            const DropdownMenuItem(value: 'Todas', child: Text('Todas as Bandeiras')),
                            ..._bandeiras.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterBandeiraId = val;
                                // Reset store filter if bandeira changes
                                _filterStoreId = 'Todas';
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Loja Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LOJA / ESTABELECIMENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
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
                          value: _filterStoreId,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: [
                            const DropdownMenuItem(value: 'Todas', child: Text('Todas as Lojas')),
                            ..._stores
                                .where((s) => _filterBandeiraId == 'Todas' || s.bandeiraId == _filterBandeiraId)
                                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterStoreId = val;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // EPI Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EPI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
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
                          value: _filterEPI,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: [
                            const DropdownMenuItem(value: 'Todos', child: Text('Todos os EPIs')),
                            ..._epiList.map((epi) => DropdownMenuItem(value: epi, child: Text(epi))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterEPI = val;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Date Range Filter Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PERÍODO DE ENTREGA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showDateRangePicker,
                      icon: const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: AppColors.textPrimary),
                      label: Text(
                        _filterDateRange == null 
                            ? 'Qualquer data' 
                            : '${DateFormat('dd/MM').format(_filterDateRange!.start)} - ${DateFormat('dd/MM').format(_filterDateRange!.end)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_filterBandeiraId != 'Todas' || _filterStoreId != 'Todas' || _filterEPI != 'Todos' || _filterDateRange != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpar Filtros'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
      initialDateRange: _filterDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _filterDateRange = pickedRange;
        _applyFilters();
      });
    }
  }

  // Diálogo para Incluir Dados de EPI
  void _showAddEPIDeliveryDialog() {
    String? dialogBandeiraId;
    String? dialogStoreId;
    String? dialogEPI;
    DateTime dialogDate = DateTime.now();
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filtrar lojas da bandeira selecionada no diálogo
            final filteredStoresForDialog = dialogBandeiraId == null 
                ? <AppStore>[]
                : _stores.where((s) => s.bandeiraId == dialogBandeiraId).toList();

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Registrar Entrega de EPI', 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)
                        ),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Seleção da Bandeira
                    const Text('Bandeira *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
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
                          value: dialogBandeiraId,
                          hint: const Text('Selecione a Bandeira', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: _bandeiras.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              dialogBandeiraId = val;
                              dialogStoreId = null; // reseta a loja
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Seleção da Loja (Reativo à Bandeira)
                    const Text('Loja / Estabelecimento *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: dialogBandeiraId == null ? Colors.grey[100] : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: dialogStoreId,
                          hint: Text(dialogBandeiraId == null ? 'Selecione uma bandeira primeiro' : 'Selecione a Loja', style: const TextStyle(fontSize: 13)),
                          isExpanded: true,
                          disabledHint: const Text('Selecione uma bandeira primeiro', style: TextStyle(fontSize: 13)),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: filteredStoresForDialog.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: dialogBandeiraId == null ? null : (val) {
                            setDialogState(() => dialogStoreId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipo de EPI
                    const Text('Equipamento de Proteção (EPI) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
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
                          value: dialogEPI,
                          hint: const Text('Qual EPI está entregando?', style: TextStyle(fontSize: 13)),
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: _epiList.map((epi) => DropdownMenuItem(value: epi, child: Text(epi))).toList(),
                          onChanged: (val) {
                            setDialogState(() => dialogEPI = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data e Quantidade Lado a Lado
                    Row(
                      children: [
                        // Data de Entrega
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Data da Entrega *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: dialogDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2027),
                                  );
                                  if (pickedDate != null) {
                                    setDialogState(() => dialogDate = pickedDate);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(dialogDate),
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Quantidade Entregue
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Quantidade *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Ações do diálogo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.textSecondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            // Validações
                            if (dialogBandeiraId == null || dialogStoreId == null || dialogEPI == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios (*).'), backgroundColor: AppColors.error),
                              );
                              return;
                            }
                            final qty = int.tryParse(qtyCtrl.text) ?? 0;
                            if (qty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Quantidade deve ser maior que zero.'), backgroundColor: AppColors.error),
                              );
                              return;
                            }

                            // Obter nomes das IDs
                            final bandName = _bandeiras.firstWhere((b) => b.id == dialogBandeiraId).name;
                            final storeName = _stores.firstWhere((s) => s.id == dialogStoreId).name;

                            final newDelivery = AppEPIDelivery(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              bandeiraId: dialogBandeiraId!,
                              bandeiraName: bandName,
                              storeId: dialogStoreId!,
                              storeName: storeName,
                              epi: dialogEPI!,
                              deliveryDate: DateFormat('dd/MM/yyyy').format(dialogDate),
                              quantity: qty,
                            );

                            try {
                              await _api.saveEPIDelivery(newDelivery);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🎉 Entrega de EPI registrada com sucesso!'), backgroundColor: AppColors.success),
                              );
                              _loadData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao salvar no Firestore: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                          child: const Text('SALVAR REGISTRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDemandsReportContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha de Ferramentas (Toolbar)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Demandas e Prestadores (${_filteredDemands.length} demandas)',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            OutlinedButton.icon(
              onPressed: _exportToXLS,
              icon: const Icon(IconsaxPlusLinear.document_download, size: 18),
              label: const Text('Exportar em XLS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Seção de Filtros
        _buildDemandsFilters(),
        const SizedBox(height: 20),
        
        // Tabela Visual
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              children: [
                // Cabeçalhos
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('LOJA / DEMANDA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 2, child: Text('FUNÇÃO / DATA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 2, child: Text('VALOR / VAGAS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                      Expanded(flex: 5, child: Text('PRESTADORES VINCULADOS (STATUS)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5))),
                    ],
                  ),
                ),
                
                // Registros
                Expanded(
                  child: _filteredDemands.isEmpty
                      ? const Center(child: Text('Nenhuma demanda encontrada com os filtros atuais.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))
                      : ListView.separated(
                          itemCount: _filteredDemands.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.cardBorder),
                          itemBuilder: (context, index) {
                            final d = _filteredDemands[index];
                            
                            // Find applications for this demand
                            final demandApps = _applications.where((app) => app['demandId'] == d.id).toList();

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Loja / Demanda
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.storeName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          d.network,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Função / Data
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.role,
                                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          d.date,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Valor / Vagas
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'R\$ ${d.value.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Vagas: ${d.filledVagas}/${d.totalVagas}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Prestadores Vinculados
                                  Expanded(
                                    flex: 5,
                                    child: demandApps.isEmpty
                                        ? const Text(
                                            'Nenhum prestador vinculado',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: demandApps.map((app) {
                                              final cpf = app['promoterCpf'] ?? '';
                                              final name = _promoterNames[cpf] ?? 'CPF: $cpf';
                                              final status = app['status'] ?? 'pendente';
                                              
                                              // Translate/format status
                                              Color statusColor = AppColors.textSecondary;
                                              String statusLabel = status.toUpperCase();
                                              
                                              if (status == 'treinamento') {
                                                statusColor = AppColors.primaryBlue;
                                                statusLabel = 'TREINAMENTO';
                                              } else if (status == 'aprovado' || status == 'selecionado') {
                                                statusColor = AppColors.success;
                                                statusLabel = 'APROVADO';
                                              } else if (status == 'tarefa_aprovada') {
                                                statusColor = Colors.purple;
                                                statusLabel = 'DIÁRIA CONCLUÍDA';
                                              } else if (status == 'rejeitado') {
                                                statusColor = AppColors.error;
                                                statusLabel = 'REJEITADO';
                                              }

                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'Inter'),
                                                          children: [
                                                            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                            const TextSpan(text: ' ('),
                                                            TextSpan(text: statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                                                            const TextSpan(text: ')'),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
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
    );
  }

  Widget _buildDemandsFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Bandeira Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BANDEIRA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
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
                          value: _filterBandeiraId,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: [
                            const DropdownMenuItem(value: 'Todas', child: Text('Todas as Bandeiras')),
                            ..._bandeiras.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterBandeiraId = val;
                                _filterStoreId = 'Todas';
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Loja Filter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LOJA / ESTABELECIMENTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
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
                          value: _filterStoreId,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                          items: [
                            const DropdownMenuItem(value: 'Todas', child: Text('Todas as Lojas')),
                            ..._stores
                                .where((s) => _filterBandeiraId == 'Todas' || s.bandeiraId == _filterBandeiraId)
                                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _filterStoreId = val;
                                _applyFilters();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Date Range Filter Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PERÍODO DA DEMANDA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showDateRangePicker,
                      icon: const Icon(IconsaxPlusLinear.calendar_1, size: 16, color: AppColors.textPrimary),
                      label: Text(
                        _filterDateRange == null 
                            ? 'Qualquer data' 
                            : '${DateFormat('dd/MM').format(_filterDateRange!.start)} - ${DateFormat('dd/MM').format(_filterDateRange!.end)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_filterBandeiraId != 'Todas' || _filterStoreId != 'Todas' || _filterDateRange != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpar Filtros'),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
