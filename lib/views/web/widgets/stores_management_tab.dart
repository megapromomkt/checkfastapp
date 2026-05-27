import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/constants/premium_theme.dart';
import '../../../models/register_models.dart';
import '../../../core/services/register_service.dart';
import 'package:excel/excel.dart' as exc;
import 'dart:html' as html;
import 'dart:typed_data';

class StoresManagementTab extends StatefulWidget {
  final List<AppStore> stores;
  final List<AppRede> redes;
  final List<AppBandeira> bandeiras;
  final Function() onRefresh;

  const StoresManagementTab({
    super.key,
    required this.stores,
    required this.redes,
    required this.bandeiras,
    required this.onRefresh,
  });

  @override
  State<StoresManagementTab> createState() => _StoresManagementTabState();
}

class _StoresManagementTabState extends State<StoresManagementTab> {
  final _api = RegisterService();
  final _searchCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  List<AppStore> _filteredStores = [];
  Set<String> _selectedStoreIds = {};
  
  String _selectedRedeFilter = 'Todas';
  String _selectedBandeiraFilter = 'Todas';
  String _selectedCidadeFilter = 'Todas';
  String _selectedEstadoFilter = 'Todas';

  @override
  void initState() {
    super.initState();
    _filteredStores = widget.stores;
  }

