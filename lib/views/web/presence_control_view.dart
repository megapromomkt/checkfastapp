import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../models/app_models.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PresenceControlView extends StatefulWidget {
  const PresenceControlView({super.key});

  @override
  State<PresenceControlView> createState() => _PresenceControlViewState();
}

class _PresenceControlViewState extends State<PresenceControlView> {
  List<AppPresence> _presences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresences();
  }

  Future<void> _loadPresences() async {
    final db = TestDatabase.instance;
    final basePresences = db.presenceRecords;
    
    final prefs = await SharedPreferences.getInstance();
    final presenceJson = prefs.getString('current_presence');
    
    setState(() {
      _presences = List.from(basePresences);
      if (presenceJson != null) {
        final data = jsonDecode(presenceJson);
        _presences.insert(0, AppPresence( // Insere no topo da lista
          id: data['id'],
          demandId: data['demandId'],
          promoterName: data['promoterName'],
          storeName: data['storeName'],
          checkInTime: data['checkInTime'],
          checkOutTime: data['checkOutTime'],
          gpsValid: data['gpsValid'],
          photoValid: data['photoValid'],
          status: data['status'],
        ));
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        const PremiumHeader(title: 'Controle de Presença', subtitle: 'Auditoria de geofencing e controle de diárias.'),
        const SizedBox(height: 30),
        Expanded(
          child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : _presences.isEmpty 
            ? const Center(child: Text('Nenhum registro de presença para hoje.', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                itemCount: _presences.length,
                itemBuilder: (context, i) {
                  final p = _presences[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 24, backgroundColor: AppColors.background, child: Icon(Icons.person_outline, color: AppColors.primaryBlue)),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.promoterName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text('Local: ${p.storeName} • Entrada: ${p.checkInTime} • Saída: ${p.checkOutTime}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        _buildAuditTag('GPS: ${p.gpsValid ? "OK" : "NOK"}', p.gpsValid ? AppColors.success : AppColors.error),
                        const SizedBox(width: 12),
                        _buildAuditTag('FOTO: ${p.photoValid ? "OK" : "NOK"}', p.photoValid ? AppColors.success : AppColors.error),
                        const SizedBox(width: 12),
                        _buildAuditTag(p.status, AppColors.primaryBlue),
                      ],
                    ),
                  );
                },
              ),
        ),
      ]
    );
  }

  Widget _buildAuditTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}
