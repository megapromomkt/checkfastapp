class AppClient {
  String id;
  String name;
  String cnpj;
  String type;
  String paymentTerm;
  String responsible;
  String contact;

  AppClient({
    required this.id,
    required this.name,
    this.cnpj = '',
    this.type = 'Indústria',
    this.paymentTerm = '30 dias',
    this.responsible = '',
    this.contact = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cnpj': cnpj,
      'type': type,
      'paymentTerm': paymentTerm,
      'responsible': responsible,
      'contact': contact,
    };
  }

  factory AppClient.fromMap(Map<String, dynamic> map) {
    return AppClient(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      cnpj: map['cnpj'] ?? '',
      type: map['type'] ?? 'Indústria',
      paymentTerm: map['paymentTerm'] ?? '30 dias',
      responsible: map['responsible'] ?? '',
      contact: map['contact'] ?? '',
    );
  }
}

class AppProject {
  String id;
  String name;
  String clientId;
  
  // BLOCO 1
  String type; 
  String code; 
  String status; 
  String operationalModel; 
  String department;
  String category;
  String level;
  
  // BLOCO 2
  String objective;
  String scope;
  String sla;
  
  // BLOCO 3
  String commercialResponsible;
  String coordinator;
  String supervisor;
  String financeResponsible;
  String clientResponsible;
  
  // BLOCO 5 (Regras)
  bool requiresCheckIn;
  bool requiresGeoloc;
  bool requiresPhoto;
  bool requiresQrCode;
  bool requiresSupervisorApproval;
  bool requiresClientApproval;
  
  // BLOCO 6
  double projectValue;
  String billingModel;
  String slaBilling;
  String slaPayment;
  
  // BLOCO 7
  String contractUrl;
  String slaUrl;
  String manualUrl;
  String trainingUrl;
  String layoutUrl;
  
  // BLOCO 8
  List<String> kpis;
  
  // BLOCO 9
  String paymentModel;
  
  // Regras de Validação
  bool validationCheckIn;
  bool validationCheckout;
  bool validationGeoloc;
  bool validationPhoto;
  bool validationQrCode;
  String minStayTime;
  bool validationForm;
  bool validationSignature;
  
  // Regras de Aprovação
  bool approveSupervisor;
  bool approveCoordinator;
  bool approveClient;
  bool approveAutomatic;
  
  // Regras Financeiras
  double baseValue;
  bool hasKmAditional;
  double kmValue;
  double extraStoreValue;
  double urgencyValue;
  double nightValue;
  List<String> costHelp; 
  
  // Penalidades
  bool discountMiss;
  bool discountDelay;
  bool discountNoEvidence;
  bool discountInvalidGeoloc;

  // Status Operacionais
  String operationalStatusValid;
  String operationalStatusPending;
  String operationalStatusInconsistent;
  String operationalStatusRejected;

  // SLA Financeiro
  String slaOperationalApproval;
  String slaBillingDays;
  String slaPaymentDays;
  
  // Parâmetros Operacionais (migrados de Configurações Gerais)
  int locationRadius; // Em metros
  bool blockCheckoutISO;
  bool useInternalCamera;
  bool showMatrixValues;
  int maxJourneyHours;

  // NOVOS: Regras de Fechamento e Pagamento (Demanda do Usuário)
  int closingDay;
  String closingPeriod;
  String closingCompetence;
  bool closingAutomaticCut;
  bool allowsPostAdjustment;
  String clientPaymentTerms;
  String clientPaymentMethod;
  String contractType;
  String paymentForm;
  String workerPaymentFrequency;
  String? questionnaireId;