  @override
  void didUpdateWidget(StoresManagementTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stores != oldWidget.stores) {
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStores = widget.stores.where((store) {
        final matchesSearch = store.name.toLowerCase().contains(_searchCtrl.text.toLowerCase());
        final matchesCNPJ = _cnpjCtrl.text.isEmpty || store.cnpj.contains(_cnpjCtrl.text);
        final matchesRede = _selectedRedeFilter == 'Todas' || store.redeId == _selectedRedeFilter;
        final matchesBandeira = _selectedBandeiraFilter == 'Todas' || store.bandeiraId == _selectedBandeiraFilter;
        final matchesCidade = _selectedCidadeFilter == 'Todas' || store.city == _selectedCidadeFilter;
        final matchesEstado = _selectedEstadoFilter == 'Todas' || store.state == _selectedEstadoFilter;
        
        return matchesSearch && matchesCNPJ && matchesRede && matchesBandeira && matchesCidade && matchesEstado;
      }).toList();
    });
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      if (val == true) {
        _selectedStoreIds = _filteredStores.map((e) => e.id).toSet();
      } else {
        _selectedStoreIds.clear();
      }
    });
  }

  void _toggleSelectStore(String id) {
    setState(() {
      if (_selectedStoreIds.contains(id)) {
        _selectedStoreIds.remove(id);
      } else {
        _selectedStoreIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildStoresList(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Lojas / Estabelecimentos (${_filteredStores.length})', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _downloadTemplate,
              icon: const Icon(IconsaxPlusLinear.document_download, size: 18),
              label: const Text('Baixar Modelo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _importExcel,
              icon: const Icon(IconsaxPlusLinear.document_upload, size: 18),
              label: const Text('Importar Excel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 18),
              label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final uniqueCidades = widget.stores.map((e) => e.city).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final uniqueEstados = widget.stores.map((e) => e.state).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final uniqueBandeiras = widget.stores.map((e) => e.bandeiraId).where((e) => e.isNotEmpty).toSet().toList()..sort();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome...',
                  prefixIcon: const Icon(IconsaxPlusLinear.search_normal, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _cnpjCtrl,
                onChanged: (val) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'CNPJ...',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildDropdownFilter('Rede', _selectedRedeFilter, ['Todas', ...widget.redes.map((e) => e.id)], (val) {
              setState(() => _selectedRedeFilter = val!);
              _applyFilters();
            }, labelMapper: (id) => id == 'Todas' ? 'Todas as Redes' : (widget.redes.any((r) => r.id == id) ? widget.redes.firstWhere((r) => r.id == id).name : id)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildDropdownFilter('Bandeira', _selectedBandeiraFilter, ['Todas', ...uniqueBandeiras], (val) {
              setState(() => _selectedBandeiraFilter = val!);
              _applyFilters();
            }),
            const SizedBox(width: 12),
            _buildDropdownFilter('Cidade', _selectedCidadeFilter, ['Todas', ...uniqueCidades], (val) {
              setState(() => _selectedCidadeFilter = val!);
              _applyFilters();
            }),
            const SizedBox(width: 12),
            _buildDropdownFilter('Estado', _selectedEstadoFilter, ['Todas', ...uniqueEstados], (val) {
              setState(() => _selectedEstadoFilter = val!);
              _applyFilters();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, Function(String?) onChanged, {String Function(String)? labelMapper}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(labelMapper != null ? labelMapper(item) : item, style: const TextStyle(fontSize: 13)),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStoresList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _selectedStoreIds.length == _filteredStores.length && _filteredStores.isNotEmpty,
                  onChanged: _toggleSelectAll,
                  activeColor: AppColors.primaryBlue,
                ),
                const SizedBox(width: 16),
                const Expanded(flex: 3, child: Text('NOME / REDE / BANDEIRA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12))),
                const Expanded(flex: 2, child: Text('CNPJ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12))),
                const Expanded(flex: 3, child: Text('ENDEREÇO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12))),
                const Expanded(flex: 2, child: Text('CIDADE / UF', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12))),
                const Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12))),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _filteredStores.isEmpty
              ? const Center(child: Text('Nenhuma loja encontrada.'))
              : ListView.separated(
                  itemCount: _filteredStores.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.cardBorder),
                  itemBuilder: (context, index) {
                    final store = _filteredStores[index];
                    final isSelected = _selectedStoreIds.contains(store.id);
                    
                    // Se não encontrar o objeto de Rede/Bandeira, exibe o ID bruto que veio na planilha
                    final redeObj = widget.redes.cast<AppRede?>().firstWhere((r) => r?.id == store.redeId, orElse: () => null);
                    final redeLabel = redeObj != null ? redeObj.name : (store.redeId.isNotEmpty ? store.redeId : 'Sem Rede');
                    
                    final bandeiraObj = widget.bandeiras.cast<AppBandeira?>().firstWhere((b) => b?.id == store.bandeiraId, orElse: () => null);
                    final bandeiraLabel = bandeiraObj != null ? bandeiraObj.name : (store.bandeiraId.isNotEmpty ? store.bandeiraId : 'Sem Bandeira');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : Colors.transparent,
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (val) => _toggleSelectStore(store.id),
                            activeColor: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                Text('$redeLabel | $bandeiraLabel', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Expanded(flex: 2, child: Text(store.cnpj, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                          Expanded(
                            flex: 3, 
                            child: Text(
                              '${store.logradouro}${store.numero.isNotEmpty ? ", ${store.numero}" : ""}${store.bairro.isNotEmpty ? " - ${store.bairro}" : ""}', 
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis
                            )
                          ),
                          Expanded(
                            flex: 2, 
                            child: Text(
                              '${store.city} / ${store.state}', 
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)
                            )
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: store.inactive ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(store.inactive ? 'Inativo' : 'Ativo', textAlign: TextAlign.center, style: TextStyle(color: store.inactive ? AppColors.error : AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
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
    );
  }

  void _downloadTemplate() {
    var excel = exc.Excel.createExcel();
    exc.Sheet sheetObject = excel['Sheet1'];
    
    // Adicionar cabeçalhos conforme o padrão que o sistema lê agora
    sheetObject.appendRow([
      exc.TextCellValue('Rede'),
      exc.TextCellValue('CodigoBandeira'),
      exc.TextCellValue('Bandeira'),
      exc.TextCellValue('Codigo'),
      exc.TextCellValue('Nome'),
      exc.TextCellValue('CNPJ'),
      exc.TextCellValue('CEP'),
      exc.TextCellValue('Logradouro'),
      exc.TextCellValue('Numero'),
      exc.TextCellValue('Complemento'),
      exc.TextCellValue('Bairro'),
      exc.TextCellValue('Cidade'),
      exc.TextCellValue('UF'),
      exc.TextCellValue('Latitude'),
      exc.TextCellValue('Longitude'),
      exc.TextCellValue('Regional'),
      exc.TextCellValue('Zona'),
      exc.TextCellValue('Filial'),
    ]);
    
    // Gerar bytes
    var fileBytes = excel.save();
    
    // Download
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "modelo_importacao_lojas.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo baixado com sucesso!')),
    );
  }

  void _importExcel() {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.xlsx,.csv';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.length == 1) {
        final file = files[0];
        final reader = html.FileReader();
        final progressNotifier = ValueNotifier<double>(0.0);

        // Mostrar Modal de Progresso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                width: 400,
                child: ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder: (context, progress, child) {
                    final isDone = progress >= 1.0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDone ? Icons.check_circle : IconsaxPlusLinear.document_upload, 
                              color: isDone ? Colors.green : AppColors.primaryBlue, 
                              size: 24
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(file.name ?? 'Arquivo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(isDone ? 'Importação concluída!' : 'Enviando e processando arquivo...', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (!isDone) ...[
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.lightBlue,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ] else ...[
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onRefresh(); // Recarregar a lista
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: const Text('Concluído', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );

        if (file.name.endsWith('.csv')) {
          reader.onLoad.listen((e) {
            try {
              final csvText = reader.result as String;
              final lines = csvText.split(RegExp(r'\r\n|\r|\n'));
              List<List<String>> rows = [];
              String separator = ';';
              if (lines.isNotEmpty) {
                if (lines[0].contains('\t')) separator = '\t';
                else if (lines[0].contains(';')) separator = ';';
                else if (lines[0].contains(',')) separator = ',';
              }
              for (var line in lines) {
                if (line.trim().isEmpty) continue;
                rows.add(line.split(separator));
              }
              _processRows(rows, progressNotifier);
            } catch (error) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao processar CSV: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
          reader.readAsText(file);
        } else {
          reader.onLoad.listen((e) {
            try {
              final bytes = reader.result as Uint8List;
              var excel = exc.Excel.decodeBytes(bytes);
              
              _processExcel(excel, progressNotifier);
            } catch (error) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao processar arquivo: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });

          reader.onError.listen((e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao ler o arquivo do disco.'),
                backgroundColor: Colors.red,
              ),
            );
          });

          reader.readAsArrayBuffer(file);
        }
      }
    });
  }

  void _processExcel(exc.Excel excel, ValueNotifier<double> progressNotifier) async {
    try {
      List<List<String>> rows = [];
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        for (int i = 0; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty) continue;
          rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
        }
      }
      _processRows(rows, progressNotifier);
    } catch (error) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao decodificar Excel: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

    void _processRows(List<List<String>> rows, ValueNotifier<double> progressNotifier) async {
    try {
      int importedCount = 0;
      int totalRows = rows.length;

      if (totalRows <= 1) {
        throw Exception("Arquivo vazio ou formato não suportado (linhas lidas: $totalRows).");
      }

      // Tenta mapear por cabeçalho
      final headers = rows[0].map((e) => e.toLowerCase().trim()).toList();
      int getIdx(List<String> variants) {
        for (var v in variants) {
          int idx = headers.indexOf(v.toLowerCase().trim());
          if (idx != -1) return idx;
        }
        return -1;
      }

      int idxRede = getIdx(['Rede', 'RedeId']);
      int idxBandeira = getIdx(['Bandeira', 'BandeiraId']);
      int idxCodigo = getIdx(['Codigo', 'Código', 'CodigoCliente']);
      int idxNome = getIdx(['Nome', 'Razão Social', 'Razao Social', 'Estabelecimento']);
      int idxCNPJ = getIdx(['CNPJ']);
      int idxCEP = getIdx(['CEP']);
      int idxLogradouro = getIdx(['Logradouro', 'Endereço', 'Endereco']);
      int idxNumero = getIdx(['Numero', 'Número', 'Nro']);
      int idxComplemento = getIdx(['Complemento']);
      int idxBairro = getIdx(['Bairro']);
      int idxCidade = getIdx(['Cidade', 'City']);
      int idxUF = getIdx(['UF', 'Estado', 'State']);
      int idxLat = getIdx(['Latitude', 'Lat']);
      int idxLng = getIdx(['Longitude', 'Lng', 'Long']);

      // Começa em 1 para pular o cabeçalho
      for (int i = 1; i < totalRows; i++) {
        progressNotifier.value = i / totalRows;
        if (i % 50 == 0) await Future.delayed(const Duration(milliseconds: 1)); 
        
        final row = rows[i];
        if (row.isEmpty || row.every((e) => e.trim().isEmpty)) continue;

        String getVal(int idx) => (idx != -1 && idx < row.length) ? row[idx].trim() : '';

        String storeId = DateTime.now().millisecondsSinceEpoch.toString() + i.toString();

        final store = AppStore(
          id: storeId,
          name: getVal(idxNome).isNotEmpty ? getVal(idxNome) : (getVal(idxRede).isNotEmpty ? getVal(idxRede) : 'Sem Nome'),
          clientId: '', 
          codigoCliente: getVal(idxCodigo),
          redeId: getVal(idxRede),
          bandeiraId: getVal(idxBandeira),
          cnpj: getVal(idxCNPJ),
          cep: getVal(idxCEP),
          logradouro: getVal(idxLogradouro),
          numero: getVal(idxNumero),
          complemento: getVal(idxComplemento),
          bairro: getVal(idxBairro),
          city: getVal(idxCidade),
          state: getVal(idxUF),
          latitude: double.tryParse(getVal(idxLat).replaceAll(',', '.')) ?? 0.0,
          longitude: double.tryParse(getVal(idxLng).replaceAll(',', '.')) ?? 0.0,
          regional: getVal(getIdx(['Regional'])),
          zona: getVal(getIdx(['Zona'])),
          filial: getVal(getIdx(['Filial'])),
        );

        await _api.saveStore(store);
        importedCount++;
      }

      progressNotifier.value = 1.0;
      widget.onRefresh();
      
      // Removemos o Navigator.pop automático para que o usuário veja a tela de "Concluído" com o botão
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SUCESSO! Foram importadas $importedCount lojas para o painel.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => const UniversalAddDialog(),
    ).then((_) => widget.onRefresh());
  }
}

// Diálogo Universal baseado nas imagens
class UniversalAddDialog extends StatefulWidget {
  const UniversalAddDialog({super.key});

  @override
  State<UniversalAddDialog> createState() => _UniversalAddDialogState();
}

class _UniversalAddDialogState extends State<UniversalAddDialog> {
  String _selectedType = 'Rede'; // Rede, Bandeira, Estabelecimento, Subcanal
  final _api = RegisterService();

  // Controllers comuns
  final _nameCtrl = TextEditingController();
  bool _inactive = false;

  // Controllers Bandeira
  String _selectedRedeId = '';

  // Controllers Estabelecimento
  final _codeCtrl = TextEditingController();
  final _clientCodeCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _vendedoresCtrl = TextEditingController();
  final _subcanalCtrl = TextEditingController();
  final _canalCtrl = TextEditingController();
  final _statusCtrl = TextEditingController(text: 'Ativo');
  final _substatusCtrl = TextEditingController();
  final _filialCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _logradouroCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _zonaCtrl = TextEditingController();
  final _regionalCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  List<AppRede> _redes = [];
  List<AppBandeira> _bandeiras = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final redes = await _api.getRedes();
    final bandeiras = await _api.getBandeiras();
    setState(() {
      _redes = redes;
      _bandeiras = bandeiras;
      if (_redes.isNotEmpty) _selectedRedeId = _redes.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      child: Container(
        width: 1000, // Largura maior para caber os campos lado a lado
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ADICIONAR', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              _buildRadioButtons(),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _buildFormContent(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: ['Rede', 'Bandeira', 'Estabelecimento', 'Subcanal'].map((type) {
        return Row(
          children: [
            Radio<String>(
              value: type,
              groupValue: _selectedType,
              onChanged: (val) => setState(() => _selectedType = val!),
              activeColor: AppColors.primaryBlue,
            ),
            Text(type, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFormContent() {
    switch (_selectedType) {
      case 'Rede': return _buildRedeForm();
      case 'Bandeira': return _buildBandeiraForm();
      case 'Estabelecimento': return _buildEstabelecimentoForm();
      default: return const SizedBox();
    }
  }

  Widget _buildRedeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Incluir rede de estabelecimentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Nome', _nameCtrl)),
            const SizedBox(width: 20),
            _buildSwitch('Inativo?', _inactive, (val) => setState(() => _inactive = val)),
          ],
        ),
      ],
    );
  }

  Widget _buildBandeiraForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Incluir bandeira', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildTextField('Nome', _nameCtrl)),
            const SizedBox(width: 20),
            Expanded(
              child: _buildDropdown('Rede', _selectedRedeId, _redes.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(), (val) {
                setState(() => _selectedRedeId = val!);
              }),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSwitch('Inativo?', _inactive, (val) => setState(() => _inactive = val)),
      ],
    );
  }

  Widget _buildEstabelecimentoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Incluir estabelecimento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        // Linha 1
        Row(
          children: [
            Expanded(child: _buildTextField('Código', _codeCtrl)),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue), child: const Text('Gerar', style: TextStyle(color: Colors.white))),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Código do Cliente', _clientCodeCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        // Linha 2
        Row(
          children: [
            Expanded(child: _buildTextField('Nome', _nameCtrl)),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('CNPJ', _cnpjCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        // Linha 3 (Dropdowns para Rede e Bandeira)
        Row(
          children: [
            Expanded(child: _buildTextField('Rede', TextEditingController())), // Mock por enquanto
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Bandeira', TextEditingController())), // Mock por enquanto
          ],
        ),
        const SizedBox(height: 16),
        // Endereço
        const Text('ENDEREÇO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField('CEP', _cepCtrl)),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _buildTextField('Logradouro', _logradouroCtrl)),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Número', _numeroCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Bairro', _bairroCtrl)),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Cidade', _cidadeCtrl)),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Estado', _estadoCtrl)),
          ],
        ),
        const SizedBox(height: 16),
        // Geoloc
        Row(
          children: [
            Expanded(child: _buildTextField('Latitude', _latCtrl)),
            const SizedBox(width: 20),
            Expanded(child: _buildTextField('Longitude', _lngCtrl)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            side: const BorderSide(color: AppColors.primaryBlue),
          ),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.primaryBlue)),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
          child: const Text('INCLUIR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _save() async {
    // Lógica de salvar dependendo do tipo selecionado
    if (_selectedType == 'Rede') {
      final newRede = AppRede(id: DateTime.now().toString(), name: _nameCtrl.text, inactive: _inactive);
      await _api.saveRede(newRede);
    } else if (_selectedType == 'Bandeira') {
      final newBandeira = AppBandeira(id: DateTime.now().toString(), name: _nameCtrl.text, redeId: _selectedRedeId, inactive: _inactive);
      await _api.saveBandeira(newBandeira);
    } else if (_selectedType == 'Estabelecimento') {
      final newStore = AppStore(
        id: DateTime.now().toString(),
        name: _nameCtrl.text,
        clientId: '', // Vincular se necessário
        cnpj: _cnpjCtrl.text,
        cep: _cepCtrl.text,
        logradouro: _logradouroCtrl.text,
        numero: _numeroCtrl.text,
        bairro: _bairroCtrl.text,
        city: _cidadeCtrl.text,
        state: _estadoCtrl.text,
        latitude: double.tryParse(_latCtrl.text) ?? 0.0,
        longitude: double.tryParse(_lngCtrl.text) ?? 0.0,
        inactive: _inactive,
      );
      await _api.saveStore(newStore);
    }
    Navigator.pop(context);
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
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

  Widget _buildDropdown(String label, String value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryBlue),
      ],
    );
  }
}
