import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/app_models.dart';
import '../../models/register_models.dart';

class RegisterService {
  // --- CLIENTES ---
  Future<List<AppClient>> getClients() async {
    final snapshot = await FirebaseFirestore.instance.collection('clients').get();
    return snapshot.docs.map((doc) => AppClient.fromMap(doc.data())).toList();
  }

  Future<void> saveClient(AppClient client) async {
    await FirebaseFirestore.instance.collection('clients').doc(client.id).set(client.toMap());
  }

  Future<void> deleteClient(String id) async {
    await FirebaseFirestore.instance.collection('clients').doc(id).delete();
  }

  // --- PROJETOS ---
  Future<List<AppProject>> getProjects() async {
    final snapshot = await FirebaseFirestore.instance.collection('projects').get();
    return snapshot.docs.map((doc) => AppProject.fromMap(doc.data())).toList();
  }

  Future<void> saveProject(AppProject project) async {
    await FirebaseFirestore.instance.collection('projects').doc(project.id).set(project.toMap());
  }

  Future<void> deleteProject(String id) async {
    await FirebaseFirestore.instance.collection('projects').doc(id).delete();
  }

  // --- LOJAS ---
  Future<List<AppStore>> getStores() async {
    final snapshot = await FirebaseFirestore.instance.collection('stores').get();
    return snapshot.docs.map((doc) => AppStore.fromMap(doc.data())).toList();
  }

  Future<void> saveStore(AppStore store) async {
    if (store.latitude == 0.0 || store.longitude == 0.0) {
      // 1. Tenta por CEP
      if (store.cep.isNotEmpty) {
        final cleanCep = store.cep.replaceAll(RegExp(r'\D'), '');
        if (cleanCep.length == 8) {
          final formattedCep = '${cleanCep.substring(0, 5)}-${cleanCep.substring(5)}';
          final query = '$formattedCep, Brasil';
          final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1';
          try {
            final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data.isNotEmpty) {
                store.latitude = double.parse(data[0]['lat']);
                store.longitude = double.parse(data[0]['lon']);
              }
            }
          } catch (e) {
            print('Erro geocodificando loja por CEP: $e');
          }
        }
      }