  AppProject({
    required this.id,
    required this.name,
    required this.clientId,
    this.type = 'Exclusivo',
    this.code = '',
    this.status = 'Implantação',
    this.operationalModel = 'Exclusivo',
    this.department = 'Operações',
    this.category = 'Promotoria',
    this.level = 'Operacional',
    this.objective = '',

    this.scope = '',
    this.sla = '',
    this.commercialResponsible = '',
    this.coordinator = '',
    this.supervisor = '',
    this.financeResponsible = '',
    this.clientResponsible = '',
    this.requiresCheckIn = true,
    this.requiresGeoloc = true,
    this.requiresPhoto = true,
    this.requiresQrCode = false,
    this.requiresSupervisorApproval = true,
    this.requiresClientApproval = false,
    this.projectValue = 0.0,
    this.billingModel = 'Por diária',
    this.slaBilling = '',
    this.slaPayment = '',
    this.contractUrl = '',
    this.slaUrl = '',
    this.manualUrl = '',
    this.trainingUrl = '',
    this.layoutUrl = '',
    this.kpis = const [],
    this.paymentModel = 'Por diária',
    this.validationCheckIn = true,
    this.validationCheckout = true,
    this.validationGeoloc = true,
    this.validationPhoto = true,
    this.validationQrCode = false,
    this.minStayTime = '',
    this.validationForm = false,
    this.validationSignature = false,
    this.approveSupervisor = true,
    this.approveCoordinator = false,
    this.approveClient = false,
    this.approveAutomatic = false,
    this.baseValue = 0.0,
    this.hasKmAditional = false,
    this.kmValue = 0.0,
    this.extraStoreValue = 0.0,
    this.urgencyValue = 0.0,
    this.nightValue = 0.0,
    this.costHelp = const [],
    this.discountMiss = false,
    this.discountDelay = false,
    this.discountNoEvidence = false,
    this.discountInvalidGeoloc = false,
    this.operationalStatusValid = 'Pagamento integral',
    this.operationalStatusPending = 'Aguardando aprovação',
    this.operationalStatusInconsistent = 'Vai para auditoria',
    this.operationalStatusRejected = 'Necessita justificativa',
    this.slaOperationalApproval = '',
    this.slaBillingDays = '',
    this.slaPaymentDays = '',
    this.locationRadius = 200,
    this.blockCheckoutISO = true,
    this.useInternalCamera = true,
    this.showMatrixValues = false,
    this.maxJourneyHours = 8,
    this.closingDay = 25,
    this.closingPeriod = '26 ao 25',
    this.closingCompetence = 'Mensal',
    this.closingAutomaticCut = true,
    this.allowsPostAdjustment = false,
    this.clientPaymentTerms = '30 dias',
    this.clientPaymentMethod = 'Boleto',
    this.contractType = 'Freelancer',
    this.paymentForm = 'PIX',
    this.workerPaymentFrequency = 'Semanal',
    this.questionnaireId,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientId': clientId,
      'type': type,
      'code': code,
      'status': status,
      'operationalModel': operationalModel,
      'department': department,
      'category': category,
      'level': level,
      'objective': objective,

      'scope': scope,
      'sla': sla,
      'commercialResponsible': commercialResponsible,
      'coordinator': coordinator,
      'supervisor': supervisor,
      'financeResponsible': financeResponsible,
      'clientResponsible': clientResponsible,
      'requiresCheckIn': requiresCheckIn,
      'requiresGeoloc': requiresGeoloc,
      'requiresPhoto': requiresPhoto,
      'requiresQrCode': requiresQrCode,
      'requiresSupervisorApproval': requiresSupervisorApproval,
      'requiresClientApproval': requiresClientApproval,
      'projectValue': projectValue,
      'billingModel': billingModel,
      'slaBilling': slaBilling,
      'slaPayment': slaPayment,
      'contractUrl': contractUrl,
      'slaUrl': slaUrl,
      'manualUrl': manualUrl,
      'trainingUrl': trainingUrl,
      'layoutUrl': layoutUrl,
      'kpis': kpis,
      'paymentModel': paymentModel,
      'validationCheckIn': validationCheckIn,
      'validationCheckout': validationCheckout,
      'validationGeoloc': validationGeoloc,
      'validationPhoto': validationPhoto,
      'validationQrCode': validationQrCode,
      'minStayTime': minStayTime,
      'validationForm': validationForm,
      'validationSignature': validationSignature,
      'approveSupervisor': approveSupervisor,
      'approveCoordinator': approveCoordinator,
      'approveClient': approveClient,
      'approveAutomatic': approveAutomatic,
      'baseValue': baseValue,
      'hasKmAditional': hasKmAditional,
      'kmValue': kmValue,
      'extraStoreValue': extraStoreValue,
      'urgencyValue': urgencyValue,
      'nightValue': nightValue,
      'costHelp': costHelp,
      'discountMiss': discountMiss,
      'discountDelay': discountDelay,
      'discountNoEvidence': discountNoEvidence,
      'discountInvalidGeoloc': discountInvalidGeoloc,
      'operationalStatusValid': operationalStatusValid,
      'operationalStatusPending': operationalStatusPending,
      'operationalStatusInconsistent': operationalStatusInconsistent,
      'operationalStatusRejected': operationalStatusRejected,
      'slaOperationalApproval': slaOperationalApproval,
      'slaBillingDays': slaBillingDays,
      'slaPaymentDays': slaPaymentDays,
      'locationRadius': locationRadius,
      'blockCheckoutISO': blockCheckoutISO,
      'useInternalCamera': useInternalCamera,
      'showMatrixValues': showMatrixValues,
      'maxJourneyHours': maxJourneyHours,
      'closingDay': closingDay,
      'closingPeriod': closingPeriod,
      'closingCompetence': closingCompetence,
      'closingAutomaticCut': closingAutomaticCut,
      'allowsPostAdjustment': allowsPostAdjustment,
      'clientPaymentTerms': clientPaymentTerms,
      'clientPaymentMethod': clientPaymentMethod,
      'contractType': contractType,
      'paymentForm': paymentForm,
      'workerPaymentFrequency': workerPaymentFrequency,
      'questionnaireId': questionnaireId,
    };

  }

