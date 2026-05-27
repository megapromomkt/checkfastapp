import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../core/constants/premium_theme.dart';
import '../../../models/register_models.dart';
import '../../../core/services/register_service.dart';

class ProjectWizardView extends StatefulWidget {
  final AppClient? client;
  final AppProject? project; // Adicionado para edição
  final Function() onFinished;

  const ProjectWizardView({
    super.key, 
    this.client, 
    this.project,
    required this.onFinished
  });

  @override
  State<ProjectWizardView> createState() => _ProjectWizardViewState();
}

class _ProjectWizardViewState extends State<ProjectWizardView> {
  final _api = RegisterService();
  int _currentStep = 0;
  List<AppQuestionnaire> _questionnaires = [];
  String? _selectedQuestionnaireId;

  // Controllers - Passo 1: Cliente
  final _clientNameCtrl = TextEditingController();
  final _clientCnpjCtrl = TextEditingController(text: '00.000.000/0001-00');

  // Controllers - Identificação do Projeto
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController(text: 'ATC-FCX-001');
  String _type = 'Frente de Caixa';
  String _status = 'Implantação';
  String _operationalModel = 'Exclusivo';
  String _department = 'Operações';
  String _category = 'Promotoria';
  String _level = 'Operacional';

  // Controllers - Descritivo

  final _objectiveCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();
  final _slaCtrl = TextEditingController();

  // Controllers - Responsáveis
  final _commercialCtrl = TextEditingController();
  final _coordinatorCtrl = TextEditingController();
  final _supervisorCtrl = TextEditingController();
  final _financeCtrl = TextEditingController();
  final _clientRespCtrl = TextEditingController();

  // Regras
  bool _requiresCheckIn = true;
  bool _requiresGeoloc = true;
  bool _requiresPhoto = true;
  bool _requiresQrCode = false;
  bool _requiresSupervisorApproval = true;
  bool _requiresClientApproval = false;

  // Financeiro
  final _projectValueCtrl = TextEditingController();
  String _billingModel = 'Por diária';
  final _slaBillingCtrl = TextEditingController();
  final _slaPaymentCtrl = TextEditingController();

  // Parâmetros Operacionais (Novos)
  final _locationRadiusCtrl = TextEditingController(text: '200');
  final _maxJourneyHoursCtrl = TextEditingController(text: '8');
  bool _blockCheckoutISO = true;
  bool _useInternalCamera = true;
  bool _showMatrixValues = false;

  // Governança Financeira (Solicitação do Usuário)
  final _closingDayCtrl = TextEditingController(text: '25');
  String _closingPeriod = '26 ao 25';
  String _closingCompetence = 'Mensal';
  bool _closingAutomaticCut = true;
  bool _allowsPostAdjustment = false;
  String _clientPaymentTerms = '30 dias';
  String _clientPaymentMethod = 'Boleto';
  String _contractType = 'Freelancer';
  String _paymentForm = 'PIX';
  String _workerPaymentFrequency = 'Semanal';


