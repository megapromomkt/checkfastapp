import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:excel/excel.dart' as exc;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/premium_theme.dart';
import '../../../core/data/test_database.dart';
import '../../../models/app_models.dart';
import '../../../models/register_models.dart';
import '../../../core/services/register_service.dart';

class CreateDemandModal extends StatefulWidget {
  const CreateDemandModal({super.key});

  @override
  State<CreateDemandModal> createState() => _CreateDemandModalState();
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

class _CreateDemandModalState extends State<CreateDemandModal> with SingleTickerProviderStateMixin {
  final _api = RegisterService();
  bool _loadingLists = true;
  
  List<AppClient> _clients = [];
  List<AppProject> _projects = [];
  List<AppStore> _stores = [];
  List<AppRole> _roles = [];
  List<AppBandeira> _bandeiras = [];
  List<AppDemandModel> _demandModels = [];

  // Tab State
  late TabController _tabController;

  // Shared Form State
  String? _selectedClient;
  String? _selectedProject;
  String _selectedRole = 'Promotor';
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  // Multi-store selection
  final Set<String> _selectedStoreNames = {};
  String _storeQuery = '';
  String? _selectedUfFilter;
  String? _selectedBandeiraFilter;

  // Date range/period
  DateTime _periodStartDate = DateTime.now();
  DateTime _periodEndDate = DateTime.now().add(const Duration(days: 2));

  // Dynamic shifts/scales list
  List<Map<String, dynamic>> _shifts = [];
  TimeOfDay _entryTimeInput = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _exitTimeInput = const TimeOfDay(hour: 14, minute: 0);
  final _vacanciesInputController = TextEditingController(text: '1');

  // Selected characteristic
  String? _selectedCharacteristicId;

  // Editable daily value (pre-filled from characteristic, but overridable)
  final TextEditingController _valorController = TextEditingController(text: '150.00');

  // Questionnaire controllers for Excel / default forms
  List<QuestionControllerGroup> _questionnaireControllers = [];

  // Excel Import state
  bool _isSaving = false;
  List<Map<String, dynamic>> _parsedExcelRows = [];
  bool _isProcessingExcel = false;
  double _importProgress = 0.0;
  String? _uploadedFileName;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    
    // Inicializa com um horário/escala padrão
    _shifts.add({
      'entry': const TimeOfDay(hour: 8, minute: 0),
      'exit': const TimeOfDay(hour: 14, minute: 0),
      'vacancies': 1,
    });
    
    _loadFirestoreData();
    _initQuestionnaire(AppDemand.defaultQuestionnaire);
    _updateAutoName();
  }