  factory AppProject.fromMap(Map<String, dynamic> map) {
    return AppProject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      clientId: map['clientId'] ?? '',
      type: map['type'] ?? 'Exclusivo',
      code: map['code'] ?? '',
      status: map['status'] ?? 'Implantação',
      operationalModel: map['operationalModel'] ?? 'Exclusivo',
      department: map['department'] ?? 'Operações',
      category: map['category'] ?? 'Promotoria',
      level: map['level'] ?? 'Operacional',
      objective: map['objective'] ?? '',

      scope: map['scope'] ?? '',
      sla: map['sla'] ?? '',
      commercialResponsible: map['commercialResponsible'] ?? '',
      coordinator: map['coordinator'] ?? '',
      supervisor: map['supervisor'] ?? '',
      financeResponsible: map['financeResponsible'] ?? '',
      clientResponsible: map['clientResponsible'] ?? '',
      requiresCheckIn: map['requiresCheckIn'] ?? true,
      requiresGeoloc: map['requiresGeoloc'] ?? true,
      requiresPhoto: map['requiresPhoto'] ?? true,
      requiresQrCode: map['requiresQrCode'] ?? false,
      requiresSupervisorApproval: map['requiresSupervisorApproval'] ?? true,
      requiresClientApproval: map['requiresClientApproval'] ?? false,
      projectValue: (map['projectValue'] ?? 0.0).toDouble(),
      billingModel: map['billingModel'] ?? 'Por diária',
      slaBilling: map['slaBilling'] ?? '',
      slaPayment: map['slaPayment'] ?? '',
      contractUrl: map['contractUrl'] ?? '',
      slaUrl: map['slaUrl'] ?? '',
      manualUrl: map['manualUrl'] ?? '',
      trainingUrl: map['trainingUrl'] ?? '',
      layoutUrl: map['layoutUrl'] ?? '',
      kpis: List<String>.from(map['kpis'] ?? []),
      paymentModel: map['paymentModel'] ?? 'Por diária',
      validationCheckIn: map['validationCheckIn'] ?? true,
      validationCheckout: map['validationCheckout'] ?? true,
      validationGeoloc: map['validationGeoloc'] ?? true,
      validationPhoto: map['validationPhoto'] ?? true,
      validationQrCode: map['validationQrCode'] ?? false,
      minStayTime: map['minStayTime'] ?? '',
      validationForm: map['validationForm'] ?? false,
      validationSignature: map['validationSignature'] ?? false,
      approveSupervisor: map['approveSupervisor'] ?? true,
      approveCoordinator: map['approveCoordinator'] ?? false,
      approveClient: map['approveClient'] ?? false,
      approveAutomatic: map['approveAutomatic'] ?? false,
      baseValue: (map['baseValue'] ?? 0.0).toDouble(),
      hasKmAditional: map['hasKmAditional'] ?? false,
      kmValue: (map['kmValue'] ?? 0.0).toDouble(),
      extraStoreValue: (map['extraStoreValue'] ?? 0.0).toDouble(),
      urgencyValue: (map['urgencyValue'] ?? 0.0).toDouble(),
      nightValue: (map['nightValue'] ?? 0.0).toDouble(),
      costHelp: List<String>.from(map['costHelp'] ?? []),
      discountMiss: map['discountMiss'] ?? false,
      discountDelay: map['discountDelay'] ?? false,
      discountNoEvidence: map['discountNoEvidence'] ?? false,
      discountInvalidGeoloc: map['discountInvalidGeoloc'] ?? false,
      operationalStatusValid: map['operationalStatusValid'] ?? 'Pagamento integral',
      operationalStatusPending: map['operationalStatusPending'] ?? 'Aguardando aprovação',
      operationalStatusInconsistent: map['operationalStatusInconsistent'] ?? 'Vai para auditoria',
      operationalStatusRejected: map['operationalStatusRejected'] ?? 'Necessita justificativa',
      slaOperationalApproval: map['slaOperationalApproval'] ?? '',
      slaBillingDays: map['slaBillingDays'] ?? '',
      slaPaymentDays: map['slaPaymentDays'] ?? '',
      locationRadius: map['locationRadius'] ?? 200,
      blockCheckoutISO: map['blockCheckoutISO'] ?? true,
      useInternalCamera: map['useInternalCamera'] ?? true,
      showMatrixValues: map['showMatrixValues'] ?? false,
      maxJourneyHours: map['maxJourneyHours'] ?? 8,
      closingDay: map['closingDay'] ?? 25,
      closingPeriod: map['closingPeriod'] ?? '26 ao 25',
      closingCompetence: map['closingCompetence'] ?? 'Mensal',
      closingAutomaticCut: map['closingAutomaticCut'] ?? true,
      allowsPostAdjustment: map['allowsPostAdjustment'] ?? false,
      clientPaymentTerms: map['clientPaymentTerms'] ?? '30 dias',
      clientPaymentMethod: map['clientPaymentMethod'] ?? 'Boleto',
      contractType: map['contractType'] ?? 'Freelancer',
      paymentForm: map['paymentForm'] ?? 'PIX',
      workerPaymentFrequency: map['workerPaymentFrequency'] ?? 'Semanal',
      questionnaireId: map['questionnaireId'],
    );
  }

}

