import '../data/test_database.dart';
import '../../models/app_models.dart';

class DemandService {
  final _db = TestDatabase.instance;

  Future<void> _networkDelay() => Future.delayed(const Duration(milliseconds: 500));

  Future<List<AppDemand>> getAllDemands() async {
    await _networkDelay();
    return _db.demands;
  }

  Future<void> createDemand(AppDemand demand) async {
    await _networkDelay();
    _db.demands.add(demand);
  }

  Future<void> updateDemandStatus(String id, String status) async {
    await _networkDelay();
    final index = _db.demands.indexWhere((d) => d.id == id);
    if (index != -1) {
      _db.demands[index].status = status;
    }
  }

  Future<void> deleteDemand(String id) async {
    await _networkDelay();
    _db.demands.removeWhere((d) => d.id == id);
  }

  Future<List<AppPresence>> getPresenceRecords() async {
    await _networkDelay();
    return _db.presenceRecords;
  }
}
