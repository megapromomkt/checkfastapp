import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';
import '../../core/utils/responsive.dart';
import 'widgets/registers_list_detail_layout.dart';
import 'widgets/project_wizard_view.dart';
import 'widgets/stores_management_tab.dart';

class RegistersManagementView extends StatefulWidget {
  const RegistersManagementView({super.key});

  @override
  State<RegistersManagementView> createState() => _RegistersManagementViewState();
}

class _RegistersManagementViewState extends State<RegistersManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final db = TestDatabase.instance;
  final _api = RegisterService();

  bool _loading = true;
  List<AppClient> _clients = [];
  List<AppProject> _projects = [];
  List<AppStore> _stores = [];
  List<AppRole> _roles = [];
  List<AppPaymentRule> _paymentRules = [];
  List<AppDemandModel> _demandModels = [];
  List<AppRede> _redes = [];
  List<AppBandeira> _bandeiras = [];
  List<AppQuestionnaire> _questionnaires = [];

  AppClient? _selectedClient;
  AppProject? _selectedProject;
  AppStore? _selectedStore;
  AppRole? _selectedRole;
  AppPaymentRule? _selectedRule;
  AppDemandModel? _selectedModel;
  AppQuestionnaire? _selectedQuestionnaire;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  Future<void> _seedAtacadaoQuestionnaire() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('questionnaires')
          .where('name', isEqualTo: 'Frente de Caixa | Atacadão')
          .get();
      if (snap.docs.isEmpty) {
        final id = FirebaseFirestore.instance.collection('questionnaires').doc().id;
        final newQuest = {
          'id': id,
          'name': 'Frente de Caixa | Atacadão',
          'questions': [
            {
              'questionText': 'Está de acordo com os detalhes da vaga?',
              'type': 'Sim/Não',
              'options': ['Sim', 'Não'],
            },
            {
              'questionText': 'Já trabalhou como frente de caixa?',
              'type': 'Sim/Não',
              'options': ['Sim', 'Não'],
            },
            {
              'questionText': 'Já fez o treinamento do Atacadão?',
              'type': 'Sim/Não',
              'options': ['Sim', 'Não'],
            },
            {
              'questionText': 'Já teve contato com o sistema de caixa do Atacadão?',
              'type': 'Sim/Não',
              'options': ['Sim', 'Não'],
            },
          ]
        };
        await FirebaseFirestore.instance.collection('questionnaires').doc(id).set(newQuest);
      }
    } catch (e) {
      print('Erro ao semear questionário: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      await _seedAtacadaoQuestionnaire();
      final clients = await _api.getClients().catchError((e) { print('Erro clients: $e'); return <AppClient>[]; });
      final projects = await _api.getProjects().catchError((e) { print('Erro projects: $e'); return <AppProject>[]; });
      final stores = await _api.getStores().catchError((e) { print('Erro stores: $e'); return <AppStore>[]; });
      final roles = await _api.getRoles().catchError((e) { print('Erro roles: $e'); return <AppRole>[]; });
      final paymentRules = await _api.getPaymentRules().catchError((e) { print('Erro rules: $e'); return <AppPaymentRule>[]; });
      final demandModels = await _api.getDemandModels().catchError((e) { print('Erro models: $e'); return <AppDemandModel>[]; });
      final redes = await _api.getRedes().catchError((e) { print('Erro redes: $e'); return <AppRede>[]; });
      final bandeiras = await _api.getBandeiras().catchError((e) { print('Erro bandeiras: $e'); return <AppBandeira>[]; });
      final questionnaires = await _api.getQuestionnaires().catchError((e) { print('Erro questionnaires: $e'); return <AppQuestionnaire>[]; });
      
      if (!mounted) return;

      setState(() {
        _clients = clients;
        _projects = projects;
        _stores = stores;
        _roles = roles;
        _paymentRules = paymentRules;
        _demandModels = demandModels;
        _redes = redes;
        _bandeiras = bandeiras;
        _questionnaires = questionnaires;
        _loading = false;
        
        if (_clients.isNotEmpty) _selectedClient = _clients.first;
        if (_projects.isNotEmpty) _selectedProject = _projects.first;
        if (_stores.isNotEmpty) _selectedStore = _stores.first;
        if (_roles.isNotEmpty) _selectedRole = _roles.first;
        if (_paymentRules.isNotEmpty) _selectedRule = _paymentRules.first;
        if (_demandModels.isNotEmpty) _selectedModel = _demandModels.first;
        if (_questionnaires.isNotEmpty) _selectedQuestionnaire = _questionnaires.first;
      });
    } catch (e, st) {
      print('CRITICAL ERROR loading data: $e\n$st');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initializeSelections() {
    if (_clients.isNotEmpty) _selectedClient = _clients.first;
    if (_projects.isNotEmpty) _selectedProject = _projects.first;
    if (_stores.isNotEmpty) _selectedStore = _stores.first;
    if (_roles.isNotEmpty) _selectedRole = _roles.first;
    if (_paymentRules.isNotEmpty) _selectedRule = _paymentRules.first;
    if (_demandModels.isNotEmpty) _selectedModel = _demandModels.first;
    if (_questionnaires.isNotEmpty) _selectedQuestionnaire = _questionnaires.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumHeader(
          title: 'Cadastros',
          subtitle: 'Gerencie clientes, projetos, locais e regras para criação de demandas',
        ),
        const SizedBox(height: 30),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          dividerColor: AppColors.cardBorder,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Clientes'),
            Tab(text: 'Projetos'),
            Tab(text: 'Locais'),
            Tab(text: 'Funções'),
            Tab(text: 'Regras de Pagamento'),
            Tab(text: 'Características de demanda'),
            Tab(text: 'Questionários'),
          ],
        ),
        const SizedBox(height: 32),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildClientsTab(),
              _buildProjectsTab(),
              _buildStoresTab(),
              _buildRolesTab(),
              _buildPaymentRulesTab(),
              _buildDemandModelsTab(),
              _buildQuestionnairesTab(),
            ],
          ),
        ),
      ],
    );
  }

  // --- DIALOGS ---
  void _showDeleteDialog(String itemName, Function() onDelete) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Confirmar Exclusão', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
        content: Text('Tem certeza que deseja excluir "$itemName"?', style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              onDelete();
              setState(() {});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({required String title, required List<Widget> fields, required Function() onSave}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder)),
        child: Container(
          width: Responsive.dialogWidth(context, maxWidth: 500),
          padding: Responsive.dialogPadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: fields,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      onSave();
                      setState(() {});
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, 
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      )
    );
  }

  // Listas padrão conforme solicitado
  static const List<String> _defaultDepts = [
    'Operações', 'Trade Marketing', 'Eventos', 'Outsourcing', 'Comercial', 'RH', 'Financeiro', 
    'Qualidade Contínua', 'Tecnologia', 'Logística', 'Facilities', 'Administrativo', 'Diretoria', 
    'Jurídico', 'Marketing', 'Atendimento', 'Compras', 'Projetos', 'Inteligência de Mercado'
  ];

  static const List<String> _defaultCategories = [
    'Promotoria', 'Reposição', 'Frente de Caixa', 'Mercearia', 'Bebidas', 'Refrigerados', 'Hortifruti', 
    'Açougue', 'Farma', 'Merchandising', 'Positivação', 'Degustação', 'Sampling', 'PDV', 'Auditoria', 
    'Pesquisa', 'Eventos', 'Recepção', 'Atendimento', 'Facilities', 'Limpeza', 'Portaria', 'Logística', 
    'Estoque', 'Transporte', 'Administrativo', 'Backoffice', 'Financeiro', 'RH', 'Recrutamento', 
    'Tecnologia', 'Suporte Técnico', 'BI / Dados', 'Comercial', 'Coordenação', 'Supervisão', 'Gestão', 
    'Qualidade', 'Compliance', 'Treinamento', 'Implantação', 'Expansão', 'Inteligência Mercado'
  ];

  static const List<String> _defaultLevels = [
    'Auxiliar', 'Assistente', 'Operacional', 'Técnico', 'Analista', 'Especialista', 'Líder', 
    'Supervisor', 'Coordenador', 'Gerente', 'Head', 'Diretor', 'Consultor', 'Executivo', 
    'Estagiário', 'Aprendiz'
  ];

  static const List<String> _defaultTypes = [
    'Campo', 'Interno', 'Externo', 'Híbrido', 'Remoto', 'Fixo', 'Roteirista', 'Motorizado', 
    'Temporário', 'Intermitente', 'Eventual', 'Freelancer', 'Plantonista', 'Escala', 
    'Home Office', 'Regional', 'Nacional'
  ];

  Widget _buildAutocompleteField(String label, TextEditingController controller, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return options;
              return options.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) => controller.text = selection,
            fieldViewBuilder: (context, fieldCtrl, focusNode, onFieldSubmitted) {
              // Sincronizar o controlador do Autocomplete com o nosso controlador externo
              if (controller.text.isNotEmpty && fieldCtrl.text.isEmpty) {
                fieldCtrl.text = controller.text;
              }
              fieldCtrl.addListener(() => controller.text = fieldCtrl.text);
              
              return TextField(
                controller: fieldCtrl,
                focusNode: focusNode,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                  suffixIcon: const Icon(IconsaxPlusLinear.arrow_down_1, size: 18),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 300, // Ajustar conforme necessário
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: const TextStyle(fontSize: 14)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
            ),
          )
        ],
      ),
    );
  }

  // --- ABA 1: CLIENTES ---
  Widget _buildClientsTab() {
    return _buildStandardListWithDetails<AppClient>(
      buttonLabel: 'Novo cliente',
      items: _clients,
      selectedItem: _selectedClient,
      titleBuilder: (c) => c.name,
      subtitleBuilder: (c) => 'CNPJ: ${c.cnpj}',
      onSelect: (val) => setState(() => _selectedClient = val),
      onAdd: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
            child: ProjectWizardView(
              onFinished: () {
                Navigator.pop(context);
                _loadData();
              },
            ),
          ),
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deleteClient(item.id);
          setState(() {
            _clients.remove(item);
            _selectedClient = _clients.isNotEmpty ? _clients.first : null;
          });
        });
      },
      detailsBuilder: (item) {
        final clientProjects = _projects.where((p) => p.clientId == item.id).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(IconsaxPlusLinear.building, color: AppColors.primaryBlue, size: 40)),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                            OutlinedButton.icon(
                              onPressed: () {
                                final nameCtrl = TextEditingController(text: item.name);
                                final cnpjCtrl = TextEditingController(text: item.cnpj);
                                _showFormDialog(
                                  title: 'Editar Cliente',
                                  fields: [_buildTextField('Nome Fantasia', nameCtrl), _buildTextField('CNPJ', cnpjCtrl)],
                                  onSave: () {
                                    item.name = nameCtrl.text;
                                    item.cnpj = cnpjCtrl.text;
                                  }
                                );
                              },
                              icon: const Icon(IconsaxPlusLinear.edit, size: 16),
                              label: const Text('Editar Dados'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue, 
                                side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildInfoItem('CNPJ', item.cnpj), const SizedBox(width: 48),
                            _buildInfoItem('TIPO', item.type), const SizedBox(width: 48),
                            _buildInfoItem('PAGAMENTO', item.paymentTerm),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Projetos Vinculados', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
                        child: ProjectWizardView(
                          client: item,
                          onFinished: () {
                            Navigator.pop(context);
                            _loadData();
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 18),
                  label: const Text('Novo projeto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface, 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: AppColors.cardBorder)
              ),
              child: clientProjects.isEmpty 
                ? const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Nenhum projeto vinculado a este cliente.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15))))
                : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: clientProjects.length,
                separatorBuilder: (context, index) => const Divider(color: AppColors.cardBorder, height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final proj = clientProjects[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    title: Text(proj.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                    subtitle: Text('Tipo: ${proj.type} | Pagamento: ${proj.paymentModel}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 20), 
                          onPressed: () => _showDeleteDialog(proj.name, () async {
                            await _api.deleteProject(proj.id);
                            setState(() {
                              _projects.remove(proj);
                            });
                          })
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
    );
  }

  // --- ABA 2: PROJETOS ---
  Widget _buildProjectsTab() {
    return _buildStandardListWithDetails<AppProject>(
      buttonLabel: 'Novo projeto (Via Cliente)',
      items: _projects,
      selectedItem: _selectedProject,
      titleBuilder: (p) => p.name,
      subtitleBuilder: (p) => _clients.firstWhere((c) => c.id == p.clientId, orElse: () => AppClient(id: '', name: 'Desconhecido')).name,
      onSelect: (val) => setState(() => _selectedProject = val),
      onAdd: () {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Projetos devem ser criados dentro da aba Clientes.')));
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deleteProject(item.id);
          setState(() {
            _projects.remove(item);
            _selectedProject = _projects.isNotEmpty ? _projects.first : null;
          });
        });
      },
      detailsBuilder: (item) {
        final clientName = _clients.firstWhere((c) => c.id == item.clientId, orElse: () => AppClient(id: '', name: 'Desconhecido')).name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE PROJETO', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 50),
                        child: ProjectWizardView(
                          project: item,
                          onFinished: () {
                            Navigator.pop(context);
                            _loadData();
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue, 
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionBlock('IDENTIFICAÇÃO E CLASSIFICAÇÃO', [
              _buildFakeField('Nome do projeto', item.name),
              _buildFakeField('Cliente vinculado', clientName),
              _buildFakeField('Código', item.code),
              _buildFakeField('Departamento', item.department, icon: IconsaxPlusLinear.building),
              _buildFakeField('Categoria', item.category, icon: IconsaxPlusLinear.category),
              _buildFakeField('Nível', item.level, icon: IconsaxPlusLinear.level),
            ]),
            _buildSectionBlock('CONFIGURAÇÕES OPERACIONAIS', [
              _buildFakeField('Tipo de Atuação', item.type, icon: IconsaxPlusLinear.star),
              _buildFakeField('Modelo Operacional', item.operationalModel),
              _buildFakeField('SLA Operacional', item.sla.isEmpty ? 'Não definido' : item.sla),
            ]),
            _buildSectionBlock('GOVERNANÇA FINANCEIRA', [
              _buildFakeField('Modelo de Cobrança', item.billingModel, icon: IconsaxPlusLinear.money_send),
              _buildFakeField('Prazo de Pagamento (Cliente)', item.clientPaymentTerms),
              _buildFakeField('Dia de Fechamento', 'Todo dia ${item.closingDay}', icon: IconsaxPlusLinear.calendar),
              _buildFakeField('Período de Apuração', item.closingPeriod),
              _buildFakeField('Competência', item.closingCompetence),
              _buildFakeField('Contratação Colaborador', item.contractType, icon: IconsaxPlusLinear.user_tag),
              _buildFakeField('Frequência Pagamento', item.workerPaymentFrequency),
            ]),
            _buildSectionBlock('TRAVAS DE SEGURANÇA (ISO 9001)', [
              _buildFakeField('Trava de Checkout', item.blockCheckoutISO ? 'Ativa' : 'Inativa', icon: IconsaxPlusLinear.lock),
              _buildFakeField('Raio de Segurança', '${item.locationRadius} metros', icon: IconsaxPlusLinear.location),
              _buildFakeField('Exigir Foto', item.requiresPhoto ? 'Sim' : 'Não', icon: IconsaxPlusLinear.camera),
              _buildFakeField('Câmera Interna', item.useInternalCamera ? 'Ativa' : 'Inativa', icon: IconsaxPlusLinear.video),
              _buildFakeField('Valores da Matriz', item.showMatrixValues ? 'Visível' : 'Oculto', icon: IconsaxPlusLinear.money_3),
              _buildFakeField('Jornada Máxima', '${item.maxJourneyHours} horas', icon: IconsaxPlusLinear.timer_1),
            ]),

          ],
        );
      }
    );
  }

  // --- ABA 3: LOCAIS ---
  Widget _buildStoresTab() {
    return StoresManagementTab(
      stores: _stores,
      redes: _redes,
      bandeiras: _bandeiras,
      onRefresh: () => _loadData(),
    );
  }

  // --- ABA 4: FUNÇÕES ---
  Widget _buildRolesTab() {
    return _buildStandardListWithDetails<AppRole>(
      buttonLabel: 'Nova função',
      items: _roles,
      selectedItem: _selectedRole,
      titleBuilder: (r) => r.name,
      subtitleBuilder: (r) => '${r.department} • ${r.category}',
      onSelect: (val) => setState(() => _selectedRole = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        final deptCtrl = TextEditingController();
        final catCtrl = TextEditingController();
        final levelCtrl = TextEditingController();
        final typeCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        bool isActive = true;

        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return Dialog(
                backgroundColor: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder)),
                child: Container(
                  width: Responsive.dialogWidth(context, maxWidth: 600),
                  padding: Responsive.dialogPadding(context),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nova Função', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(height: 32),
                        _buildTextField('Nome da Função (Ex: Promotor Líder)', nameCtrl),
                        Row(
                          children: [
                            Expanded(child: _buildAutocompleteField('Departamento (Ex: Trade Marketing)', deptCtrl, {..._defaultDepts, ..._roles.map((r) => r.department)}.where((e) => e.isNotEmpty).toList()..sort())),
                            const SizedBox(width: 16),
                            Expanded(child: _buildAutocompleteField('Categoria (Ex: Promotoria)', catCtrl, {..._defaultCategories, ..._roles.map((r) => r.category)}.where((e) => e.isNotEmpty).toList()..sort())),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: _buildAutocompleteField('Nível (Ex: Operacional)', levelCtrl, {..._defaultLevels, ..._roles.map((r) => r.level)}.where((e) => e.isNotEmpty).toList()..sort())),
                            const SizedBox(width: 16),
                            Expanded(child: _buildAutocompleteField('Tipo de Atuação (Ex: Campo)', typeCtrl, {..._defaultTypes, ..._roles.map((r) => r.type)}.where((e) => e.isNotEmpty).toList()..sort())),
                          ],
                        ),
                        _buildTextField('Descrição das Atividades', descCtrl),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          title: const Text('Status: Ativo', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Quando inativo, não aparecerá na criação de demandas.'),
                          value: isActive,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (val) {
                            setModalState(() => isActive = val);
                          },
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context), 
                              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final newRole = AppRole(
                                  id: DateTime.now().toString(), 
                                  name: nameCtrl.text, 
                                  department: deptCtrl.text,
                                  category: catCtrl.text,
                                  level: levelCtrl.text,
                                  type: typeCtrl.text,
                                  description: descCtrl.text,
                                  isActive: isActive,
                                );
                                await _api.saveRole(newRole);
                                setState(() {
                                  _roles.add(newRole);
                                  _selectedRole = newRole;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue, 
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            }
          )
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deleteRole(item.id);
          setState(() {
            _roles.remove(item);
            _selectedRole = _roles.isNotEmpty ? _roles.first : null;
          });
        });
      },
      detailsBuilder: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DESCRIÇÃO DA FUNÇÃO', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
                OutlinedButton.icon(
                  onPressed: () {
                    final nameCtrl = TextEditingController(text: item.name);
                    final deptCtrl = TextEditingController(text: item.department);
                    final catCtrl = TextEditingController(text: item.category);
                    final levelCtrl = TextEditingController(text: item.level);
                    final typeCtrl = TextEditingController(text: item.type);
                    final descCtrl = TextEditingController(text: item.description);
                    bool isActive = item.isActive;

                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setModalState) {
                          return Dialog(
                            backgroundColor: AppColors.surface,
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder)),
                            child: Container(
                              width: Responsive.dialogWidth(context, maxWidth: 600),
                              padding: Responsive.dialogPadding(context),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Editar Função', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                                    const SizedBox(height: 32),
                                    _buildTextField('Nome da Função', nameCtrl),
                                    Row(
                                      children: [
                                        Expanded(child: _buildAutocompleteField('Departamento', deptCtrl, {..._defaultDepts, ..._roles.map((r) => r.department)}.where((e) => e.isNotEmpty).toList()..sort())),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildAutocompleteField('Categoria', catCtrl, {..._defaultCategories, ..._roles.map((r) => r.category)}.where((e) => e.isNotEmpty).toList()..sort())),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(child: _buildAutocompleteField('Nível', levelCtrl, {..._defaultLevels, ..._roles.map((r) => r.level)}.where((e) => e.isNotEmpty).toList()..sort())),
                                        const SizedBox(width: 16),
                                        Expanded(child: _buildAutocompleteField('Tipo de Atuação', typeCtrl, {..._defaultTypes, ..._roles.map((r) => r.type)}.where((e) => e.isNotEmpty).toList()..sort())),
                                      ],
                                    ),
                                    _buildTextField('Descrição', descCtrl),
                                    const SizedBox(height: 10),
                                    SwitchListTile(
                                      title: const Text('Status: Ativo', style: TextStyle(fontWeight: FontWeight.bold)),
                                      value: isActive,
                                      activeColor: AppColors.primaryBlue,
                                      onChanged: (val) {
                                        setModalState(() => isActive = val);
                                      },
                                    ),
                                    const SizedBox(height: 32),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context), 
                                          child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600))
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: () async {
                                            item.name = nameCtrl.text;
                                            item.department = deptCtrl.text;
                                            item.category = catCtrl.text;
                                            item.level = levelCtrl.text;
                                            item.type = typeCtrl.text;
                                            item.description = descCtrl.text;
                                            item.isActive = isActive;
                                            
                                            await _api.saveRole(item);
                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue, 
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      )
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue, 
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionBlock('DADOS DA OCUPAÇÃO', [
              _buildFakeField('Título da Função', item.name),
              _buildFakeField('Departamento', item.department, icon: IconsaxPlusLinear.building),
              _buildFakeField('Categoria Operacional', item.category, icon: IconsaxPlusLinear.category),
              _buildFakeField('Nível Hierárquico', item.level, icon: IconsaxPlusLinear.level),
              _buildFakeField('Tipo de Atuação', item.type, icon: IconsaxPlusLinear.briefcase),
            ]),
            _buildFakeField('Status', item.isActive ? 'Ativo' : 'Inativo', icon: item.isActive ? IconsaxPlusLinear.tick_circle : IconsaxPlusLinear.close_circle),
            const SizedBox(height: 24),
            _buildFakeField('Escopo e Responsabilidades', item.description, isLong: true),
          ],
        );
      }
    );
  }

  // --- ABA 5: REGRAS DE PAGAMENTO ---
  Widget _buildPaymentRulesTab() {
    return _buildStandardListWithDetails<AppPaymentRule>(
      buttonLabel: 'Nova regra',
      items: _paymentRules,
      selectedItem: _selectedRule,
      titleBuilder: (pr) => pr.name,
      subtitleBuilder: (pr) => pr.type,
      onSelect: (val) => setState(() => _selectedRule = val),
      onAdd: () {
        final nameCtrl = TextEditingController();
        _showPaymentRuleDialog(AppPaymentRule(id: DateTime.now().millisecondsSinceEpoch.toString(), name: ''));
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deletePaymentRule(item.id);
          setState(() {
            _paymentRules.remove(item);
            _selectedRule = _paymentRules.isNotEmpty ? _paymentRules.first : null;
          });
        });
      },
      detailsBuilder: (item) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                      Text('Regra: ${item.measurementType} | ${item.contractType}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showPaymentRuleDialog(item),
                    icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                    label: const Text('Configurar Regra'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue, 
                      side: const BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              _buildRuleSummary(item),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRuleSummary(AppPaymentRule item) {
    return Column(
      children: [
        _buildSummarySection('MEDIÇÃO E FECHAMENTO', [
          _buildInfoItem('Tipo Medição', item.measurementType),
          _buildInfoItem('Frequência', item.frequency),
          _buildInfoItem('Dia Fechamento', 'Todo dia ${item.closingDay}'),
          _buildInfoItem('Período', item.closingPeriod),
        ]),
        const Divider(height: 48),
        _buildSummarySection('PAGAMENTO COLABORADOR', [
          _buildInfoItem('Contratação', item.contractType),
          _buildInfoItem('Forma', item.paymentForm),
          _buildInfoItem('NF Necessária', item.necessitaNF ? 'Sim' : 'Não'),
          _buildInfoItem('Pgto Automático', item.pagamentoAutomatico ? 'Sim' : 'Não'),
        ]),
        const Divider(height: 48),
        _buildSummarySection('REGRAS OPERACIONAIS', [
          _buildInfoItem('Exige Foto', item.exigeFoto ? 'Sim' : 'Não'),
          _buildInfoItem('Exige GPS', item.exigeGeoloc ? 'Sim' : 'Não'),
          _buildInfoItem('Tolerância', '${item.toleranceLate} min'),
          _buildInfoItem('Aprovação', item.approvalFlow),
        ]),
        const Divider(height: 48),
        _buildSummarySection('REEMBOLSOS E IMPOSTOS', [
          _buildInfoItem('Reembolsa KM', item.reimbursesKM ? 'Sim' : 'Não'),
          _buildInfoItem('Valor KM', 'R\$ ${item.kmValue.toStringAsFixed(2)}'),
          _buildInfoItem('Retém ISS', item.retencaoISS ? 'Sim' : 'Não'),
          _buildInfoItem('CNAE', item.cnae.isEmpty ? 'Não inf.' : item.cnae),
        ]),
      ],
    );
  }

  Widget _buildSummarySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children.map((c) => Expanded(child: c)).toList(),
        ),
      ],
    );
  }

  void _showPaymentRuleDialog(AppPaymentRule rule) {
    final nameCtrl = TextEditingController(text: rule.name);
    final cnaeCtrl = TextEditingController(text: rule.cnae);
    final kmCtrl = TextEditingController(text: rule.kmValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 900,
              padding: const EdgeInsets.all(32),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Configuração de Regra de Pagamento', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTextField('Nome da Regra', nameCtrl),
                    const SizedBox(height: 16),
                    
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: Column(
                        children: [
                          _buildExpansionSection('1. MEDIÇÃO E FECHAMENTO', [
                            _buildDialogDropdown('Tipo de Medição', rule.measurementType, ['Por presença', 'Por visita', 'Por hora', 'Por diária', 'Por produção', 'Por sell out', 'Por positivação', 'Por auditoria'], (v) => setModalState(() => rule.measurementType = v!)),
                            _buildDialogDropdown('Frequência', rule.frequency, ['Semanal', 'Quinzenal', 'Mensal', 'D+7', 'D+15', 'D+30'], (v) => setModalState(() => rule.frequency = v!)),
                            _buildDialogTextField('Dia do Fechamento', rule.closingDay.toString(), (v) => rule.closingDay = int.tryParse(v) ?? 25),
                            _buildDialogSwitch('Corte Automático?', rule.closingAutomaticCut, (v) => setModalState(() => rule.closingAutomaticCut = v)),
                          ]),
                          _buildExpansionSection('2. PRAZOS CLIENTE E FATURAMENTO', [
                            _buildDialogDropdown('Prazo Pagamento Cliente', rule.clientPaymentTerms, ['À vista', '7 dias', '14 dias', '21 dias', '28 dias', '30 dias', '45 dias', '60 dias'], (v) => setModalState(() => rule.clientPaymentTerms = v!)),
                            _buildDialogDropdown('Meio de Recebimento', rule.clientPaymentMethod, ['Boleto', 'PIX', 'Transferência', 'Cartão corporativo'], (v) => setModalState(() => rule.clientPaymentMethod = v!)),
                          ]),
                          _buildExpansionSection('3. PAGAMENTO COLABORADOR', [
                            _buildDialogDropdown('Tipo Contratação', rule.contractType, ['CLT', 'PJ', 'Freelancer', 'Diarista', 'Cooperado', 'Temporário', 'RPA'], (v) => setModalState(() => rule.contractType = v!)),
                            _buildDialogDropdown('Forma de Pagamento', rule.paymentForm, ['PIX', 'Conta Corrente', 'Conta Poupança'], (v) => setModalState(() => rule.paymentForm = v!)),
                            _buildDialogSwitch('Exige Evidência?', rule.exigeEvidencia, (v) => setModalState(() => rule.exigeEvidencia = v)),
                            _buildDialogSwitch('Pagamento Automático?', rule.pagamentoAutomatico, (v) => setModalState(() => rule.pagamentoAutomatico = v)),
                            _buildDialogSwitch('Necessita NF?', rule.necessitaNF, (v) => setModalState(() => rule.necessitaNF = v)),
                          ]),
                          _buildExpansionSection('4. REGRAS DE APROVAÇÃO', [
                            _buildDialogDropdown('Fluxo de Aprovação', rule.approvalFlow, ['Supervisor aprova', 'Cliente aprova', 'Backoffice aprova', 'Aprovação automática'], (v) => setModalState(() => rule.approvalFlow = v!)),
                            _buildDialogTextField('SLA Aprovação (Horas)', rule.approvalSLA.toString(), (v) => rule.approvalSLA = int.tryParse(v) ?? 48),
                            _buildDialogSwitch('Bloqueia sem aprovação?', rule.blockPaymentWithoutApproval, (v) => setModalState(() => rule.blockPaymentWithoutApproval = v)),
                          ]),
                          _buildExpansionSection('5. REGRAS OPERACIONAIS', [
                            _buildDialogTextField('Tolerância Atraso (min)', rule.toleranceLate.toString(), (v) => rule.toleranceLate = int.tryParse(v) ?? 15),
                            _buildDialogSwitch('Exige Geolocalização?', rule.exigeGeoloc, (v) => setModalState(() => rule.exigeGeoloc = v)),
                            _buildDialogSwitch('Exige Foto?', rule.exigeFoto, (v) => setModalState(() => rule.exigeFoto = v)),
                            _buildDialogSwitch('Exige Roteiro?', rule.exigeRoteiro, (v) => setModalState(() => rule.exigeRoteiro = v)),
                          ]),
                          _buildExpansionSection('6. REEMBOLSOS', [
                            _buildDialogSwitch('Reembolsa KM?', rule.reimbursesKM, (v) => setModalState(() => rule.reimbursesKM = v)),
                            if (rule.reimbursesKM) _buildDialogTextField('Valor por KM', rule.kmValue.toString(), (v) => rule.kmValue = double.tryParse(v) ?? 0.0),
                            _buildDialogSwitch('Reembolsa Pedágio?', rule.reimbursesToll, (v) => setModalState(() => rule.reimbursesToll = v)),
                            _buildDialogSwitch('Reembolsa Alimentação?', rule.reimbursesFood, (v) => setModalState(() => rule.reimbursesFood = v)),
                          ]),
                          _buildExpansionSection('7. IMPOSTOS E FISCAL', [
                            _buildDialogSwitch('Retém ISS?', rule.retencaoISS, (v) => setModalState(() => rule.retencaoISS = v)),
                            _buildDialogSwitch('Retém INSS?', rule.retencaoINSS, (v) => setModalState(() => rule.retencaoINSS = v)),
                            _buildDialogTextField('CNAE Fiscal', rule.cnae, (v) => rule.cnae = v),
                          ]),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            rule.name = nameCtrl.text;
                            await _api.savePaymentRule(rule);
                            if (!_paymentRules.any((r) => r.id == rule.id)) {
                              setState(() => _paymentRules.add(rule));
                            }
                            setState(() => _selectedRule = rule);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
                          child: const Text('Salvar Regra Completa'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpansionSection(String title, List<Widget> children) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryBlue)),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: children.map((c) => SizedBox(width: 250, child: c)).toList(),
        )
      ],
    );
  }

  Widget _buildDialogDropdown(String label, String value, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogTextField(String label, String initialValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _getRoleName(String roleId) {
    if (_roles.isEmpty) return roleId.isNotEmpty ? roleId : 'Nenhuma';
    final r = _roles.cast<AppRole?>().firstWhere((x) => x?.id == roleId, orElse: () => null);
    return r?.name ?? (roleId.isNotEmpty ? roleId : 'Nenhuma');
  }

  void _showDemandModelDialog(AppDemandModel item) {
    final nameCtrl = TextEditingController(text: item.name);
    final timeCtrl = TextEditingController(text: item.defaultTime);
    final vacCtrl = TextEditingController(text: item.defaultVacancies.toString());
    final valueCtrl = TextEditingController(text: item.defaultValue.toString());
    final activityCtrl = TextEditingController(text: item.requiredActivity);
    final dressCtrl = TextEditingController(text: item.dressCode);
    final docsCtrl = TextEditingController(text: item.requiredDocuments);
    final rulesCtrl = TextEditingController(text: item.defaultInstructions);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final roleNames = _roles.map((r) => r.name).toList();
          String? currentRoleName;
          if (_roles.isNotEmpty) {
            final match = _roles.cast<AppRole?>().firstWhere((r) => r?.id == item.roleId, orElse: () => null);
            currentRoleName = match?.name ?? _roles.first.name;
          }

          return Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.name.isEmpty ? 'Nova Característica de Demanda' : 'Editar Característica', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTextField('Nome da Característica', nameCtrl),
                      const SizedBox(height: 16),
                      if (roleNames.isNotEmpty) ...[
                        _buildDialogDropdown('Função Vinculada', currentRoleName ?? '', roleNames, (v) {
                          final role = _roles.firstWhere((r) => r.name == v);
                          setModalState(() => item.roleId = role.id);
                        }),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField('Horário Padrão', timeCtrl),
                      const SizedBox(height: 16),
                      _buildTextField('Vagas Padrão', vacCtrl),
                      const SizedBox(height: 16),
                      _buildTextField('Valor Padrão da Diária', valueCtrl),
                      const SizedBox(height: 16),
                      _buildTextField('Atividades Obrigatórias', activityCtrl),
                      const SizedBox(height: 16),
                      _buildTextField('Vestimenta (Dress Code)', dressCtrl),
                      const SizedBox(height: 16),
                      _buildTextField('Documentos Necessários', docsCtrl),
                      const SizedBox(height: 16),
                      _buildTextField('Regras e Recomendações', rulesCtrl),
                      const SizedBox(height: 24),
                      const Text('REGRAS DE VALIDAÇÃO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      _buildDialogSwitch('Exigir Check-in', item.requiresCheckIn, (v) => setModalState(() => item.requiresCheckIn = v)),
                      _buildDialogSwitch('Exigir Check-out', item.requiresCheckOut, (v) => setModalState(() => item.requiresCheckOut = v)),
                      _buildDialogSwitch('Exigir Foto', item.requiresPhoto, (v) => setModalState(() => item.requiresPhoto = v)),
                      _buildDialogSwitch('Exigir Localização', item.requiresLocation, (v) => setModalState(() => item.requiresLocation = v)),
                      const SizedBox(height: 16),
                      _buildDialogTextField('Raio Permitido (metros)', item.allowedRadius.toString(), (v) => item.allowedRadius = int.tryParse(v) ?? 100),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              item.name = nameCtrl.text;
                              item.defaultTime = timeCtrl.text;
                              item.defaultVacancies = int.tryParse(vacCtrl.text) ?? 1;
                              item.defaultValue = double.tryParse(valueCtrl.text) ?? 150.0;
                              item.requiredActivity = activityCtrl.text;
                              item.dressCode = dressCtrl.text;
                              item.requiredDocuments = docsCtrl.text;
                              item.defaultInstructions = rulesCtrl.text;
                              
                              if (item.roleId.isEmpty && _roles.isNotEmpty) {
                                item.roleId = _roles.first.id;
                              }

                              await _api.saveDemandModel(item);
                              if (!_demandModels.any((m) => m.id == item.id)) {
                                _demandModels.add(item);
                              }
                              setState(() {
                                _selectedModel = item;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- ABA 6: CARACTERÍSTICAS DE DEMANDA ---
  Widget _buildDemandModelsTab() {
    return _buildStandardListWithDetails<AppDemandModel>(
      buttonLabel: 'Nova característica',
      items: _demandModels,
      selectedItem: _selectedModel,
      titleBuilder: (m) => m.name,
      subtitleBuilder: (m) => _getRoleName(m.roleId),
      onSelect: (val) => setState(() => _selectedModel = val),
      onAdd: () {
        _showDemandModelDialog(AppDemandModel(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '', clientId: '', roleId: ''));
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deleteDemandModel(item.id);
          setState(() {
            _demandModels.remove(item);
            _selectedModel = _demandModels.isNotEmpty ? _demandModels.first : null;
          });
        });
      },
      detailsBuilder: (item) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CARACTERÍSTICAS DA DEMANDA', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showDemandModelDialog(item);
                    },
                    icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue, 
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionBlock('ESTRUTURA', [
                _buildFakeField('Nome da característica', item.name),
                _buildFakeField('Função vinculada', _getRoleName(item.roleId)),
              ]),
              _buildSectionBlock('EXECUÇÃO PADRÃO', [
                _buildFakeField('Horário padrão', item.defaultTime),
                _buildFakeField('Vagas padrão', item.defaultVacancies.toString()),
                _buildFakeField('Valor da Diária', 'R\$ ${item.defaultValue.toStringAsFixed(2)}'),
              ]),
              _buildSectionBlock('DETALHES DA VAGA', [
                _buildFakeField('Atividades obrigatórias', item.requiredActivity.isNotEmpty ? item.requiredActivity : 'Não preenchido'),
                _buildFakeField('Vestimenta (Dress Code)', item.dressCode.isNotEmpty ? item.dressCode : 'Não preenchido'),
              ]),
              _buildSectionBlock('REQUISITOS E REGRAS', [
                _buildFakeField('Documentos necessários', item.requiredDocuments.isNotEmpty ? item.requiredDocuments : 'Não preenchido'),
                _buildFakeField('Regras / Recomendações', item.defaultInstructions.isNotEmpty ? item.defaultInstructions : 'Não preenchido'),
              ]),
              _buildSectionBlock('REGRAS DE VALIDAÇÃO (PROVEDOR)', [
                _buildFakeField('Exige check-in', item.requiresCheckIn ? 'Sim' : 'Não'),
                _buildFakeField('Exige check-out', item.requiresCheckOut ? 'Sim' : 'Não'),
                _buildFakeField('Exige foto', item.requiresPhoto ? 'Sim' : 'Não'),
                _buildFakeField('Exige geolocalização', item.requiresLocation ? 'Sim' : 'Não'),
                _buildFakeField('Raio permitido', '${item.allowedRadius} metros'),
              ]),
            ],
          ),
        );
      }
    );
  }

  // --- GENERIC LIST VIEW BUILDER ---
  Widget _buildStandardListWithDetails<T>({
    required String buttonLabel,
    required List<T> items,
    required T? selectedItem,
    required String Function(T) titleBuilder,
    required String Function(T) subtitleBuilder,
    required Function(T) onSelect,
    required Function() onAdd,
    required Function(T) onDelete,
    required Widget Function(T) detailsBuilder,
  }) {
    return StandardListWithDetails<T>(
      buttonLabel: buttonLabel,
      items: items,
      selectedItem: selectedItem,
      titleBuilder: titleBuilder,
      subtitleBuilder: subtitleBuilder,
      onSelect: onSelect,
      onAdd: onAdd,
      onDelete: onDelete,
      detailsBuilder: detailsBuilder,
    );
  }

  Widget _buildSectionBlock(String title, List<Widget> children, {bool isColumn = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          isColumn 
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList())
            : Row(children: children.map((c) => Expanded(child: c)).toList()),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _buildFakeField(String label, String value, {IconData? icon, bool isLong = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.primaryBlue, size: 18), const SizedBox(width: 10)],
              Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, String initialValue) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
        decoration: InputDecoration(
          labelText: label.toUpperCase(),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          border: InputBorder.none,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  // --- ABA 7: QUESTIONÁRIOS ---
  Widget _buildQuestionnairesTab() {
    return _buildStandardListWithDetails<AppQuestionnaire>(
      buttonLabel: 'Novo questionário',
      items: _questionnaires,
      selectedItem: _selectedQuestionnaire,
      titleBuilder: (q) => q.name,
      subtitleBuilder: (q) => '${q.questions.length} perguntas cadastradas',
      onSelect: (val) => setState(() => _selectedQuestionnaire = val),
      onAdd: () {
        showDialog(
          context: context,
          builder: (context) => CreateEditQuestionnaireModal(
            onSave: (q) async {
              await _api.saveQuestionnaire(q);
              _loadData();
            },
          ),
        );
      },
      onDelete: (item) {
        _showDeleteDialog(item.name, () async {
          await _api.deleteQuestionnaire(item.id);
          setState(() {
            _questionnaires.remove(item);
            _selectedQuestionnaire = _questionnaires.isNotEmpty ? _questionnaires.first : null;
          });
        });
      },
      detailsBuilder: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CADASTRO DE QUESTIONÁRIO', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CreateEditQuestionnaireModal(
                        questionnaire: item,
                        onSave: (q) async {
                          await _api.saveQuestionnaire(q);
                          _loadData();
                        },
                      ),
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.edit, size: 14),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue, 
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionBlock('ESTRUTURA', [
              _buildFakeField('Nome do questionário', item.name),
              _buildFakeField('Total de Perguntas', '${item.questions.length} perguntas'),
            ]),
            const SizedBox(height: 32),
            const Text('PERGUNTAS CADASTRADAS', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...item.questions.map((q) {
              final options = (q['options'] as List? ?? []).map((o) => "${o['text']} (${o['points']} pts)").join(', ');
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.cardBorder)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['sectionTitle']?.toString().toUpperCase() ?? 'GERAL', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Text(q['questionText']?.toString() ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('Mapeamento: ${q['curriculumMapping'] ?? 'Nenhum'}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Opções: $options', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class StandardListWithDetails<T> extends StatefulWidget {
  final String buttonLabel;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) titleBuilder;
  final String Function(T) subtitleBuilder;
  final Function(T) onSelect;
  final Function() onAdd;
  final Function(T) onDelete;
  final Widget Function(T) detailsBuilder;

  const StandardListWithDetails({
    super.key,
    required this.buttonLabel,
    required this.items,
    required this.selectedItem,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.detailsBuilder,
  });

  @override
  State<StandardListWithDetails<T>> createState() => _StandardListWithDetailsState<T>();
}

class _StandardListWithDetailsState<T> extends State<StandardListWithDetails<T>> {
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase().trim();
      final title = widget.titleBuilder(item).toLowerCase();
      final subtitle = widget.subtitleBuilder(item).toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            prefixIcon: const Icon(IconsaxPlusLinear.search_normal, color: AppColors.textSecondary, size: 20),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: widget.onAdd, 
                        icon: const Icon(IconsaxPlusLinear.add_square, color: AppColors.primaryBlue, size: 28), 
                        tooltip: widget.buttonLabel
                      )
                    ],
                  ),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                Expanded(
                  child: filteredItems.isEmpty ? const Center(child: Text('Nenhum item.', style: TextStyle(color: AppColors.textSecondary))) : ListView.builder(
                    itemCount: filteredItems.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = item == widget.selectedItem;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primaryBlue.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        title: Text(widget.titleBuilder(item), style: TextStyle(
                          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary, 
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 15
                        )),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(widget.subtitleBuilder(item), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(IconsaxPlusLinear.trash, color: AppColors.error, size: 18), onPressed: () => widget.onDelete(item)),
                            Icon(IconsaxPlusLinear.arrow_right_3, color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary, size: 16),
                          ],
                        ),
                        onTap: () => widget.onSelect(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(16), 
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: widget.selectedItem == null || !widget.items.contains(widget.selectedItem) 
              ? const Center(child: Text('Selecione ou crie um item para ver os detalhes', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500))) 
              : widget.detailsBuilder(widget.selectedItem!),
          ),
        ),
      ],
    );
  }
}

