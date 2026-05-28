import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/premium_theme.dart';

class PresenceControlView extends StatefulWidget {
  const PresenceControlView({super.key});

  @override
  State<PresenceControlView> createState() => _PresenceControlViewState();
}

class _PresenceControlViewState extends State<PresenceControlView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumHeader(
          title: 'Controle de Presença',
          subtitle: 'Auditoria de geofencing e controle de diárias.',
        ),
        const SizedBox(height: 30),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
              }

              final userDocs = usersSnapshot.data?.docs ?? [];
              final Map<String, String> promoterMap = {};
              for (var doc in userDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name'] ?? '';
                final cpf = data['cpf'] ?? '';
                if (cpf.isNotEmpty) {
                  promoterMap[cpf] = name;
                }
                promoterMap[doc.id] = name;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, appsSnapshot) {
                  if (appsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                  }

                  final appDocs = appsSnapshot.data?.docs ?? [];
                  final presenceApps = appDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final checkInTime = data['checkInTime'] ?? '';
                    final checkOutTime = data['checkOutTime'] ?? '';
                    final status = data['status'] ?? '';
                    return checkInTime.toString().isNotEmpty || checkOutTime.toString().isNotEmpty || status == 'em_andamento';
                  }).toList();

                  if (presenceApps.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum registro de presença para hoje.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: presenceApps.length,
                    itemBuilder: (context, i) {
                      final doc = presenceApps[i];
                      final data = doc.data() as Map<String, dynamic>;

                      final String cpf = data['promoterCpf'] ?? '';
                      final String promoterName = data['promoterName'] ?? promoterMap[cpf] ?? 'Promotor';
                      final String storeName = data['storeName'] ?? '';

                      final checkInTime = data['checkInTime'] ?? '';
                      final checkOutTime = data['checkOutTime'] ?? '';
                      final status = data['status'] ?? '';

                      // Formatar datas para exibir HH:mm
                      String formattedCheckIn = '--:--';
                      if (checkInTime.toString().isNotEmpty) {
                        try {
                          formattedCheckIn = DateFormat("HH:mm").format(DateTime.parse(checkInTime));
                        } catch (_) {
                          formattedCheckIn = checkInTime.toString();
                        }
                      }

                      String formattedCheckOut = '--:--';
                      if (checkOutTime.toString().isNotEmpty) {
                        try {
                          formattedCheckOut = DateFormat("HH:mm").format(DateTime.parse(checkOutTime));
                        } catch (_) {
                          formattedCheckOut = checkOutTime.toString();
                        }
                      }

                      Color statusColor;
                      String statusText;
                      IconData statusIcon;

                      if (checkOutTime.toString().isNotEmpty) {
                        statusColor = Colors.blue;
                        statusText = 'Checkout Realizado';
                        statusIcon = Icons.logout;
                      } else if (checkInTime.toString().isNotEmpty || status == 'em_andamento') {
                        statusColor = Colors.green;
                        statusText = 'Em Loja (Checked-in)';
                        statusIcon = Icons.login;
                      } else {
                        statusColor = Colors.red;
                        statusText = 'Check-in Pendente';
                        statusIcon = Icons.timer_outlined;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(statusIcon, color: statusColor),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    promoterName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Local: $storeName • Entrada: $formattedCheckIn • Saída: $formattedCheckOut',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildAuditTag(
                              'GPS: ${checkInTime.toString().isNotEmpty ? "OK" : "PENDENTE"}',
                              checkInTime.toString().isNotEmpty ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            _buildAuditTag(
                              'FOTO: ${checkInTime.toString().isNotEmpty ? "OK" : "PENDENTE"}',
                              checkInTime.toString().isNotEmpty ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 12),
                            _buildAuditTag(statusText, statusColor),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
