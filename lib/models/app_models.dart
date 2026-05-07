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
  final String? instructions;
  final String priority; // 'Alta', 'Média', 'Baixa'

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
    this.instructions,
    this.priority = 'Média',
  });
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