  @override
  void initState() {
    super.initState();
    _loadQuestionnaires();
    if (widget.project != null) {
      _nameCtrl.text = widget.project!.name;
      _codeCtrl.text = widget.project!.code;
      _type = widget.project!.type;
      _status = widget.project!.status;
      _operationalModel = widget.project!.operationalModel;
      _objectiveCtrl.text = widget.project!.objective;
      _scopeCtrl.text = widget.project!.scope;
      _slaCtrl.text = widget.project!.sla;
      _commercialCtrl.text = widget.project!.commercialResponsible;
      _coordinatorCtrl.text = widget.project!.coordinator;
      _supervisorCtrl.text = widget.project!.supervisor;
      _financeCtrl.text = widget.project!.financeResponsible;
      _clientRespCtrl.text = widget.project!.clientResponsible;
      _requiresCheckIn = widget.project!.requiresCheckIn;
      _requiresGeoloc = widget.project!.requiresGeoloc;
      _requiresPhoto = widget.project!.requiresPhoto;
      _requiresQrCode = widget.project!.requiresQrCode;
      _requiresSupervisorApproval = widget.project!.requiresSupervisorApproval;
      _requiresClientApproval = widget.project!.requiresClientApproval;
      _projectValueCtrl.text = widget.project!.projectValue.toString();
      _billingModel = widget.project!.billingModel;
      _slaBillingCtrl.text = widget.project!.slaBilling;
      _slaPaymentCtrl.text = widget.project!.slaPayment;
      _locationRadiusCtrl.text = widget.project!.locationRadius.toString();
      _blockCheckoutISO = widget.project!.blockCheckoutISO;
      _useInternalCamera = widget.project!.useInternalCamera;
      _showMatrixValues = widget.project!.showMatrixValues;
      _maxJourneyHoursCtrl.text = widget.project!.maxJourneyHours.toString();
      _department = widget.project!.department;
      _category = widget.project!.category;
      _level = widget.project!.level;
      _closingDayCtrl.text = widget.project!.closingDay.toString();
      _closingPeriod = widget.project!.closingPeriod;
      _closingCompetence = widget.project!.closingCompetence;
      _closingAutomaticCut = widget.project!.closingAutomaticCut;
      _allowsPostAdjustment = widget.project!.allowsPostAdjustment;
      _clientPaymentTerms = widget.project!.clientPaymentTerms;
      _clientPaymentMethod = widget.project!.clientPaymentMethod;
      _contractType = widget.project!.contractType;
      _paymentForm = widget.project!.paymentForm;
      _workerPaymentFrequency = widget.project!.workerPaymentFrequency;
      _currentStep = 1; // Pula o passo do cliente se for edição de projeto
      _selectedQuestionnaireId = widget.project!.questionnaireId;
    } else if (widget.client != null) {
      _clientNameCtrl.text = widget.client!.name;
      _clientCnpjCtrl.text = widget.client!.cnpj;
      _nameCtrl.text = '${widget.client!.name} - Novo Projeto';
      _currentStep = 1; 
    }
  }

  void _loadQuestionnaires() async {
    try {
      final list = await _api.getQuestionnaires();
      setState(() {
        _questionnaires = list;
        if (widget.project != null) {
          _selectedQuestionnaireId = widget.project!.questionnaireId;
        }
      });
    } catch (e) {
      print('Erro ao carregar questionários: $e');
    }
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientCnpjCtrl.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _objectiveCtrl.dispose();
    _scopeCtrl.dispose();
    _slaCtrl.dispose();
    _commercialCtrl.dispose();
    _coordinatorCtrl.dispose();
    _supervisorCtrl.dispose();
    _financeCtrl.dispose();
    _clientRespCtrl.dispose();
    _projectValueCtrl.dispose();
    _slaBillingCtrl.dispose();
    _slaPaymentCtrl.dispose();
    _locationRadiusCtrl.dispose();
    _maxJourneyHoursCtrl.dispose();
    _closingDayCtrl.dispose();
    super.dispose();

  }

