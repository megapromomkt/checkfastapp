import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------ USUÁRIOS ------------------
  
  /// Salva ou atualiza um usuário no banco
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      print("Erro ao salvar usuário: \$e");
      rethrow;
    }
  }

  /// Busca o perfil de um colaborador específico
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Erro ao buscar usuário: \$e");
      return null;
    }
  }

  // ------------------ DEMANDAS ------------------

  /// Escuta as demandas ativas em tempo real (para listar no mapa)
  Stream<List<Map<String, dynamic>>> getActiveDemandsStream() {
    return _db
        .collection('demands')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ------------------ PRESENÇAS ------------------

  /// Atualiza o status de uma presença (usado pelo Admin para aprovar/reprovar)
  Future<void> updateAttendanceStatus(String attendanceId, String status) async {
    try {
      await _db.collection('attendances').doc(attendanceId).update({
        'status': status,
      });
    } catch (e) {
      print("Erro ao atualizar presença: \$e");
      rethrow;
    }
  }
}