      // 2. Tenta por endereço completo se o CEP falhar ou não retornar coordenadas
      if (store.latitude == 0.0 || store.longitude == 0.0) {
        final addressStr = '${store.logradouro}, ${store.numero} - ${store.bairro}, ${store.city}, ${store.state}, Brasil';
        final urlStr = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(addressStr)}&format=json&limit=1';
        try {
          final response = await http.get(Uri.parse(urlStr), headers: {'User-Agent': 'CheckFastApp'});
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data.isNotEmpty) {
              store.latitude = double.parse(data[0]['lat']);
              store.longitude = double.parse(data[0]['lon']);
            }
          }
        } catch (e) {
          print('Erro geocodificando loja por endereco: $e');
        }
      }
    }
    
    await FirebaseFirestore.instance.collection('stores').doc(store.id).set(store.toMap());
  }

  Future<void> deleteStore(String id) async {
    await FirebaseFirestore.instance.collection('stores').doc(id).delete();
  }

  // --- FUNÇÕES ---
  Future<List<AppRole>> getRoles() async {
    final snapshot = await FirebaseFirestore.instance.collection('roles').get();
    return snapshot.docs.map((doc) => AppRole.fromMap(doc.data())).toList();
  }

  Future<void> saveRole(AppRole role) async {
    await FirebaseFirestore.instance.collection('roles').doc(role.id).set(role.toMap());
  }

  Future<void> deleteRole(String id) async {
    await FirebaseFirestore.instance.collection('roles').doc(id).delete();
  }

  // --- REGRAS DE PAGAMENTO ---
  Future<List<AppPaymentRule>> getPaymentRules() async {
    final snapshot = await FirebaseFirestore.instance.collection('payment_rules').get();
    return snapshot.docs.map((doc) => AppPaymentRule.fromMap(doc.data())).toList();
  }

  Future<void> savePaymentRule(AppPaymentRule rule) async {
    await FirebaseFirestore.instance.collection('payment_rules').doc(rule.id).set(rule.toMap());
  }

  Future<void> deletePaymentRule(String id) async {
    await FirebaseFirestore.instance.collection('payment_rules').doc(id).delete();
  }

  // --- MODELOS DE DEMANDA ---
  Future<List<AppDemandModel>> getDemandModels() async {
    final snapshot = await FirebaseFirestore.instance.collection('demand_models').get();
    return snapshot.docs.map((doc) => AppDemandModel.fromMap(doc.data())).toList();
  }

  Future<void> saveDemandModel(AppDemandModel model) async {
    await FirebaseFirestore.instance.collection('demand_models').doc(model.id).set(model.toMap());
  }

  Future<void> deleteDemandModel(String id) async {
    await FirebaseFirestore.instance.collection('demand_models').doc(id).delete();
  }

  // --- REDES ---
  Future<List<AppRede>> getRedes() async {
    final snapshot = await FirebaseFirestore.instance.collection('redes').get();
    return snapshot.docs.map((doc) => AppRede.fromMap(doc.data())).toList();
  }

  Future<void> saveRede(AppRede rede) async {
    await FirebaseFirestore.instance.collection('redes').doc(rede.id).set(rede.toMap());
  }

  Future<void> deleteRede(String id) async {
    await FirebaseFirestore.instance.collection('redes').doc(id).delete();
  }

  // --- BANDEIRAS ---
  Future<List<AppBandeira>> getBandeiras() async {
    final snapshot = await FirebaseFirestore.instance.collection('bandeiras').get();
    return snapshot.docs.map((doc) => AppBandeira.fromMap(doc.data())).toList();
  }

  Future<void> saveBandeira(AppBandeira bandeira) async {
    await FirebaseFirestore.instance.collection('bandeiras').doc(bandeira.id).set(bandeira.toMap());
  }

  Future<void> deleteBandeira(String id) async {
    await FirebaseFirestore.instance.collection('bandeiras').doc(id).delete();
  }

  // --- DEMANDAS ---
  Future<List<AppDemand>> getDemands() async {
    final snapshot = await FirebaseFirestore.instance.collection('demands').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      if (!data.containsKey('id') || data['id'] == null || data['id'].toString().isEmpty) {
        data['id'] = doc.id;
      }
      return AppDemand.fromMap(data);
    }).toList();
  }

  Stream<List<AppDemand>> getDemandsStream() {
    return FirebaseFirestore.instance.collection('demands').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id') || data['id'] == null || data['id'].toString().isEmpty) {
          data['id'] = doc.id;
        }
        return AppDemand.fromMap(data);
      }).toList();
    });
  }


  Future<void> saveDemand(AppDemand demand) async {
    await FirebaseFirestore.instance.collection('demands').doc(demand.id).set(demand.toMap());
  }

  Future<void> deleteDemand(String id) async {
    await FirebaseFirestore.instance.collection('demands').doc(id).delete();
  }


  // --- USUÁRIOS ---

  Future<AppUser?> getUserByEmail(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Future<List<AppUser>> getUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList();
  }

  Future<void> saveUser(AppUser user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteUser(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).delete();
  }

  // --- ENTREGAS DE EPI ---
  Future<List<AppEPIDelivery>> getEPIDeliveries() async {
    final snapshot = await FirebaseFirestore.instance.collection('epi_deliveries').get();
    return snapshot.docs.map((doc) => AppEPIDelivery.fromMap(doc.data())).toList();
  }

  Future<void> saveEPIDelivery(AppEPIDelivery delivery) async {
    await FirebaseFirestore.instance.collection('epi_deliveries').doc(delivery.id).set(delivery.toMap());
  }

  Future<void> deleteEPIDelivery(String id) async {
    await FirebaseFirestore.instance.collection('epi_deliveries').doc(id).delete();
  }

  // --- QUESTIONÁRIOS ---
  Future<List<AppQuestionnaire>> getQuestionnaires() async {
    final snapshot = await FirebaseFirestore.instance.collection('questionnaires').get();
    return snapshot.docs.map((doc) => AppQuestionnaire.fromMap(doc.data())).toList();
  }

  Future<void> saveQuestionnaire(AppQuestionnaire questionnaire) async {
    await FirebaseFirestore.instance.collection('questionnaires').doc(questionnaire.id).set(questionnaire.toMap());
  }

  Future<void> deleteQuestionnaire(String id) async {
    await FirebaseFirestore.instance.collection('questionnaires').doc(id).delete();
  }
}