  void _save() async {
    String clientId = widget.project?.clientId ?? widget.client?.id ?? DateTime.now().toString();

    // Se for cliente novo, salva ele primeiro
    if (widget.client == null && widget.project == null) {
      final newClient = AppClient(
        id: clientId,
        name: _clientNameCtrl.text,
        cnpj: _clientCnpjCtrl.text,
      );
      await _api.saveClient(newClient);
    }

    // Salva o projeto
    final projectToSave = AppProject(
      id: widget.project?.id ?? DateTime.now().toString(), // Mantém o ID se for edição
      name: _nameCtrl.text,
      clientId: clientId,
      type: _type,
      code: _codeCtrl.text,
      status: _status,
      operationalModel: _operationalModel,
      objective: _objectiveCtrl.text,
      scope: _scopeCtrl.text,
      sla: _slaCtrl.text,
      commercialResponsible: _commercialCtrl.text,
      coordinator: _coordinatorCtrl.text,
      supervisor: _supervisorCtrl.text,
      financeResponsible: _financeCtrl.text,
      clientResponsible: _clientRespCtrl.text,
      requiresCheckIn: _requiresCheckIn,
      requiresGeoloc: _requiresGeoloc,
      requiresPhoto: _requiresPhoto,
      requiresQrCode: _requiresQrCode,
      requiresSupervisorApproval: _requiresSupervisorApproval,
      requiresClientApproval: _requiresClientApproval,
      projectValue: double.tryParse(_projectValueCtrl.text) ?? 0.0,
      billingModel: _billingModel,
      slaBilling: _slaBillingCtrl.text,
      slaPayment: _slaPaymentCtrl.text,
      locationRadius: int.tryParse(_locationRadiusCtrl.text) ?? 200,
      blockCheckoutISO: _blockCheckoutISO,
      useInternalCamera: _useInternalCamera,
      showMatrixValues: _showMatrixValues,
      maxJourneyHours: int.tryParse(_maxJourneyHoursCtrl.text) ?? 8,
      department: _department,
      category: _category,
      level: _level,
      closingDay: int.tryParse(_closingDayCtrl.text) ?? 25,
      closingPeriod: _closingPeriod,
      closingCompetence: _closingCompetence,
      closingAutomaticCut: _closingAutomaticCut,
      allowsPostAdjustment: _allowsPostAdjustment,
      clientPaymentTerms: _clientPaymentTerms,
      clientPaymentMethod: _clientPaymentMethod,
      contractType: _contractType,
      paymentForm: _paymentForm,
      workerPaymentFrequency: _workerPaymentFrequency,
      questionnaireId: _selectedQuestionnaireId,
    );

    await _api.saveProject(projectToSave);

    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildStepperHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStepContent(),
            ),
          ),
          const SizedBox(height: 32),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(IconsaxPlusLinear.document_sketch, color: AppColors.primaryBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.project != null ? 'Editando Projeto' : 'Esteira de Cadastro', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(widget.project != null ? 'Atualizando dados do projeto' : (widget.client != null ? 'Adicionando projeto para ${widget.client!.name}' : 'Cadastrando novo cliente e projeto'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepperHeader() {
    final steps = ['Cliente', 'Identificação', 'Descritivo', 'Regras', 'Financeiro'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isPast = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryBlue : (isPast ? AppColors.success : AppColors.background),
                  shape: BoxShape.circle,
                  border: Border.all(color: isActive ? AppColors.primaryBlue : (isPast ? AppColors.success : AppColors.cardBorder)),
                ),
                child: Center(
                  child: isPast 
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${index}', style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Text(steps[index], style: TextStyle(color: isActive ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
              if (index < steps.length - 1) ...[
                const SizedBox(width: 12),
                Expanded(child: Divider(color: isPast ? AppColors.success : AppColors.cardBorder, thickness: 2)),
                const SizedBox(width: 12),
              ]
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _buildStepClient();
      case 1: return _buildStepIdentification();
      case 2: return _buildStepDescription();
      case 3: return _buildStepRules();
      case 4: return _buildStepFinancial();
      default: return const SizedBox();
    }
  }

  Widget _buildStepClient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Nome do Cliente', _clientNameCtrl),
        _buildTextField('CNPJ', _clientCnpjCtrl),
      ],
    );
  }

  Widget _buildStepIdentification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Nome do Projeto', _nameCtrl),
        _buildTextField('Código do Projeto', _codeCtrl),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Departamento', _department, [
                'Operações', 'Trade Marketing', 'Eventos', 'Outsourcing', 'Comercial', 'RH', 'Financeiro', 'Qualidade Contínua', 'Tecnologia', 'Logística', 'Facilities', 'Administrativo', 'Diretoria', 'Jurídico', 'Marketing', 'Atendimento', 'Compras', 'Projetos', 'Inteligência de Mercado'
              ], (val) => setState(() => _department = val!)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown('Categoria', _category, [
                'Promotoria', 'Reposição', 'Frente de Caixa', 'Mercearia', 'Bebidas', 'Refrigerados', 'Hortifruti', 'Açougue', 'Farma', 'Merchandising', 'Positivação', 'Degustação', 'Sampling', 'PDV', 'Auditoria', 'Pesquisa', 'Eventos', 'Recepção', 'Atendimento', 'Facilities', 'Limpeza', 'Portaria', 'Logística', 'Estoque', 'Transporte', 'Administrativo', 'Backoffice', 'Financeiro', 'RH', 'Recrutamento', 'Tecnologia', 'Suporte Técnico', 'BI / Dados', 'Comercial', 'Coordenação', 'Supervisão', 'Gestão', 'Qualidade', 'Compliance', 'Treinamento', 'Implantação', 'Expansão', 'Inteligência Mercado'
              ], (val) => setState(() => _category = val!)),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Nível Hierárquico', _level, ['Auxiliar', 'Assistente', 'Operacional', 'Técnico', 'Especialista', 'Líder', 'Supervisor', 'Coordenador', 'Gerente', 'Diretor'], (val) => setState(() => _level = val!)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown('Tipo de Atuação', _type, [
                'Frente de Caixa', 'Reposição', 'Mercearia', 'Bebidas', 'Refrigerados', 'Hortifruti', 'Açougue', 'Farma', 'Degustação', 'Sampling', 'PDV', 'Auditoria', 'Pesquisa', 'Merchandising', 'Eventos', 'Positivação', 'Exclusivo', 'Compartilhado', 'Híbrido'
              ], (val) => setState(() => _type = val!)),
            ),
          ],
        ),
        _buildDropdown('Status do Projeto', _status, ['Implantação', 'Ativo', 'Pausado', 'Encerrado', 'Sazonal'], (val) => setState(() => _status = val!)),
        _buildDropdown('Modelo Operacional', _operationalModel, ['Exclusivo', 'Compartilhado', 'Híbrido', 'Temporário', 'Fixo', 'Sazonal'], (val) => setState(() => _operationalModel = val!)),
      ],
    );

  }

  Widget _buildStepDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Objetivo do Projeto', _objectiveCtrl, maxLines: 3),
        _buildTextField('Escopo Operacional', _scopeCtrl, maxLines: 5),
        _buildTextField('SLA Operacional', _slaCtrl, maxLines: 3),
        const SizedBox(height: 20),
        const Text('RESPONSÁVEIS', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildTextField('Comercial Responsável', _commercialCtrl),
        _buildTextField('Coordenador Operacional', _coordinatorCtrl),
        _buildTextField('Supervisor Responsável', _supervisorCtrl),
        _buildTextField('Cliente Responsável', _clientRespCtrl),
      ],
    );
  }

  Widget _buildStepRules() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('REGRAS DO PROJETO', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildSwitch('Check-in Obrigatório', _requiresCheckIn, (val) => setState(() => _requiresCheckIn = val)),
        _buildSwitch('Geolocalização Obrigatória', _requiresGeoloc, (val) => setState(() => _requiresGeoloc = val)),
        _buildSwitch('Evidência Fotográfica Obrigatória', _requiresPhoto, (val) => setState(() => _requiresPhoto = val)),
        _buildSwitch('QR Code Obrigatório', _requiresQrCode, (val) => setState(() => _requiresQrCode = val)),
        _buildSwitch('Aprovação do Supervisor Necessária', _requiresSupervisorApproval, (val) => setState(() => _requiresSupervisorApproval = val)),
        _buildSwitch('Aprovação do Cliente Necessária', _requiresClientApproval, (val) => setState(() => _requiresClientApproval = val)),
        const SizedBox(height: 20),
        const Text('TRAVAS DE SEGURANÇA (ISO 9001)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildSwitch('Bloquear Checkout fora do raio', _blockCheckoutISO, (val) => setState(() => _blockCheckoutISO = val)),
        _buildTextField('Raio de Segurança (metros)', _locationRadiusCtrl),
        const SizedBox(height: 10),
        _buildSwitch('Usar Câmera Interna no Aplicativo', _useInternalCamera, (val) => setState(() => _useInternalCamera = val)),
        _buildSwitch('Permitir Ver Valores da Matriz', _showMatrixValues, (val) => setState(() => _showMatrixValues = val)),
        _buildTextField('Tempo Máximo de Jornada (horas)', _maxJourneyHoursCtrl),
        const SizedBox(height: 20),
        const Text('QUESTIONÁRIO DO PROJETO', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildQuestionnaireDropdown(),
      ],
    );
  }

  Widget _buildQuestionnaireDropdown() {
    final value = _questionnaires.any((q) => q.id == _selectedQuestionnaireId) ? _selectedQuestionnaireId : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECIONE O QUESTIONÁRIO VINCULADO', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            value: value,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Nenhum / Sem Questionário', style: TextStyle(fontSize: 15))),
              ..._questionnaires.map((q) => DropdownMenuItem<String?>(value: q.id, child: Text(q.name, style: const TextStyle(fontSize: 15)))),
            ],
            onChanged: (val) {
              setState(() {
                _selectedQuestionnaireId = val;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepFinancial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FATURAMENTO (CLIENTE)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildTextField('Valor do Projeto', _projectValueCtrl),
        _buildDropdown('Modelo de Cobrança', _billingModel, ['Mensal', 'Por visita', 'Por diária', 'Por loja', 'Por colaborador'], (val) => setState(() => _billingModel = val!)),
        _buildDropdown('Prazo de Pagamento (Cliente)', _clientPaymentTerms, ['À vista', 'D+1', '7 dias', '14 dias', '21 dias', '28 dias', '30 dias', '45 dias', '60 dias', 'D+7', 'D+15', 'D+28', 'D+30 faturado'], (val) => setState(() => _clientPaymentTerms = val!)),

        _buildDropdown('Meio de Pagamento (Cliente)', _clientPaymentMethod, ['Boleto', 'PIX', 'Transferência', 'Cartão corporativo'], (val) => setState(() => _clientPaymentMethod = val!)),
        
        const SizedBox(height: 32),
        const Text('REGRA DE FECHAMENTO', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildTextField('Dia de Fechamento', _closingDayCtrl),
        _buildDropdown('Período de Apuração', _closingPeriod, ['21 ao 20', '26 ao 25', '01 ao 30', '16 ao 15'], (val) => setState(() => _closingPeriod = val!)),
        _buildDropdown('Competência', _closingCompetence, ['Mês atual', 'Mês subsequente', 'Mensal', 'Semanal'], (val) => setState(() => _closingCompetence = val!)),
        _buildSwitch('Corte Automático?', _closingAutomaticCut, (val) => setState(() => _closingAutomaticCut = val)),
        _buildSwitch('Permite Ajuste Pós-Fechamento?', _allowsPostAdjustment, (val) => setState(() => _allowsPostAdjustment = val)),

        const SizedBox(height: 32),
        const Text('PAGAMENTO DO COLABORADOR', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        _buildDropdown('Tipo de Contratação', _contractType, ['CLT', 'PJ', 'Freelancer', 'Diarista', 'Cooperado', 'Temporário'], (val) => setState(() => _contractType = val!)),
        _buildDropdown('Forma de Pagamento', _paymentForm, ['PIX', 'Depósito Bancário', 'Cartão Benefício', 'Espécie'], (val) => setState(() => _paymentForm = val!)),
        _buildDropdown('Frequência de Pagamento', _workerPaymentFrequency, ['Semanal', 'Quinzenal', 'Mensal', 'D+1', 'D+7', 'D+15', 'D+30'], (val) => setState(() => _workerPaymentFrequency = val!)),

      ],
    );

  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0 && widget.project == null && widget.client == null)
          OutlinedButton(
            onPressed: () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            child: const Text('Voltar'),
          )
        else
          const SizedBox(),
        ElevatedButton(
          onPressed: () {
            if (_currentStep < 4) {
              setState(() => _currentStep++);
            } else {
              _save();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(_currentStep < 4 ? 'Avançar' : 'Salvar Alterações'),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: maxLines,
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

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 15)))).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}
