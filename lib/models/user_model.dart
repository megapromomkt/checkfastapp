class UserModel {
  final String id;
  final String role; // 'admin' ou 'worker'
  final String name;
  final String cpf;
  final String phone;
  final String email;
  final String pixKey;
  final String experience;
  final String status; // 'Em análise', 'Aprovado', 'Reprovado', 'Bloqueado', 'Ativo'
  final double rating; // Ranking do colaborador (0-5 estrelas)
  final int loyaltyPoints; // Pontos de fidelidade
  final String? profilePhotoUrl;
  final Map<String, String>? documents; // {'rg': 'url', 'cpf': 'url', 'comprovante': 'url'}
  final List<String>? demandHistory; // IDs de demandas concluídas
  final List<Map<String, dynamic>>? paymentHistory; // [{'amount': 150, 'date': '...', 'status': 'Paid'}]
  final DateTime createdAt;
  final String? birthDate;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? emergencyContact;
  final Map<String, dynamic>? bankAccount;
  final String? password;

  UserModel({
    required this.id,
    required this.role,
    required this.name,
    required this.cpf,
    required this.phone,
    required this.email,
    required this.pixKey,
    required this.experience,
    required this.status,
    this.rating = 5.0,
    this.loyaltyPoints = 0,
    this.profilePhotoUrl,
    this.documents,
    this.demandHistory,
    this.paymentHistory,
    required this.createdAt,
    this.birthDate,
    this.address,
    this.emergencyContact,
    this.bankAccount,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'cpf': cpf,
      'phone': phone,
      'email': email,
      'pixKey': pixKey,
      'experience': experience,
      'status': status,
      'rating': rating,
      'loyaltyPoints': loyaltyPoints,
      'profilePhotoUrl': profilePhotoUrl,
      'documents': documents,
      'demandHistory': demandHistory,
      'paymentHistory': paymentHistory,
      'createdAt': createdAt.toIso8601String(),
      'birthDate': birthDate,
      'address': address,
      'emergencyContact': emergencyContact,
      'bankAccount': bankAccount,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      role: map['role'] ?? 'worker',
      name: map['name'] ?? '',
      cpf: map['cpf'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      pixKey: map['pixKey'] ?? '',
      experience: map['experience'] ?? '',
      status: map['status'] ?? 'Em análise',
      rating: (map['rating'] ?? 5.0).toDouble(),
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      profilePhotoUrl: map['profilePhotoUrl'],
      documents: map['documents'] != null ? Map<String, String>.from(map['documents']) : null,
      demandHistory: map['demandHistory'] != null ? List<String>.from(map['demandHistory']) : null,
      paymentHistory: map['paymentHistory'] != null ? List<Map<String, dynamic>>.from(map['paymentHistory']) : null,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      birthDate: map['birthDate'],
      address: map['address'] != null ? Map<String, dynamic>.from(map['address']) : null,
      emergencyContact: map['emergencyContact'] != null ? Map<String, dynamic>.from(map['emergencyContact']) : null,
      bankAccount: map['bankAccount'] != null ? Map<String, dynamic>.from(map['bankAccount']) : null,
      password: map['password'],
    );
  }
}