class AppRede {
  String id;
  String name;
  bool inactive;

  AppRede({
    required this.id,
    required this.name,
    this.inactive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inactive': inactive,
    };
  }

  factory AppRede.fromMap(Map<String, dynamic> map) {
    return AppRede(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      inactive: map['inactive'] ?? false,
    );
  }
}

class AppBandeira {
  String id;
  String name;
  String redeId;
  bool inactive;

  AppBandeira({
    required this.id,
    required this.name,
    required this.redeId,
    this.inactive = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'redeId': redeId,
      'inactive': inactive,
    };
  }

  factory AppBandeira.fromMap(Map<String, dynamic> map) {
    return AppBandeira(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      redeId: map['redeId'] ?? '',
      inactive: map['inactive'] ?? false,
    );
  }
}

class AppStore {
  String id;
  String name;
  String clientId;
  
  // Novos campos das imagens
  String codigoCliente;
  String redeId;
  String bandeiraId;
  String cnpj;
  String vendedores;
  String subcanalId;
  String canalEstabelecimento;
  String status;
  String substatus;
  String filial;
  String dataInauguracao;
  String dataEncerramento;
  bool inactive;
  
  // Endereço
  String cep;
  String logradouro;
  String numero;
  String complemento;
  String bairro;
  String city;
  String state;
  String zona;
  String regional;
  
  // Geolocalização
  double latitude;
  double longitude;
  int locationRadius; 

  AppStore({
    required this.id,
    required this.name,
    required this.clientId,
    this.codigoCliente = '',
    this.redeId = '',
    this.bandeiraId = '',
    this.cnpj = '',
    this.vendedores = '',
    this.subcanalId = '',
    this.canalEstabelecimento = '',
    this.status = 'Ativo',
    this.substatus = '',
    this.filial = '',
    this.dataInauguracao = '',
    this.dataEncerramento = '',
    this.inactive = false,
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.complemento = '',
    this.bairro = '',
    this.city = '',
    this.state = '',
    this.zona = '',
    this.regional = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.locationRadius = 200,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientId': clientId,
      'codigoCliente': codigoCliente,
      'redeId': redeId,
      'bandeiraId': bandeiraId,
      'cnpj': cnpj,
      'vendedores': vendedores,
      'subcanalId': subcanalId,
      'canalEstabelecimento': canalEstabelecimento,
      'status': status,
      'substatus': substatus,
      'filial': filial,
      'dataInauguracao': dataInauguracao,
      'dataEncerramento': dataEncerramento,
      'inactive': inactive,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'city': city,
      'state': state,
      'zona': zona,
      'regional': regional,
      'latitude': latitude,
      'longitude': longitude,
      'locationRadius': locationRadius,
    };
  }

  factory AppStore.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 200;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 200;
      return 200;
    }

    return AppStore(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      clientId: map['clientId']?.toString() ?? '',
      codigoCliente: map['codigoCliente']?.toString() ?? '',
      redeId: map['redeId']?.toString() ?? '',
      bandeiraId: map['bandeiraId']?.toString() ?? '',
      cnpj: map['cnpj']?.toString() ?? '',
      vendedores: map['vendedores']?.toString() ?? '',
      subcanalId: map['subcanalId']?.toString() ?? '',
      canalEstabelecimento: map['canalEstabelecimento']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Ativo',
      substatus: map['substatus']?.toString() ?? '',
      filial: map['filial']?.toString() ?? '',
      dataInauguracao: map['dataInauguracao']?.toString() ?? '',
      dataEncerramento: map['dataEncerramento']?.toString() ?? '',
      inactive: map['inactive'] == true || map['inactive'] == 'true',
      cep: map['cep']?.toString() ?? '',
      logradouro: map['logradouro']?.toString() ?? '',
      numero: map['numero']?.toString() ?? '',
      complemento: map['complemento']?.toString() ?? '',
      bairro: map['bairro']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      zona: map['zona']?.toString() ?? '',
      regional: map['regional']?.toString() ?? '',
      latitude: parseDouble(map['latitude']),
      longitude: parseDouble(map['longitude']),
      locationRadius: parseInt(map['locationRadius']),
    );
  }
}

