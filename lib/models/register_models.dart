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
}

class AppProject {
  String id;
  String name;
  String clientId;
  String type; // Exclusivo, Compartilhado
  String paymentModel; // Diária, Hora, Misto
  double defaultValue;
  int minHours;
  bool requiresPhoto;
  bool requiresLocation;
  int locationRadius;

  AppProject({
    required this.id,
    required this.name,
    required this.clientId,
    this.type = 'Exclusivo',
    this.paymentModel = 'Diária',
    this.defaultValue = 150.0,
    this.minHours = 6,
    this.requiresPhoto = true,
    this.requiresLocation = true,
    this.locationRadius = 100,
  });
}

class AppStore {
  String id;
  String name;
  String clientId;
  String address;
  String city;
  String state;
  int locationRadius;
  double latitude;
  double longitude;
  String responsible;
  String phone;

  AppStore({
    required this.id,
    required this.name,
    required this.clientId,
    this.address = '',
    this.city = '',
    this.state = '',
    this.locationRadius = 200,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.responsible = '',
    this.phone = '',
  });
}

class AppRole {
  String id;
  String name;
  String type;
  String description;

  AppRole({
    required this.id,
    required this.name,
    this.type = 'Operacional em Loja',
    this.description = '',
  });
}

class AppPaymentRule {
  String id;
  String name;
  String type;
  double baseValue;
  int minHours;
  bool allowException;

  AppPaymentRule({
    required this.id,
    required this.name,
    this.type = 'Diária',
    this.baseValue = 120.0,
    this.minHours = 8,
    this.allowException = false,
  });
}

class AppDemandModel {
  String id;
  String name;
  String clientId;
  String roleId;
  String defaultTime;
  int defaultVacancies;
  String defaultInstructions;

  AppDemandModel({
    required this.id,
    required this.name,
    required this.clientId,
    required this.roleId,
    this.defaultTime = '08:00 - 17:00',
    this.defaultVacancies = 1,
    this.defaultInstructions = '',
  });
}