  void _loadFirestoreData() async {
    try {
      final clients = await _api.getClients();
      final projects = await _api.getProjects();
      final stores = await _api.getStores();
      final roles = await _api.getRoles();
      final demandModels = await _api.getDemandModels().catchError((e) {
        print('Erro ao carregar características: $e');
        return <AppDemandModel>[];
      });
      final bandeiras = await _api.getBandeiras().catchError((e) {
        print('Erro ao carregar bandeiras: $e');
        return <AppBandeira>[];
      });
      setState(() {
        _clients = clients;
        _projects = projects;
        _stores = stores;
        _roles = roles;
        _demandModels = demandModels;
        _bandeiras = bandeiras;
        _loadingLists = false;
        
        if (_clients.isNotEmpty) {
          _selectedClient = _clients.first.name;
          final clientId = _clients.first.id;
          final clientProjects = _projects.where((p) => p.clientId == clientId).toList();
          if (clientProjects.isNotEmpty) {
            _selectedProject = clientProjects.first.name;
          }
        }
        if (_roles.isNotEmpty) {
          _selectedRole = _roles.first.name;
        }
        if (_demandModels.isNotEmpty) {
          _selectedCharacteristicId = _demandModels.first.id;
        }
        _updateAutoName();
      });
    } catch (e) {
      print('Erro ao carregar dados do Firestore: $e');
      setState(() {
        _loadingLists = false;
      });
    }
  }

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
  void dispose() {
    _tabController.dispose();
    for (var qc in _questionnaireControllers) {
      qc.dispose();
    }
    _nameController.dispose();
    _vacanciesInputController.dispose();
    _instructionsController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _updateAutoName() {
    setState(() {
      final storeText = _selectedStoreNames.isNotEmpty 
          ? (_selectedStoreNames.length == 1 ? _selectedStoreNames.first : "${_selectedStoreNames.length} lojas")
          : 'Lojas';
      _nameController.text = "$storeText — $_selectedRole — ${DateFormat('dd/MM').format(_periodStartDate)} a ${DateFormat('dd/MM').format(_periodEndDate)}";
    });
  }

  Future<void> _saveDemand(String status) async {
    if (_isSaving) return;
    if (_selectedClient == null || _selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione Cliente e Projeto obrigatórios.')));
      return;
    }
    if (_selectedStoreNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione pelo menos uma loja.')));
      return;
    }
    if (_shifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adicione pelo menos uma escala/horário.')));
      return;
    }
    if (_selectedCharacteristicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma Característica de Demanda.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    final characteristic = _demandModels.cast<AppDemandModel?>().firstWhere(
      (m) => m?.id == _selectedCharacteristicId,
      orElse: () => null,
    );

    int count = 0;
    try {
      for (var storeName in _selectedStoreNames) {
        final storeObj = _stores.cast<AppStore?>().firstWhere(
          (s) => s?.name == storeName,
          orElse: () => null,
        );
        final address = storeObj != null 
            ? '${storeObj.logradouro}, ${storeObj.numero} - ${storeObj.bairro}, ${storeObj.city} - ${storeObj.state}'
            : 'Endereço não informado';
        final lat = storeObj?.latitude;
        final lng = storeObj?.longitude;

        for (var shift in _shifts) {
          final entry = shift['entry'] as TimeOfDay;
          final exit = shift['exit'] as TimeOfDay;
          final vacancies = shift['vacancies'] as int;
          
          final timeRange = "${entry.format(context)} - ${exit.format(context)}";
          final dateRangeStr = "${DateFormat('dd/MM/yyyy').format(_periodStartDate)} - ${DateFormat('dd/MM/yyyy').format(_periodEndDate)}";
          
          final id = "${DateTime.now().millisecondsSinceEpoch}_ind_$count";

          final newDemand = AppDemand(
            id: id,
            storeName: storeName,
            network: storeObj?.redeId ?? 'REDE',
            address: address,
            role: _selectedRole,
            distance: '0.0 KM',
            timeRange: timeRange,
            value: double.tryParse(_valorController.text.replaceAll(',', '.')) ?? characteristic?.defaultValue ?? 150.0,
            date: dateRangeStr,
            urgency: 'NORMAL',
            status: status,
            clientName: _selectedClient,
            projectName: _selectedProject,
            totalVagas: vacancies,
            instructions: characteristic?.defaultInstructions ?? _instructionsController.text,
            priority: 'Média',
            questionnaire: const [],
            requiresCheckIn: characteristic?.requiresCheckIn ?? true,
            requiresCheckOut: characteristic?.requiresCheckOut ?? true,
            requiresPhoto: characteristic?.requiresPhoto ?? true,
            requiresLocation: characteristic?.requiresLocation ?? true,
            allowedRadius: characteristic?.allowedRadius ?? 100,
            requiredActivity: characteristic?.requiredActivity,
            dressCode: characteristic?.dressCode,
            requiredDocuments: characteristic?.requiredDocuments,
            latitude: lat,
            longitude: lng,
          );

          await _api.saveDemand(newDemand);
          count++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // Fecha o CircularProgressIndicator
        Navigator.pop(context, true); // Fecha o modal principal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sucesso! Criadas $count demandas com base nas características selecionadas.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        Navigator.pop(context); // Fecha o CircularProgressIndicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar demandas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        setState(() {
          _uploadedFileName = file.name;
          _isProcessingExcel = true;
        });

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
              _processRows(rows);
            } catch (error) {
              setState(() => _isProcessingExcel = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao processar CSV: $error'), backgroundColor: Colors.red));
            }
          });
          reader.readAsText(file);
        } else {
          reader.onLoad.listen((e) {
            try {
              final bytes = reader.result as Uint8List;
              var excel = exc.Excel.decodeBytes(bytes);
              _processExcel(excel);
            } catch (error) {
              setState(() => _isProcessingExcel = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao processar arquivo: $error'), backgroundColor: Colors.red));
            }
          });
          reader.readAsArrayBuffer(file);
        }
      }
    });
  }

  void _processExcel(exc.Excel excel) {
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
    _processRows(rows);
  }

  void _processRows(List<List<String>> rows) {
    try {
      if (rows.length <= 1) {
        throw Exception("Arquivo vazio ou formato não suportado.");
      }

      final headers = rows[0].map((e) => e.toLowerCase().trim()).toList();
      int getIdx(List<String> variants) {
        for (var v in variants) {
          int idx = headers.indexOf(v.toLowerCase().trim());
          if (idx != -1) return idx;
        }
        return -1;
      }

      int idxCliente = getIdx(['cliente']);
      int idxProjeto = getIdx(['projeto']);
      int idxLoja = getIdx(['loja', 'estabelecimento']);
      int idxFuncao = getIdx(['funcao', 'função', 'cargo', 'role']);
      int idxData = getIdx(['data', 'date']);
      int idxEntrada = getIdx(['entrada', 'horario entrada', 'checkin']);
      int idxSaida = getIdx(['saida', 'saída', 'horario saida', 'checkout']);
      int idxVagas = getIdx(['vagas', 'slots', 'quantidade']);
      int idxPrioridade = getIdx(['prioridade']);
      int idxInstrucoes = getIdx(['instrucoes', 'instruções']);

      int idxValor = getIdx(['valor', 'diaria', 'diária', 'preco', 'preço', 'value']);
      int idxCheckIn = getIdx(['exige checkin', 'checkin obrigatorio', 'check-in', 'requirescheckin']);
      int idxCheckOut = getIdx(['exige checkout', 'checkout obrigatorio', 'check-out', 'requirescheckout']);
      int idxFoto = getIdx(['exige foto', 'foto obrigatoria', 'foto', 'requiresphoto']);
      int idxGeoloc = getIdx(['exige geolocalizacao', 'geolocalizacao', 'geoloc', 'requireslocation']);
      int idxRaio = getIdx(['raio permitido', 'raio', 'allowedradius', 'radius']);
      int idxAtividade = getIdx(['atividade', 'requiredactivity', 'activity']);
      int idxPassoAPasso = getIdx(['passo a passo', 'stepbystep', 'instructions_step']);
      int idxVestuario = getIdx(['vestuario', 'vestuário', 'dresscode', 'dress']);
      int idxDocumentos = getIdx(['documentos necessarios', 'documentos', 'requireddocuments', 'docs']);
      int idxLatitude = getIdx(['latitude', 'lat']);
      int idxLongitude = getIdx(['longitude', 'lng', 'lon']);

      List<Map<String, dynamic>> parsed = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((e) => e.trim().isEmpty)) continue;
        
        String getVal(int idx) => (idx != -1 && idx < row.length) ? row[idx].trim() : '';

        bool parseBool(String s, bool def) {
          if (s.isEmpty) return def;
          final clean = s.toLowerCase().trim();
          if (clean == 'sim' || clean == 'true' || clean == '1' || clean == 's' || clean == 'yes' || clean == 'y') return true;
          if (clean == 'não' || clean == 'nao' || clean == 'false' || clean == '0' || clean == 'n' || clean == 'no') return false;
          return def;
        }

        parsed.add({
          'cliente': getVal(idxCliente).isNotEmpty ? getVal(idxCliente) : (_selectedClient ?? ''),
          'projeto': getVal(idxProjeto).isNotEmpty ? getVal(idxProjeto) : (_selectedProject ?? ''),
          'loja': getVal(idxLoja),
          'funcao': getVal(idxFuncao).isNotEmpty ? getVal(idxFuncao) : 'Promotor',
          'data': getVal(idxData),
          'entrada': getVal(idxEntrada).isNotEmpty ? getVal(idxEntrada) : '08:00',
          'saida': getVal(idxSaida).isNotEmpty ? getVal(idxSaida) : '14:00',
          'vagas': int.tryParse(getVal(idxVagas)) ?? 1,
          'prioridade': getVal(idxPrioridade).isNotEmpty ? getVal(idxPrioridade) : 'Média',
          'instrucoes': getVal(idxInstrucoes),
          'valor': double.tryParse(getVal(idxValor)) ?? 150.0,
          'requiresCheckIn': parseBool(getVal(idxCheckIn), true),
          'requiresCheckOut': parseBool(getVal(idxCheckOut), true),
          'requiresPhoto': parseBool(getVal(idxFoto), true),
          'requiresLocation': parseBool(getVal(idxGeoloc), true),
          'allowedRadius': int.tryParse(getVal(idxRaio)) ?? 100,
          'requiredActivity': getVal(idxAtividade),
          'stepByStep': getVal(idxPassoAPasso),
          'dressCode': getVal(idxVestuario),
          'requiredDocuments': getVal(idxDocumentos),
          'latitude': double.tryParse(getVal(idxLatitude)),
          'longitude': double.tryParse(getVal(idxLongitude)),
        });
      }

      setState(() {
        _parsedExcelRows = parsed;
        _isProcessingExcel = false;
      });
    } catch (e) {
      setState(() => _isProcessingExcel = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao processar linhas: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveExcelDemands() async {
    if (_parsedExcelRows.isEmpty) return;

    setState(() {
      _isProcessingExcel = true;
      _importProgress = 0.0;
    });

    int totalSaved = 0;
    try {
      for (int i = 0; i < _parsedExcelRows.length; i++) {
        final row = _parsedExcelRows[i];
        final String id = '${DateTime.now().millisecondsSinceEpoch}_excel_${i}';
        
        final demand = AppDemand(
          id: id,
          storeName: row['loja'].toString().isNotEmpty ? row['loja'].toString() : 'Loja Não Informada',
          network: 'REDE',
          address: 'Endereço',
          role: row['funcao'].toString(),
          distance: '0.0 KM',
          timeRange: '${row['entrada']} - ${row['saida']}',
          value: row['valor'] as double? ?? 150.0,
          date: row['data'].toString(),
          urgency: 'NORMAL',
          status: 'ABERTAS',
          clientName: row['cliente'].toString(),
          projectName: row['projeto'].toString(),
          totalVagas: row['vagas'] as int,
          instructions: row['instrucoes'].toString(),
          priority: row['prioridade'].toString(),
          questionnaire: const [],
          requiresCheckIn: row['requiresCheckIn'] as bool? ?? true,
          requiresCheckOut: row['requiresCheckOut'] as bool? ?? true,
          requiresPhoto: row['requiresPhoto'] as bool? ?? true,
          requiresLocation: row['requiresLocation'] as bool? ?? true,
          allowedRadius: row['allowedRadius'] as int? ?? 100,
          requiredActivity: row['requiredActivity']?.toString(),
          stepByStep: row['stepByStep']?.toString(),
          dressCode: row['dressCode']?.toString(),
          requiredDocuments: row['requiredDocuments']?.toString(),
          latitude: row['latitude'] as double?,
          longitude: row['longitude'] as double?,
        );

        await _api.saveDemand(demand);
        totalSaved++;
        setState(() {
          _importProgress = (i + 1) / _parsedExcelRows.length;
        });
      }

      setState(() {
        _isProcessingExcel = false;
        _parsedExcelRows = [];
        _uploadedFileName = null;
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sucesso! Importadas $totalSaved demandas com sucesso!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _isProcessingExcel = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar importação: $e'), backgroundColor: Colors.red));
    }
  }

  void _downloadDemandTemplate() {
    var excel = exc.Excel.createExcel();
    exc.Sheet sheetObject = excel['Sheet1'];
    
    sheetObject.appendRow([
      exc.TextCellValue('Cliente'),
      exc.TextCellValue('Projeto'),
      exc.TextCellValue('Loja'),
      exc.TextCellValue('Funcao'),
      exc.TextCellValue('Data'),
      exc.TextCellValue('Entrada'),
      exc.TextCellValue('Saida'),
      exc.TextCellValue('Vagas'),
      exc.TextCellValue('Prioridade'),
      exc.TextCellValue('Instrucoes'),
      exc.TextCellValue('Valor'),
      exc.TextCellValue('Exige Checkin'),
      exc.TextCellValue('Exige Checkout'),
      exc.TextCellValue('Exige Foto'),
      exc.TextCellValue('Exige Localizacao'),
      exc.TextCellValue('Raio Permitido'),
      exc.TextCellValue('Atividade'),
      exc.TextCellValue('Passo a Passo'),
      exc.TextCellValue('Vestuario'),
      exc.TextCellValue('Documentos Necessarios'),
      exc.TextCellValue('Latitude'),
      exc.TextCellValue('Longitude'),
    ]);
    
    sheetObject.appendRow([
      exc.TextCellValue(_selectedClient ?? 'Unilever'),
      exc.TextCellValue(_selectedProject ?? 'Reposição Verão'),
      exc.TextCellValue(_selectedStoreNames.isNotEmpty ? _selectedStoreNames.first : 'Atacadão Lapa'),
      exc.TextCellValue('Promotor'),
      exc.TextCellValue(DateFormat('dd/MM/yyyy').format(DateTime.now())),
      exc.TextCellValue('08:00'),
      exc.TextCellValue('14:00'),
      exc.TextCellValue('1'),
      exc.TextCellValue('Média'),
      exc.TextCellValue('Levar EPI e crachá.'),
      exc.TextCellValue('150.00'),
      exc.TextCellValue('Sim'),
      exc.TextCellValue('Sim'),
      exc.TextCellValue('Sim'),
      exc.TextCellValue('Sim'),
      exc.TextCellValue('100'),
      exc.TextCellValue('Reposição de produtos e precificação.'),
      exc.TextCellValue('1. Chegar na loja; 2. Fazer check-in; 3. Limpar gôndola.'),
      exc.TextCellValue('Calça jeans escura e tênis fechado.'),
      exc.TextCellValue('RG e CPF.'),
      exc.TextCellValue('-23.5275'),
      exc.TextCellValue('-46.6853'),
    ]);
    
    var fileBytes = excel.save();
    
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "modelo_importacao_demandas.xlsx")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _loadingLists
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : Column(
                children: [
                  _buildHeader(),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primaryBlue,
                    labelColor: AppColors.primaryBlue,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: 'Criar Demanda'),
                      Tab(text: 'Importar Excel'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIndividualTab(),
                        _buildExcelTab(),
                      ],
                    ),
                  ),
                  _buildFooter(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CRIAR NOVA DEMANDA', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 4),
              Text('Vincule projetos e defina regras de execução.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final int index = _tabController.index;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (index == 0) ...[
            OutlinedButton(
              onPressed: (_loadingLists || _isSaving) ? null : () => _saveDemand('RASCUNHO'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cardBorder),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : const Text('SALVAR RASCUNHO', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: (_loadingLists || _isSaving) ? null : () => _saveDemand('ABERTAS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('PUBLICAR DEMANDA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ] else if (index == 1) ...[
            ElevatedButton.icon(
              onPressed: _parsedExcelRows.isEmpty || _isProcessingExcel ? null : _saveExcelDemands,
              icon: const Icon(Icons.cloud_done_outlined, color: Colors.white, size: 18),
              label: const Text('PUBLICAR IMPORTAÇÃO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCharacteristicPreview() {
    final characteristic = _demandModels.cast<AppDemandModel?>().firstWhere(
      (m) => m?.id == _selectedCharacteristicId,
      orElse: () => null,
    );
    if (characteristic == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RESUMO DO MODELO VINCULADO', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Diária: R\$ ${characteristic.defaultValue.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPreviewRow('Atividades obrigatórias', characteristic.requiredActivity),
          _buildPreviewRow('Vestimenta (Dress Code)', characteristic.dressCode),
          _buildPreviewRow('Documentos necessários', characteristic.requiredDocuments),
          _buildPreviewRow('Instruções / Regras', characteristic.defaultInstructions),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 16),
          const Text('REGRAS DE VALIDAÇÃO (ATIVAS):', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildValidationBadge('Check-in', characteristic.requiresCheckIn),
              _buildValidationBadge('Checkout', characteristic.requiresCheckOut),
              _buildValidationBadge('Foto', characteristic.requiresPhoto),
              _buildValidationBadge('Geolocalização', characteristic.requiresLocation),
              _buildValidationBadge('Raio: ${characteristic.allowedRadius}m', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'Não configurado', 
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)
          ),
        ],
      ),
    );
  }

  Widget _buildValidationBadge(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryBlue.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: active ? AppColors.primaryBlue.withOpacity(0.2) : Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel, 
            color: active ? AppColors.primaryBlue : Colors.grey, 
            size: 14
          ),
          const SizedBox(width: 6),
          Text(
            label, 
            style: TextStyle(
              color: active ? AppColors.primaryBlue : AppColors.textSecondary, 
              fontWeight: FontWeight.bold, 
              fontSize: 11
            )
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualTab() {
    final filteredStores = _stores.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(_storeQuery.toLowerCase()) ||
                            s.city.toLowerCase().contains(_storeQuery.toLowerCase());
      final matchesUf = _selectedUfFilter == null || s.state == _selectedUfFilter;
      final matchesBandeira = _selectedBandeiraFilter == null || _getBandeiraName(s.bandeiraId) == _selectedBandeiraFilter;
      return matchesSearch && matchesUf && matchesBandeira;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔹 BLOCO 1 — ESTRUTURA E PARÂMETROS'),
          Row(
            children: [
              Expanded(child: _buildDropdown('Cliente *', _clients.map((e) => e.name).toList(), _selectedClient, (val) {
                setState(() {
                  _selectedClient = val;
                  _selectedProject = null;
                  
                  if (val != null && _clients.any((c) => c.name == val)) {
                    final clientId = _clients.firstWhere((c) => c.name == val).id;
                    final clientProjects = _projects.where((p) => p.clientId == clientId).toList();
                    if (clientProjects.isNotEmpty) {
                      _selectedProject = clientProjects.first.name;
                    }
                  }
                });
              })),
              const SizedBox(width: 20),
              Expanded(child: _buildDropdown('Projeto *', _selectedClient == null ? [] : _projects.where((p) => p.clientId == _clients.firstWhere((c) => c.name == _selectedClient).id).map((p) => p.name).toList(), _selectedProject, (val) {
                setState(() {
                  _selectedProject = val;
                });
              })),
              const SizedBox(width: 20),
              Expanded(child: _buildDropdown('Função *', _roles.map((e) => e.name).toList(), _selectedRole, (val) {
                setState(() {
                  _selectedRole = val!;
                  _updateAutoName();
                });
              })),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildTextField('Nome da demanda (Auto)', _nameController)),
            ],
          ),
          const SizedBox(height: 32),

          _buildSectionTitle('📅 PERÍODO DA DEMANDA'),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context, 
                      initialDate: _periodStartDate, 
                      firstDate: DateTime.now().subtract(const Duration(days: 30)), 
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    );
                    if (date != null) {
                      setState(() {
                        _periodStartDate = date;
                        if (_periodEndDate.isBefore(_periodStartDate)) {
                          _periodEndDate = _periodStartDate.add(const Duration(days: 2));
                        }
                        _updateAutoName();
                      });
                    }
                  },
                  child: _buildDateTimeCard('Data Início', DateFormat('dd/MM/yyyy').format(_periodStartDate)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context, 
                      initialDate: _periodEndDate, 
                      firstDate: _periodStartDate, 
                      lastDate: DateTime.now().add(const Duration(days: 365))
                    );
                    if (date != null) {
                      setState(() {
                        _periodEndDate = date;
                        _updateAutoName();
                      });
                    }
                  },
                  child: _buildDateTimeCard('Data Fim', DateFormat('dd/MM/yyyy').format(_periodEndDate)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text('SELECIONE AS LOJAS *', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (val) => setState(() => _storeQuery = val),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Filtrar por nome ou cidade...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUfFilter ?? 'Todas',
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: ['Todas', ..._getUniqueUfs()].map((uf) => DropdownMenuItem(value: uf, child: Text(uf == 'Todas' ? 'Todas as UFs' : uf))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedUfFilter = val == 'Todas' ? null : val;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBandeiraFilter ?? 'Todas',
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: ['Todas', ..._getUniqueBandeiraNames()].map((b) => DropdownMenuItem(value: b, child: Text(b == 'Todas' ? 'Todas as Bandeiras' : b))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedBandeiraFilter = val == 'Todas' ? null : val;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStoreNames.addAll(filteredStores.map((s) => s.name));
                          _updateAutoName();
                        });
                      },
                      child: const Text('Selecionar Todas', style: TextStyle(color: AppColors.primaryBlue)),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedStoreNames.removeAll(filteredStores.map((s) => s.name));
                          _updateAutoName();
                        });
                      },
                      child: const Text('Limpar Seleção', style: TextStyle(color: Colors.redAccent)),
                    ),
                    const Spacer(),
                    Text('${_selectedStoreNames.length} lojas selecionadas', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: filteredStores.length,
                    itemBuilder: (context, index) {
                      final store = filteredStores[index];
                      final isSelected = _selectedStoreNames.contains(store.name);
                      return CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        title: Text(store.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        subtitle: Text('${store.city} - ${store.state} | ${_getBandeiraName(store.bandeiraId)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        activeColor: AppColors.primaryBlue,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedStoreNames.add(store.name);
                            } else {
                              _selectedStoreNames.remove(store.name);
                            }
                            _updateAutoName();
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionTitle('🔹 BLOCO 3 — HORÁRIOS E ESCALAS'),
          Container(
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildTimePicker('Horário de Entrada', _entryTimeInput, (t) => setState(() => _entryTimeInput = t)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker('Horário de Saída', _exitTimeInput, (t) => setState(() => _exitTimeInput = t)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField('Vagas para esta escala', _vacanciesInputController),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final v = int.tryParse(_vacanciesInputController.text) ?? 1;
                        setState(() {
                          _shifts.add({
                            'entry': _entryTimeInput,
                            'exit': _exitTimeInput,
                            'vacancies': v,
                          });
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Icon(Icons.add, size: 24),
                    ),
                  ],
                ),
                if (_shifts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('HORÁRIOS ADICIONADOS:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(_shifts.length, (idx) {
                      final s = _shifts[idx];
                      final entryTime = s['entry'] as TimeOfDay;
                      final exitTime = s['exit'] as TimeOfDay;
                      final v = s['vacancies'] as int;
                      return Chip(
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.05),
                        side: const BorderSide(color: AppColors.primaryBlue, width: 0.5),
                        label: Text(
                          "${entryTime.format(context)} - ${exitTime.format(context)} ($v ${v == 1 ? 'vaga' : 'vagas'})",
                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.cancel, size: 16, color: AppColors.error),
                        onDeleted: () {
                          setState(() {
                            _shifts.removeAt(idx);
                          });
                        },
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildSectionTitle('🔹 CARACTERÍSTICAS DA DEMANDA'),
          _buildDropdown(
            'Modelo de Características *', 
            _demandModels.map((e) => e.name).toList(),
            _demandModels.cast<AppDemandModel?>().firstWhere((m) => m?.id == _selectedCharacteristicId, orElse: () => null)?.name,
            (val) {
              setState(() {
                final match = _demandModels.firstWhere((m) => m.name == val);
                _selectedCharacteristicId = match.id;
                // Auto-fill the value field from the selected characteristic
                _valorController.text = match.defaultValue.toStringAsFixed(2);
              });
            }
          ),
          const SizedBox(height: 16),
          // Editable daily value field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VALOR DA DIÁRIA (R\$)',
                style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                ),
                child: TextField(
                  controller: _valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    prefixText: 'R\$ ',
                    prefixStyle: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
                    hintText: '150.00',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pré-preenchido com o valor padrão da característica selecionada. Você pode alterar por demanda.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          if (_selectedCharacteristicId != null) ...[
            const SizedBox(height: 24),
            _buildCharacteristicPreview(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getBandeiraName(String bandeiraId) {
    if (_bandeiras.isEmpty) return bandeiraId;
    final b = _bandeiras.cast<AppBandeira?>().firstWhere((x) => x?.id == bandeiraId, orElse: () => null);
    return b?.name ?? bandeiraId;
  }

  List<String> _getUniqueBandeiraNames() {
    final ids = _stores.map((s) => s.bandeiraId).where((id) => id.isNotEmpty).toSet().toList();
    final names = ids.map((id) => _getBandeiraName(id)).toSet().toList();
    names.sort();
    return names;
  }

  List<String> _getUniqueUfs() {
    final ufs = _stores.map((s) => s.state).where((uf) => uf.isNotEmpty).toSet().toList();
    ufs.sort();
    return ufs;
  }



  Widget _buildExcelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('📊 IMPORTAÇÃO DE VAGAS VIA PLANILHA'),
          const Text(
            'Importe centenas de vagas de uma só vez a partir de um arquivo Excel (.xlsx) ou CSV.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          if (_isProcessingExcel) ...[
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryBlue),
                  const SizedBox(height: 16),
                  Text(
                    _uploadedFileName != null ? 'Lendo ${_uploadedFileName}...' : 'Processando arquivo...',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  if (_importProgress > 0.0) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _importProgress, color: AppColors.primaryBlue, backgroundColor: AppColors.lightBlue),
                    const SizedBox(height: 8),
                    Text('${(_importProgress * 100).toStringAsFixed(0)}% concluído', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryBlue, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _uploadedFileName ?? 'Selecione uma planilha do seu computador',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _downloadDemandTemplate,
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Baixar Modelo XLSX'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(color: AppColors.primaryBlue),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _importExcel,
                              icon: const Icon(Icons.file_open, size: 16),
                              label: const Text('Selecionar Planilha'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          if (_parsedExcelRows.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PRÉ-VISUALIZAÇÃO DE IMPORTAÇÃO (${_parsedExcelRows.length} demandas encontradas)',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _parsedExcelRows.clear();
                      _uploadedFileName = null;
                    });
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                  label: const Text('Limpar Prévia', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(AppColors.background),
                    columns: const [
                      DataColumn(label: Text('Loja', style: TextStyle(color: AppColors.textPrimary))),
                      DataColumn(label: Text('Data', style: TextStyle(color: AppColors.textPrimary))),
                      DataColumn(label: Text('Função', style: TextStyle(color: AppColors.textPrimary))),
                      DataColumn(label: Text('Vagas', style: TextStyle(color: AppColors.textPrimary))),
                      DataColumn(label: Text('Horário', style: TextStyle(color: AppColors.textPrimary))),
                      DataColumn(label: Text('Prioridade', style: TextStyle(color: AppColors.textPrimary))),
                      DataColumn(label: Text('Projeto', style: TextStyle(color: AppColors.textPrimary))),
                    ],
                    rows: _parsedExcelRows.take(15).map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['loja'].toString(), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                          DataCell(Text(row['data'].toString(), style: const TextStyle(color: AppColors.textPrimary))),
                          DataCell(Text(row['funcao'].toString(), style: const TextStyle(color: AppColors.textPrimary))),
                          DataCell(Text(row['vagas'].toString(), style: const TextStyle(color: AppColors.textPrimary))),
                          DataCell(Text('${row['entrada']} - ${row['saida']}', style: const TextStyle(color: AppColors.textPrimary))),
                          DataCell(Text(row['prioridade'].toString(), style: const TextStyle(color: AppColors.textPrimary))),
                          DataCell(Text(row['projeto'].toString(), style: const TextStyle(color: AppColors.textPrimary))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (_parsedExcelRows.length > 15) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Exibindo as primeiras 15 de ${_parsedExcelRows.length} linhas.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(title, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: Colors.white,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              hint: const Text('Selecione...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryBlue),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
      ],
    );
  }



  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: time);
            if (t != null) onSelected(t);
          },
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(IconsaxPlusLinear.timer, color: AppColors.primaryBlue, size: 18),
                const SizedBox(width: 15),
                Text(time.format(context), style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, QuestionControllerGroup qc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta #${index + 1}',
                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    final removed = _questionnaireControllers.removeAt(index);
                    removed.dispose();
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildQuestionInput('Título da Seção', qc.sectionController),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 3,
                child: _buildQuestionInput('Texto da Pergunta', qc.textController),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MAPEAMENTO NO CURRÍCULO', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _mappingOptions.contains(qc.curriculumMapping) ? qc.curriculumMapping : 'Nenhum',
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          items: _mappingOptions.map((opt) {
                            return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(color: AppColors.textPrimary)));
                          }).toList(),
                          onChanged: (v) {
                            setState(() {
                              qc.curriculumMapping = v ?? 'Nenhum';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('OPÇÕES DE RESPOSTA E PONTUAÇÃO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...List.generate(qc.optionControllers.length, (optIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildQuestionInput('Opção', qc.optionControllers[optIndex], hint: 'Ex: Sim'),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 1,
                    child: _buildQuestionInput('Pontos', qc.pointControllers[optIndex], hint: 'Ex: 10'),
                  ),
                  const SizedBox(width: 15),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        qc.optionControllers.removeAt(optIndex).dispose();
                        qc.pointControllers.removeAt(optIndex).dispose();
                      });
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              setState(() {
                qc.optionControllers.add(TextEditingController(text: ''));
                qc.pointControllers.add(TextEditingController(text: '0'));
              });
            },
            icon: const Icon(Icons.add, color: AppColors.primaryBlue, size: 16),
            label: const Text('Adicionar Opção', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Icon(Icons.calendar_today, color: AppColors.primaryBlue, size: 20),
        ],
      ),
    );
  }
}