class AppRole {
  String id;
  String name;
  String department;
  String category;
  String level;
  String type;
  bool isActive;
  String description;

  AppRole({
    required this.id,
    required this.name,
    this.department = '',
    this.category = '',
    this.level = '',
    this.type = '',
    this.isActive = true,
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'category': category,
      'level': level,
      'type': type,
      'isActive': isActive,
      'description': description,
    };
  }

  factory AppRole.fromMap(Map<String, dynamic> map) {
    return AppRole(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      category: map['category'] ?? '',
      level: map['level'] ?? '',
      type: map['type'] ?? '',
      isActive: map['isActive'] ?? true,
      description: map['description'] ?? '',
    );
  }
}

class AppPaymentRule {
  String id;
  String name;
  String type;
  double baseValue;
  
  // 1. Regras de Medição
  String measurementType; // Presença, Visita, Hora, Diária, Produção, Sell Out, Positivação, Auditoria
  String billingUnit;
  String frequency;
  bool requiresApproval;

  // 3. Regra de Fechamento
  int closingDay;
  String closingPeriod;
  String closingCompetence;
  bool closingAutomaticCut;
  bool allowsPostAdjustment;

  // 4. Prazo de Pagamento (Cliente)
  String clientPaymentTerms; // À vista, 7 dias, D+30, etc
  String clientPaymentMethod; // Boleto, PIX, etc

  // 5. Regra de Pagamento do Colaborador
  String contractType; // CLT, PJ, Freelancer, etc
  String paymentForm; // PIX, Banco
  String workerPaymentFrequency; // Semanal, Quinzenal
  bool exigeEvidencia;
  bool pagamentoAutomatico;
  bool necessitaNF;

  // 6. Regra de Aprovação
  String approvalFlow; // Supervisor, Cliente, Backoffice, Auto
  int approvalSLA; // Em horas
  int autoApprovalHours;
  bool blockPaymentWithoutApproval;
  bool allowContestation;

  // 7. Regras Operacionais
  int toleranceLate; // Minutos
  int toleranceCheckout;
  bool exigeGeoloc;
  bool exigeFoto;
  bool exigeRoteiro;
  bool exigePesquisa;
  bool exigeRelatorio;

  // 9. Reembolso
  bool reimbursesKM;
  double kmValue;
  bool reimbursesToll;
  bool reimbursesParking;
  bool reimbursesFood;
  bool reimbursesLodging;
  double reimbursementDailyLimit;
  bool requiresReceipt;

  // 10. Impostos e Retenções
  bool retencaoISS;
  bool retencaoINSS;
  bool retencaoIR;
  String cnae;
  String costCenter;
  String natureOperation;

  // 13. Tipos de Cálculo Automático
  bool calcExtraHour;
  bool calcNightShift;
  bool calcDSR;
  bool calcInsalubridade;
  bool calcPericulosidade;
  bool calcBancoHoras;

