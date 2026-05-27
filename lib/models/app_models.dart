class AppDemand {
  final String id;
  final String? clientId;
  final String? projectId;
  final String? storeId;
  final String? roleId;
  final String storeName;
  final String network;
  final String address;
  final String role;
  final String distance;
  final String timeRange;
  final double value;
  final String date;
  final String urgency;
  String status; // 'RASCUNHO', 'ABERTAS', 'PREENCHIDAS', 'EM ANDAMENTO', 'FINALIZADAS', 'CANCELADA'
  String? assignedPromoter;
  
  // Novos campos para o fluxo completo
  final String? clientName;
  final String? projectName;
  final int totalVagas;
  final int filledVagas;
  final String? entryTime;
  final String? exitTime;
  final bool requiresCheckIn;
  final bool requiresCheckOut;
  final bool requiresPhoto;
  final bool requiresLocation;
  final int allowedRadius;
  final double maxPromoterDistance;
  final String? instructions;
  final String priority; // 'Alta', 'Média', 'Baixa'
  final List<dynamic> questionnaire;
  
  // Campos detalhados para o prestador
  final String? requiredActivity;
  final String? stepByStep;
  final String? minTime;
  final String? dressCode;
  final String? requiredDocuments;
  final double? latitude;
  final double? longitude;

  static List<Map<String, dynamic>> get defaultQuestionnaire => [
    {
      'sectionTitle': 'Documentação',
      'questionText': 'Possui MEI ativo?',
      'responseType': 'Dropdown',
      'curriculumMapping': 'documentacao/mei',
      'options': [
        {'text': 'Sim', 'points': 10},
        {'text': 'Não', 'points': 0},
      ],
    },
    {
      'sectionTitle': 'Segurança',
      'questionText': 'Possui bota de segurança (EPI)?',
      'responseType': 'Dropdown',
      'curriculumMapping': 'Nenhum',
      'options': [
        {'text': 'Sim, possuo e levarei', 'points': 10},
        {'text': 'Não possuo', 'points': 0},
      ],
    },
    {
      'sectionTitle': 'Disponibilidade',
      'questionText': 'Disponibilidade para início imediato?',
      'responseType': 'Dropdown',
      'curriculumMapping': 'disponibilidade/imediata',
      'options': [
        {'text': 'Sim', 'points': 10},
        {'text': 'Não', 'points': 0},
      ],
    },
  ];

  AppDemand({
    required this.id,
    this.clientId,
    this.projectId,
    this.storeId,
    this.roleId,
    required this.storeName,
    required this.network,
    required this.address,
    required this.role,
    required this.distance,
    required this.timeRange,
    required this.value,
    required this.date,
    required this.urgency,
    required this.status,
    this.assignedPromoter,
    this.clientName,
    this.projectName,
    this.totalVagas = 1,
    this.filledVagas = 0,
    this.entryTime,
    this.exitTime,
    this.requiresCheckIn = true,
    this.requiresCheckOut = true,
    this.requiresPhoto = true,
    this.requiresLocation = true,
    this.allowedRadius = 100,
    this.maxPromoterDistance = 99999.0,
    this.instructions,
    this.priority = 'Média',
    this.questionnaire = const [],
    this.requiredActivity,
    this.stepByStep,
    this.minTime,
    this.dressCode,
    this.requiredDocuments,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'projectId': projectId,
      'storeId': storeId,
      'roleId': roleId,
      'storeName': storeName,
      'network': network,
      'address': address,
      'role': role,
      'distance': distance,
      'timeRange': timeRange,
      'value': value,
      'date': date,
      'urgency': urgency,
      'status': status,
      'assignedPromoter': assignedPromoter,
      'clientName': clientName,
      'projectName': projectName,
      'totalVagas': totalVagas,
      'filledVagas': filledVagas,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'requiresCheckIn': requiresCheckIn,
      'requiresCheckOut': requiresCheckOut,
      'requiresPhoto': requiresPhoto,
      'requiresLocation': requiresLocation,
      'allowedRadius': allowedRadius,
      'maxPromoterDistance': maxPromoterDistance,
      'instructions': instructions,
      'priority': priority,
      'questionnaire': questionnaire,
      'requiredActivity': requiredActivity,
      'stepByStep': stepByStep,
      'minTime': minTime,
      'dressCode': dressCode,
      'requiredDocuments': requiredDocuments,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory AppDemand.fromMap(Map<String, dynamic> map) {
    return AppDemand(
      id: map['id'] ?? '',
      clientId: map['clientId'],
      projectId: map['projectId'],
      storeId: map['storeId'],
      roleId: map['roleId'],
      storeName: map['storeName'] ?? '',
      network: map['network'] ?? '',
      address: map['address'] ?? '',
      role: map['role'] ?? '',
      distance: map['distance'] ?? '',
      timeRange: map['timeRange'] ?? '',
      value: (map['value'] ?? 0.0).toDouble(),
      date: map['date'] ?? '',
      urgency: map['urgency'] ?? '',
      status: map['status'] ?? '',
      assignedPromoter: map['assignedPromoter'],
      clientName: map['clientName'],
      projectName: map['projectName'],
      totalVagas: map['totalVagas'] ?? 1,
      filledVagas: map['filledVagas'] ?? 0,
      entryTime: map['entryTime'],
      exitTime: map['exitTime'],
      requiresCheckIn: map['requiresCheckIn'] ?? true,
      requiresCheckOut: map['requiresCheckOut'] ?? true,
      requiresPhoto: map['requiresPhoto'] ?? true,
      requiresLocation: map['requiresLocation'] ?? true,
      allowedRadius: map['allowedRadius'] ?? 100,
      maxPromoterDistance: (map['maxPromoterDistance'] ?? 99999.0).toDouble(),
      instructions: map['instructions'],
      priority: map['priority'] ?? 'Média',
      questionnaire: map['questionnaire'] ?? AppDemand.defaultQuestionnaire,
      requiredActivity: map['requiredActivity'],
      stepByStep: map['stepByStep'],
      minTime: map['minTime'],
      dressCode: map['dressCode'],
      requiredDocuments: map['requiredDocuments'],
      latitude: _fixCoordinate((map['latitude'] ?? 0.0).toDouble(), true),
      longitude: _fixCoordinate((map['longitude'] ?? 0.0).toDouble(), false),
    );
  }

  static double _fixCoordinate(double val, bool isLat) {
    if (val == 0.0) return 0.0;
    double clean = val;
    final maxVal = isLat ? 90.0 : 180.0;
    while (clean.abs() > maxVal) {
      clean /= 10.0;
    }
    return clean;
  }

}

class AppPresence {
  final String id;
  final String demandId;
  final String promoterName;
  final String storeName;
  final String checkInTime;
  final String checkOutTime;
  final bool gpsValid;
  final bool photoValid;
  final String status;

  AppPresence({
    required this.id,
    required this.demandId,
    required this.promoterName,
    required this.storeName,
    required this.checkInTime,
    required this.checkOutTime,
    required this.gpsValid,
    required this.photoValid,
    required this.status,
  });
}

class AppPayment {
  final String id;
  final String storeName;
  final String date;
  final double value;
  final String status; // 'Pago', 'Em análise', 'Aprovado', 'Não apto'

  AppPayment({
    required this.id,
    required this.storeName,
    required this.date,
    required this.value,
    required this.status,
  });
}

class AdminFinancialBatch {
  final String id;
  final String batchName;
  final double totalValue;
  final bool isPaid;

  AdminFinancialBatch({
    required this.id,
    required this.batchName,
    required this.totalValue,
    required this.isPaid,
  });
}
