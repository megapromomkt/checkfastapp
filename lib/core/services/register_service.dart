import '../data/test_database.dart';
import '../../models/register_models.dart';

class RegisterService {
  final _db = TestDatabase.instance;

  // Simulação de delay de rede para comportamento real de API
  Future<void> _networkDelay() => Future.delayed(const Duration(milliseconds: 400));

  // --- CLIENTES ---
  Future<List<AppClient>> getClients() async {
    await _networkDelay();
    return _db.clients;
  }

  Future<void> saveClient(AppClient client) async {
    await _networkDelay();
    final index = _db.clients.indexWhere((c) => c.id == client.id);
    if (index != -1) {
      _db.clients[index] = client;
    } else {
      _db.clients.add(client);
    }
  }

  Future<void> deleteClient(String id) async {
    await _networkDelay();
    _db.clients.removeWhere((c) => c.id == id);
  }

  // --- PROJETOS ---
  Future<List<AppProject>> getProjects() async {
    await _networkDelay();
    return _db.projects;
  }

  Future<void> saveProject(AppProject project) async {
    await _networkDelay();
    final index = _db.projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _db.projects[index] = project;
    } else {
      _db.projects.add(project);
    }
  }

  Future<void> deleteProject(String id) async {
    await _networkDelay();
    _db.projects.removeWhere((p) => p.id == id);
  }

  // --- LOJAS ---
  Future<List<AppStore>> getStores() async {
    await _networkDelay();
    return _db.stores;
  }

  Future<void> saveStore(AppStore store) async {
    await _networkDelay();
    final index = _db.stores.indexWhere((s) => s.id == store.id);
    if (index != -1) {
      _db.stores[index] = store;
    } else {
      _db.stores.add(store);
    }
  }

  Future<void> deleteStore(String id) async {
    await _networkDelay();
    _db.stores.removeWhere((s) => s.id == id);
  }

  // --- FUNÇÕES ---
  Future<List<AppRole>> getRoles() async {
    await _networkDelay();
    return _db.roles;
  }

  Future<void> saveRole(AppRole role) async {
    await _networkDelay();
    final index = _db.roles.indexWhere((r) => r.id == role.id);
    if (index != -1) {
      _db.roles[index] = role;
    } else {
      _db.roles.add(role);
    }
  }

  Future<void> deleteRole(String id) async {
    await _networkDelay();
    _db.roles.removeWhere((r) => r.id == id);
  }
}