  AppPaymentRule({
    required this.id,
    required this.name,
    this.type = 'Padrão',
    this.baseValue = 0.0,
    this.measurementType = 'Por presença',
    this.billingUnit = 'Unidade',
    this.frequency = 'Mensal',
    this.requiresApproval = true,
    this.closingDay = 25,
    this.closingPeriod = '26 ao 25',
    this.closingCompetence = 'Mensal',
    this.closingAutomaticCut = true,
    this.allowsPostAdjustment = false,
    this.clientPaymentTerms = '30 dias',
    this.clientPaymentMethod = 'Boleto',
    this.contractType = 'Freelancer',
    this.paymentForm = 'PIX',
    this.workerPaymentFrequency = 'Semanal',
    this.exigeEvidencia = true,
    this.pagamentoAutomatico = false,
    this.necessitaNF = false,
    this.approvalFlow = 'Supervisor aprova',
    this.approvalSLA = 48,
    this.autoApprovalHours = 72,
    this.blockPaymentWithoutApproval = true,
    this.allowContestation = true,
    this.toleranceLate = 15,
    this.toleranceCheckout = 10,
    this.exigeGeoloc = true,
    this.exigeFoto = true,
    this.exigeRoteiro = true,
    this.exigePesquisa = false,
    this.exigeRelatorio = true,
    this.reimbursesKM = false,
    this.kmValue = 0.0,
    this.reimbursesToll = false,
    this.reimbursesParking = false,
    this.reimbursesFood = false,
    this.reimbursesLodging = false,
    this.reimbursementDailyLimit = 0.0,
    this.requiresReceipt = true,
    this.retencaoISS = false,
    this.retencaoINSS = false,
    this.retencaoIR = false,
    this.cnae = '',
    this.costCenter = '',
    this.natureOperation = '',
    this.calcExtraHour = false,
    this.calcNightShift = false,
    this.calcDSR = false,
    this.calcInsalubridade = false,
    this.calcPericulosidade = false,
    this.calcBancoHoras = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'baseValue': baseValue,
      'measurementType': measurementType,
      'billingUnit': billingUnit,
      'frequency': frequency,
      'requiresApproval': requiresApproval,
      'closingDay': closingDay,
      'closingPeriod': closingPeriod,
      'closingCompetence': closingCompetence,
      'closingAutomaticCut': closingAutomaticCut,
      'allowsPostAdjustment': allowsPostAdjustment,
      'clientPaymentTerms': clientPaymentTerms,
      'clientPaymentMethod': clientPaymentMethod,
      'contractType': contractType,
      'paymentForm': paymentForm,
      'workerPaymentFrequency': workerPaymentFrequency,
      'exigeEvidencia': exigeEvidencia,
      'pagamentoAutomatico': pagamentoAutomatico,
      'necessitaNF': necessitaNF,
      'approvalFlow': approvalFlow,
      'approvalSLA': approvalSLA,
      'autoApprovalHours': autoApprovalHours,
      'blockPaymentWithoutApproval': blockPaymentWithoutApproval,
      'allowContestation': allowContestation,
      'toleranceLate': toleranceLate,
      'toleranceCheckout': toleranceCheckout,
      'exigeGeoloc': exigeGeoloc,
      'exigeFoto': exigeFoto,
      'exigeRoteiro': exigeRoteiro,
      'exigePesquisa': exigePesquisa,
      'exigeRelatorio': exigeRelatorio,
      'reimbursesKM': reimbursesKM,
      'kmValue': kmValue,
      'reimbursesToll': reimbursesToll,
      'reimbursesParking': reimbursesParking,
      'reimbursesFood': reimbursesFood,
      'reimbursesLodging': reimbursesLodging,
      'reimbursementDailyLimit': reimbursementDailyLimit,
      'requiresReceipt': requiresReceipt,
      'retencaoISS': retencaoISS,
      'retencaoINSS': retencaoINSS,
      'retencaoIR': retencaoIR,
      'cnae': cnae,
      'costCenter': costCenter,
      'natureOperation': natureOperation,
      'calcExtraHour': calcExtraHour,
      'calcNightShift': calcNightShift,
      'calcDSR': calcDSR,
      'calcInsalubridade': calcInsalubridade,
      'calcPericulosidade': calcPericulosidade,
      'calcBancoHoras': calcBancoHoras,
    };
  }

  factory AppPaymentRule.fromMap(Map<String, dynamic> map) {
    double parseD(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);
    bool parseB(dynamic v) => v == true || v == 'true';
    int parseI(dynamic v) => (v is num) ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0);

