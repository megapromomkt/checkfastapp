import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/data/test_database.dart';
import '../../models/app_models.dart';

class PresenceControlView extends StatefulWidget {
  const PresenceControlView({super.key});

  @override
  State<PresenceControlView> createState() => _PresenceControlViewState();
}

class _PresenceControlViewState extends State<PresenceControlView> {
  @override
  Widget build(BuildContext context) {
    final db = TestDatabase.instance;
    final presences = db.presenceRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        const PremiumHeader(title: 'Controle de Presença', subtitle: 'Auditoria ISO 9001 de geofencing e jornada de trabalho.'),
        const SizedBox(height: 30),
        Expanded(
          child: presences.isEmpty 
          ? const Center(child: Text('Nenhum registro de presença para hoje.', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              itemCount: presences.length,
              itemBuilder: (context, i) {
                final p = presences[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark, 
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05))
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 22, backgroundColor: AppColors.cardDark, child: Icon(Icons.person_outline, color: AppColors.neonCyan)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.promoterName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 5),
                            Text('Loja: ${p.storeName} • Entrada: ${p.checkInTime} • Saída: ${p.checkOutTime}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      _buildAuditTag('GPS: ${p.gpsValid ? "OK" : "NOK"}', p.gpsValid ? AppColors.successEmerald : Colors.redAccent),
                      const SizedBox(width: 10),
                      _buildAuditTag('FOTO: ${p.photoValid ? "OK" : "NOK"}', p.photoValid ? AppColors.successEmerald : Colors.redAccent),
                      const SizedBox(width: 10),
                      _buildAuditTag(p.status, AppColors.neonCyan),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}