class QuestionControllerGroup {
  final TextEditingController sectionController;
  final TextEditingController textController;
  String curriculumMapping;
  String questionType;
  String responseType;
  final List<TextEditingController> optionControllers;
  final List<TextEditingController> pointControllers;

  QuestionControllerGroup({
    required this.sectionController,
    required this.textController,
    required this.curriculumMapping,
    this.questionType = 'Opções',
    this.responseType = 'Texto',
    required this.optionControllers,
    required this.pointControllers,
  });

  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>> options = [];
    if (questionType == 'Opções' || questionType == 'Múltiplas opções escolha') {
      for (int i = 0; i < optionControllers.length; i++) {
        options.add({
          'text': optionControllers[i].text,
          'points': int.tryParse(pointControllers[i].text) ?? 0,
        });
      }
    } else if (questionType == 'Sim/Não') {
      for (int i = 0; i < optionControllers.length; i++) {
        options.add({
          'text': i == 0 ? 'Sim' : 'Não',
          'points': int.tryParse(pointControllers[i].text) ?? 0,
        });
      }
    }
    return {
      'sectionTitle': sectionController.text,
      'questionText': textController.text,
      'questionType': questionType,
      'responseType': responseType,
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

class CreateEditQuestionnaireModal extends StatefulWidget {
  final AppQuestionnaire? questionnaire;
  final Function(AppQuestionnaire) onSave;

  const CreateEditQuestionnaireModal({super.key, this.questionnaire, required this.onSave});

  @override
  State<CreateEditQuestionnaireModal> createState() => _CreateEditQuestionnaireModalState();
}

class _CreateEditQuestionnaireModalState extends State<CreateEditQuestionnaireModal> {
  final _nameController = TextEditingController();
  List<QuestionControllerGroup> _questionControllers = [];

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
    if (widget.questionnaire != null) {
      _nameController.text = widget.questionnaire!.name;
      for (var q in widget.questionnaire!.questions) {
        List<TextEditingController> optConts = [];
        List<TextEditingController> ptConts = [];
        final qType = q['questionType']?.toString() ?? (q['responseType'] == 'Dropdown' ? 'Opções' : 'Pergunta e resposta');
        final rType = q['responseType']?.toString() ?? 'Texto';
        
        for (var o in (q['options'] as List? ?? [])) {
          optConts.add(TextEditingController(text: o['text']?.toString() ?? ''));
          ptConts.add(TextEditingController(text: o['points']?.toString() ?? '0'));
        }

        if (qType == 'Sim/Não' && optConts.length < 2) {
          optConts = [TextEditingController(text: 'Sim'), TextEditingController(text: 'Não')];
          ptConts = [TextEditingController(text: '10'), TextEditingController(text: '0')];
        }

        _questionControllers.add(QuestionControllerGroup(
          sectionController: TextEditingController(text: q['sectionTitle']?.toString() ?? ''),
          textController: TextEditingController(text: q['questionText']?.toString() ?? ''),
          curriculumMapping: q['curriculumMapping']?.toString() ?? 'Nenhum',
          questionType: qType,
          responseType: rType,
          optionControllers: optConts,
          pointControllers: ptConts,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _questionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questionControllers.add(QuestionControllerGroup(
        sectionController: TextEditingController(text: 'Geral'),
        textController: TextEditingController(),
        curriculumMapping: 'Nenhum',
        optionControllers: [TextEditingController(text: 'Sim'), TextEditingController(text: 'Não')],
        pointControllers: [TextEditingController(text: '10'), TextEditingController(text: '0')],
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      final qc = _questionControllers.removeAt(index);
      qc.dispose();
    });
  }

  void _addOption(QuestionControllerGroup qc) {
    setState(() {
      qc.optionControllers.add(TextEditingController());
      qc.pointControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeOption(QuestionControllerGroup qc, int index) {
    setState(() {
      final o = qc.optionControllers.removeAt(index);
      final p = qc.pointControllers.removeAt(index);
      o.dispose();
      p.dispose();
    });
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nome do questionário é obrigatório.')));
      return;
    }

    final questions = _questionControllers.map((qc) => qc.toMap()).toList();
    final q = AppQuestionnaire(
      id: widget.questionnaire?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      questions: questions,
    );
    widget.onSave(q);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.cardBorder)),
      child: Container(
        width: Responsive.dialogWidth(context, maxWidth: 800),
        height: MediaQuery.of(context).size.height * 0.85,
        padding: Responsive.dialogPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.questionnaire != null ? 'Editar Questionário' : 'Novo Questionário', style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                )
              ],
            ),
            const SizedBox(height: 24),
            // Nome do questionário
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NOME DO QUESTIONÁRIO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                    ),
                  )
                ],
              ),
            ),
            
            // Header Perguntas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PERGUNTAS', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Adicionar pergunta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Lista de Perguntas
            Expanded(
              child: _questionControllers.isEmpty
                  ? Center(child: Text('Nenhuma pergunta adicionada.', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5))))
                  : ListView.builder(
                      itemCount: _questionControllers.length,
                      itemBuilder: (context, index) {
                        final qc = _questionControllers[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.cardBorder)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildInput('Seção (Ex: Segurança)', qc.sectionController),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 4,
                                      child: _buildInput('Texto da Pergunta', qc.textController),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('MAPEAMENTO CURRÍCULO', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                      onPressed: () => _removeQuestion(index),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Question Type and Response Type selection
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('TIPO DE PERGUNTA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                                value: qc.questionType,
                                                dropdownColor: Colors.white,
                                                isExpanded: true,
                                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                                items: ['Opções', 'Pergunta e resposta', 'Texto', 'Sim/Não', 'Múltiplas opções escolha'].map((opt) {
                                                  return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(color: AppColors.textPrimary)));
                                                }).toList(),
                                                onChanged: (v) {
                                                  setState(() {
                                                    qc.questionType = v ?? 'Opções';
                                                    if (qc.questionType == 'Sim/Não') {
                                                      qc.optionControllers.clear();
                                                      qc.pointControllers.clear();
                                                      qc.optionControllers.addAll([TextEditingController(text: 'Sim'), TextEditingController(text: 'Não')]);
                                                      qc.pointControllers.addAll([TextEditingController(text: '10'), TextEditingController(text: '0')]);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: qc.questionType == 'Pergunta e resposta'
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('TIPO DE RESPOSTA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                                      value: qc.responseType,
                                                      dropdownColor: Colors.white,
                                                      isExpanded: true,
                                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                                      items: ['Texto', 'Inteiro', 'Decimal', 'Moeda', 'Data', 'Hora'].map((opt) {
                                                        return DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(color: AppColors.textPrimary)));
                                                      }).toList(),
                                                      onChanged: (v) {
                                                        setState(() {
                                                          qc.responseType = v ?? 'Texto';
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                                
                                // Option controllers display
                                if (qc.questionType == 'Opções' || qc.questionType == 'Múltiplas opções escolha') ...[
                                  const SizedBox(height: 16),
                                  const Text('OPÇÕES DE RESPOSTA E PONTUAÇÃO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  ...List.generate(qc.optionControllers.length, (optIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: TextField(
                                              controller: qc.optionControllers[optIndex],
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                hintText: 'Opção (Ex: Sim)',
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: qc.pointControllers[optIndex],
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                hintText: 'Pontos (Ex: 10)',
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                            onPressed: () => _removeOption(qc, optIndex),
                                          )
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => _addOption(qc),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Adicionar Opção', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                ] else if (qc.questionType == 'Sim/Não') ...[
                                  const SizedBox(height: 16),
                                  const Text('PONTUAÇÃO DAS RESPOSTAS', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('SIM (PONTOS)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: qc.pointControllers[0],
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('NÃO (PONTOS)', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                            const SizedBox(height: 6),
                                            TextField(
                                              controller: qc.pointControllers[1],
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 13),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Salvar Questionário', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
          ),
        ),
      ],
    );
  }
}