    return AppPaymentRule(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Padrão',
      baseValue: parseD(map['baseValue']),
      measurementType: map['measurementType'] ?? 'Por presença',
      billingUnit: map['billingUnit'] ?? 'Unidade',
      frequency: map['frequency'] ?? 'Mensal',
      requiresApproval: parseB(map['requiresApproval']),
      closingDay: parseI(map['closingDay']),
      closingPeriod: map['closingPeriod'] ?? '26 ao 25',
      closingCompetence: map['closingCompetence'] ?? 'Mensal',
      closingAutomaticCut: parseB(map['closingAutomaticCut']),
      allowsPostAdjustment: parseB(map['allowsPostAdjustment']),
      clientPaymentTerms: map['clientPaymentTerms'] ?? '30 dias',
      clientPaymentMethod: map['clientPaymentMethod'] ?? 'Boleto',
      contractType: map['contractType'] ?? 'Freelancer',
      paymentForm: map['paymentForm'] ?? 'PIX',
      workerPaymentFrequency: map['workerPaymentFrequency'] ?? 'Semanal',
      exigeEvidencia: parseB(map['exigeEvidencia']),
      pagamentoAutomatico: parseB(map['pagamentoAutomatico']),
      necessitaNF: parseB(map['necessitaNF']),
      approvalFlow: map['approvalFlow'] ?? 'Supervisor aprova',
      approvalSLA: parseI(map['approvalSLA']),
      autoApprovalHours: parseI(map['autoApprovalHours']),
      blockPaymentWithoutApproval: parseB(map['blockPaymentWithoutApproval']),
      allowContestation: parseB(map['allowContestation']),
      toleranceLate: parseI(map['toleranceLate']),
      toleranceCheckout: parseI(map['toleranceCheckout']),
      exigeGeoloc: parseB(map['exigeGeoloc']),
      exigeFoto: parseB(map['exigeFoto']),
      exigeRoteiro: parseB(map['exigeRoteiro']),
      exigePesquisa: parseB(map['exigePesquisa']),
      exigeRelatorio: parseB(map['exigeRelatorio']),
      reimbursesKM: parseB(map['reimbursesKM']),
      kmValue: parseD(map['kmValue']),
      reimbursesToll: parseB(map['reimbursesToll']),
      reimbursesParking: parseB(map['reimbursesParking']),
      reimbursesFood: parseB(map['reimbursesFood']),
      reimbursesLodging: parseB(map['reimbursesLodging']),
      reimbursementDailyLimit: parseD(map['reimbursementDailyLimit']),
      requiresReceipt: parseB(map['requiresReceipt']),
      retencaoISS: parseB(map['retencaoISS']),
      retencaoINSS: parseB(map['retencaoINSS']),
      retencaoIR: parseB(map['retencaoIR']),
      cnae: map['cnae'] ?? '',
      costCenter: map['costCenter'] ?? '',
      natureOperation: map['natureOperation'] ?? '',
      calcExtraHour: parseB(map['calcExtraHour']),
      calcNightShift: parseB(map['calcNightShift']),
      calcDSR: parseB(map['calcDSR']),
      calcInsalubridade: parseB(map['calcInsalubridade']),
      calcPericulosidade: parseB(map['calcPericulosidade']),
      calcBancoHoras: parseB(map['calcBancoHoras']),
    );
  }
}

class AppDemandModel {
  String id;
  String name;
  String clientId;
  String roleId;
  String defaultTime;
  int defaultVacancies;
  String defaultInstructions;
  String requiredActivity;
  String dressCode;
  String requiredDocuments;
  double defaultValue;
  bool requiresCheckIn;
  bool requiresCheckOut;
  bool requiresPhoto;
  bool requiresLocation;
  int allowedRadius;

  AppDemandModel({
    required this.id,
    required this.name,
    required this.clientId,
    required this.roleId,
    this.defaultTime = '08:00 - 17:00',
    this.defaultVacancies = 1,
    this.defaultInstructions = '',
    this.requiredActivity = '',
    this.dressCode = '',
    this.requiredDocuments = '',
    this.defaultValue = 150.0,
    this.requiresCheckIn = true,
    this.requiresCheckOut = true,
    this.requiresPhoto = true,
    this.requiresLocation = true,
    this.allowedRadius = 100,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientId': clientId,
      'roleId': roleId,
      'defaultTime': defaultTime,
      'defaultVacancies': defaultVacancies,
      'defaultInstructions': defaultInstructions,
      'requiredActivity': requiredActivity,
      'dressCode': dressCode,
      'requiredDocuments': requiredDocuments,
      'defaultValue': defaultValue,
      'requiresCheckIn': requiresCheckIn,
      'requiresCheckOut': requiresCheckOut,
      'requiresPhoto': requiresPhoto,
      'requiresLocation': requiresLocation,
      'allowedRadius': allowedRadius,
    };
  }

  factory AppDemandModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 150.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 150.0;
      return 150.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 100;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 100;
      return 100;
    }

    return AppDemandModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      clientId: map['clientId'] ?? '',
      roleId: map['roleId'] ?? '',
      defaultTime: map['defaultTime'] ?? '08:00 - 17:00',
      defaultVacancies: map['defaultVacancies'] ?? 1,
      defaultInstructions: map['defaultInstructions'] ?? '',
      requiredActivity: map['requiredActivity'] ?? '',
      dressCode: map['dressCode'] ?? '',
      requiredDocuments: map['requiredDocuments'] ?? '',
      defaultValue: parseDouble(map['defaultValue']),
      requiresCheckIn: map['requiresCheckIn'] ?? true,
      requiresCheckOut: map['requiresCheckOut'] ?? true,
      requiresPhoto: map['requiresPhoto'] ?? true,
      requiresLocation: map['requiresLocation'] ?? true,
      allowedRadius: parseInt(map['allowedRadius']),
    );
  }
}

class AppUser {
  String id;
  String name;
  String email;
  String password;
  String role;
  String status;
  String type; // 'prestador', 'interno', 'rede' (Líder de Frente de Caixa / Regional)
  String storeId;        // ID da loja vinculada (Líder de Frente de Caixa)
  List<String> storeIds; // múltiplas lojas vinculadas (Regional)
  String regional;       // Nome da regional de atuação (Regional)
  String authUid;        // UID do Firebase Authentication
  String? curriculumResumo;
  String? curriculumExperiencias;
  String? curriculumEscolaridade;
  String? curriculumAttachedPdf;
  String? curriculumCompletoDados;
  String? addressCity;
  String? addressUf;
  String? addressBairro;
  String? addressRua;
  String? addressCep;
  bool trainingCompleted;
  bool atacadaoExperience;
  bool isBlocked;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.password = '123456',
    this.role = '',
    this.status = 'Ativo',
    this.type = 'interno',
    this.storeId = '',
    this.storeIds = const [],
    this.regional = '',
    this.authUid = '',
    this.curriculumResumo,
    this.curriculumExperiencias,
    this.curriculumEscolaridade,
    this.curriculumAttachedPdf,
    this.curriculumCompletoDados,
    this.addressCity,
    this.addressUf,
    this.addressBairro,
    this.addressRua,
    this.addressCep,
    this.trainingCompleted = false,
    this.atacadaoExperience = false,
    this.isBlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'status': status,
      'type': type,
      'storeId': storeId,
      'storeIds': storeIds,
      'regional': regional,
      'authUid': authUid,
      'curriculum_resumo': curriculumResumo,
      'curriculum_experiencias': curriculumExperiencias,
      'curriculum_escolaridade': curriculumEscolaridade,
      'curriculum_attached_pdf': curriculumAttachedPdf,
      'curriculum_completo_dados': curriculumCompletoDados,
      'address_city': addressCity,
      'address_uf': addressUf,
      'address_bairro': addressBairro,
      'address_rua': addressRua,
      'address_cep': addressCep,
      'trainingCompleted': trainingCompleted,
      'atacadaoExperience': atacadaoExperience,
      'isBlocked': isBlocked,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '123456',
      role: map['role'] ?? '',
      status: map['status'] ?? 'Ativo',
      type: map['type'] ?? 'interno',
      storeId: map['storeId'] ?? '',
      storeIds: List<String>.from(map['storeIds'] ?? []),
      regional: map['regional'] ?? '',
      authUid: map['authUid'] ?? '',
      curriculumResumo: map['curriculum_resumo'],
      curriculumExperiencias: map['curriculum_experiencias'],
      curriculumEscolaridade: map['curriculum_escolaridade'],
      curriculumAttachedPdf: map['curriculum_attached_pdf'],
      curriculumCompletoDados: map['curriculum_completo_dados'],
      addressCity: map['address_city'] ?? map['address_cidade'] ?? map['cidade'],
      addressUf: map['address_uf'] ?? map['uf'],
      addressBairro: map['address_bairro'] ?? map['bairro'],
      addressRua: map['address_rua'] ?? map['rua'],
      addressCep: map['address_cep'] ?? map['cep'],
      trainingCompleted: map['trainingCompleted'] ?? map['training_completed'] ?? false,
      atacadaoExperience: map['atacadaoExperience'] ?? map['atacadao_experience'] ?? false,
      isBlocked: map['isBlocked'] ?? map['is_blocked'] ?? false,
    );
  }
}

class AppEPIDelivery {
  final String id;
  final String bandeiraId;
  final String bandeiraName;
  final String storeId;
  final String storeName;
  final String epi;
  final String deliveryDate;
  final int quantity;

  AppEPIDelivery({
    required this.id,
    required this.bandeiraId,
    required this.bandeiraName,
    required this.storeId,
    required this.storeName,
    required this.epi,
    required this.deliveryDate,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bandeiraId': bandeiraId,
      'bandeiraName': bandeiraName,
      'storeId': storeId,
      'storeName': storeName,
      'epi': epi,
      'deliveryDate': deliveryDate,
      'quantity': quantity,
    };
  }

  factory AppEPIDelivery.fromMap(Map<String, dynamic> map) {
    return AppEPIDelivery(
      id: map['id'] ?? '',
      bandeiraId: map['bandeiraId'] ?? '',
      bandeiraName: map['bandeiraName'] ?? '',
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      epi: map['epi'] ?? '',
      deliveryDate: map['deliveryDate'] ?? '',
      quantity: map['quantity'] ?? 0,
    );
  }
}

class AppQuestionnaire {
  String id;
  String name;
  List<dynamic> questions;

  AppQuestionnaire({
    required this.id,
    required this.name,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'questions': questions,
    };
  }

  factory AppQuestionnaire.fromMap(Map<String, dynamic> map) {
    return AppQuestionnaire(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      questions: map['questions'] ?? [],
    );
  }
}



