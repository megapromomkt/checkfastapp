import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as exc;
import 'dart:html' as html;
import '../../core/constants/premium_theme.dart';

class PresenceControlView extends StatefulWidget {
  const PresenceControlView({super.key});

  @override
  State<PresenceControlView> createState() => _PresenceControlViewState();
}

class _PresenceControlViewState extends State<PresenceControlView> {
  final Map<String, String> _cachedNames = {};
  String _searchQuery = '';
  String _statusFilter = 'Todos';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _parseFlexibleDate(String dateStr) {
    final str = dateStr.trim();
    if (str.isEmpty) return null;

    // Try yyyy-MM-dd
    try {
      if (str.contains('-')) {
        final parts = str.split('-');
        if (parts.length == 3) {
          final y = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final d = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}

    // Try dd/MM/yyyy or dd/MM/yy or dd/MM
    try {
      if (str.contains('/')) {
        final parts = str.split('/');
        if (parts.length >= 2) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          int y = DateTime.now().year;
          if (parts.length == 3) {
            y = int.parse(parts[2]);
            if (y < 100) {
              y += 2000; // yy to yyyy
            }
          }
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}

    return null;
  }

  bool _isToday(String dateStr) {
    if (dateStr.isEmpty) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Clean and split ranges
    final cleaned = dateStr.trim();
    if (cleaned.contains(' - ')) {
      final parts = cleaned.split(' - ');
      if (parts.length == 2) {
        final start = _parseFlexibleDate(parts[0]);
        final end = _parseFlexibleDate(parts[1]);
        if (start != null && end != null) {
          return (today.isAfter(start) || today.isAtSameMomentAs(start)) &&
                 (today.isBefore(end) || today.isAtSameMomentAs(end));
        }
      }
    }

    // Single date
    final dateVal = _parseFlexibleDate(cleaned);
    if (dateVal != null) {
      return dateVal.year == today.year && dateVal.month == today.month && dateVal.day == today.day;
    }

    // Fallback string comparisons
    final todayStr1 = DateFormat("yyyy-MM-dd").format(now); // e.g., 2026-06-05
    final todayStr2 = DateFormat("dd/MM/yyyy").format(now); // e.g., 05/06/2026
    final todayStr3 = DateFormat("dd/MM/yy").format(now); // e.g., 05/06/26
    final todayStr4 = DateFormat("dd/MM").format(now); // e.g., 05/06

    return dateStr.contains(todayStr1) ||
           dateStr.contains(todayStr2) ||
           dateStr.contains(todayStr3) ||
           dateStr.contains(todayStr4) ||
           todayStr2.contains(dateStr) ||
           todayStr3.contains(dateStr) ||
           todayStr4.contains(dateStr);
  }

  void _exportToXLS(List<QueryDocumentSnapshot> presenceApps) {
    try {
      var excel = exc.Excel.createExcel();
      exc.Sheet sheetObject = excel['Controle de Presença'];
      excel.setDefaultSheet('Controle de Presença');

      sheetObject.appendRow([
        exc.TextCellValue('Promotor'),
        exc.TextCellValue('CPF'),
        exc.TextCellValue('Loja'),
        exc.TextCellValue('Cargo'),
        exc.TextCellValue('Data da Diária'),
        exc.TextCellValue('Valor'),
        exc.TextCellValue('Check-in'),
        exc.TextCellValue('Check-out'),
        exc.TextCellValue('Status'),
      ]);

      for (var doc in presenceApps) {
        final data = doc.data() as Map<String, dynamic>;
        final String cpf = data['promoterCpf'] ?? '';
        final String promoterName = data['promoterName'] ?? _cachedNames[cpf] ?? cpf;
        final String storeName = data['storeName'] ?? '';
        final String role = data['role'] ?? '';
        final String date = data['date'] ?? '';
        final double value = (data['value'] ?? 0.0).toDouble();
        final checkInTime = data['checkInTime'] ?? '';
        final checkOutTime = data['checkOutTime'] ?? '';
        final status = data['status'] ?? '';

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

        String statusText;
        if (checkOutTime.toString().isNotEmpty) {
          statusText = 'Checkout Realizado';
        } else if (checkInTime.toString().isNotEmpty || status == 'em_andamento') {
          statusText = 'Em Loja (Checked-in)';
        } else {
          statusText = 'Check-in Pendente';
        }

        sheetObject.appendRow([
          exc.TextCellValue(promoterName),
          exc.TextCellValue(cpf),
          exc.TextCellValue(storeName),
          exc.TextCellValue(role),
          exc.TextCellValue(date),
          exc.DoubleCellValue(value),
          exc.TextCellValue(formattedCheckIn),
          exc.TextCellValue(formattedCheckOut),
          exc.TextCellValue(statusText),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final fileName = 'Relatorio_Presenca_Tempo_Real_${DateFormat('dd-MM-yyyy').format(DateTime.now())}.xlsx';

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório exportado com sucesso!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar relatório: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumHeader(
          title: 'Controle de Presença',
          subtitle: 'Auditoria de geofencing e controle de diárias.',
        ),
        const SizedBox(height: 25),
        
        // Barra de Filtros e Ferramentas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    hintText: 'Buscar por promotor, CPF ou loja...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por Status',
                    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: ['Todos', 'Check-in Pendente', 'Em Loja (Checked-in)', 'Checkout Realizado'].map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _statusFilter = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Export Button Placeholders (Loaded dynamically)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('applications')
                    .where('status', whereIn: [
                      'tarefa_aprovada',
                      'aprovado',
                      'selecionado',
                      'treinamento',
                      'em_andamento',
                      'em_analise',
                      'liberado_pagamento',
                      'pago'
                    ])
                    .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  final presenceList = _getFilteredPresenceList(docs);
                  
                  return ElevatedButton.icon(
                    onPressed: presenceList.isEmpty ? null : () => _exportToXLS(presenceList),
                    icon: const Icon(Icons.download, size: 16, color: Colors.white),
                    label: const Text('Exportar Excel', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.cardBorder,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stream de Exibição dos Registros
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('status', whereIn: [
                  'tarefa_aprovada',
                  'aprovado',
                  'selecionado',
                  'treinamento',
                  'em_andamento',
                  'em_analise',
                  'liberado_pagamento',
                  'pago'
                ])
                .snapshots(),
            builder: (context, appsSnapshot) {
              if (appsSnapshot.hasError) {
                final err = appsSnapshot.error.toString();
                if (err.contains('429') || err.contains('RESOURCE_EXHAUSTED') || err.contains('Quota exceeded')) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Cota de Consulta do Banco de Dados Esgotada',
                          style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'O sistema alcançou o limite diário gratuito de consultas (Firestore Quota Exceeded). '
                          'Os dados em tempo real não puderam ser carregados neste momento. Por favor, tente novamente mais tarde ou atualize a página.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return Center(child: Text('Erro ao carregar dados: $err', style: const TextStyle(color: Colors.redAccent)));
              }

              if (appsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
              }

              final appDocs = appsSnapshot.data?.docs ?? [];
              final filteredPresenceApps = _getFilteredPresenceList(appDocs);

              if (filteredPresenceApps.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum registro de presença encontrado.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredPresenceApps.length,
                itemBuilder: (context, i) {
                  final doc = filteredPresenceApps[i];
                  final data = doc.data() as Map<String, dynamic>;

                  final String cpf = data['promoterCpf'] ?? '';
                  final String storeName = data['storeName'] ?? '';
                  final String role = data['role'] ?? 'Promotor';
                  final double value = (data['value'] ?? 0.0).toDouble();

                  // Resolve promoter name dynamically with lazy loading
                  String promoterName = data['promoterName'] ?? '';
                  if (promoterName.isEmpty) {
                    promoterName = _cachedNames[cpf] ?? 'Carregando...';
                    if (!_cachedNames.containsKey(cpf) && cpf.isNotEmpty) {
                      _cachedNames[cpf] = 'Carregando...';
                      FirebaseFirestore.instance.collection('users').doc(cpf).get().then((userDoc) {
                        if (userDoc.exists && mounted) {
                          final uData = userDoc.data() as Map<String, dynamic>;
                          final name = uData['name'] ?? '';
                          if (name.toString().isNotEmpty) {
                            setState(() {
                              _cachedNames[cpf] = name.toString();
                            });
                          } else {
                            setState(() {
                              _cachedNames[cpf] = cpf;
                            });
                          }
                        } else {
                          if (mounted) {
                            setState(() {
                              _cachedNames[cpf] = cpf;
                            });
                          }
                        }
                      }).catchError((_) {
                        if (mounted) {
                          setState(() {
                            _cachedNames[cpf] = cpf;
                          });
                        }
                      });
                    }
                  }

                  final checkInTime = data['checkInTime'] ?? '';
                  final checkOutTime = data['checkOutTime'] ?? '';
                  final status = data['status'] ?? '';

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
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: statusColor.withOpacity(0.08),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promoterName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Local: $storeName ($role) • Diária: R\$ ${value.toStringAsFixed(2)} • Entrada: $formattedCheckIn • Saída: $formattedCheckOut',
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
                        const SizedBox(width: 8),
                        _buildAuditTag(
                          'FOTO: ${checkInTime.toString().isNotEmpty ? "OK" : "PENDENTE"}',
                          checkInTime.toString().isNotEmpty ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        _buildAuditTag(statusText, statusColor),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot> _getFilteredPresenceList(List<QueryDocumentSnapshot> docs) {
    // 1. Filter by Date & active status
    final list = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final checkInTime = data['checkInTime'] ?? '';
      final status = data['status'] ?? '';
      final dateStr = data['date']?.toString() ?? '';

      // Check if it's scheduled for today
      if (_isToday(dateStr)) {
        return true;
      }

      // Check if check-in was registered today
      if (checkInTime.toString().isNotEmpty) {
        try {
          final parsed = DateTime.parse(checkInTime.toString());
          final now = DateTime.now();
          if (parsed.year == now.year && parsed.month == now.month && parsed.day == now.day) {
            return true;
          }
        } catch (_) {}
      }

      // Or if it's active right now
      return status == 'em_andamento';
    }).toList();

    // 2. Sort by updatedAt descending
    list.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['updatedAt']?.toString() ?? '';
      final bTime = bData['updatedAt']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    // 3. Filter by Search Query
    final filtered = list.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final String cpf = data['promoterCpf'] ?? '';
      final String promoterName = (data['promoterName'] ?? _cachedNames[cpf] ?? cpf).toString().toLowerCase();
      final String storeName = (data['storeName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) return true;
      return promoterName.contains(query) || cpf.contains(query) || storeName.contains(query);
    }).toList();

    // 4. Filter by Status Selection
    if (_statusFilter == 'Todos') {
      return filtered;
    }
    
    return filtered.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final checkInTime = data['checkInTime'] ?? '';
      final checkOutTime = data['checkOutTime'] ?? '';
      final status = data['status'] ?? '';

      if (_statusFilter == 'Checkout Realizado') {
        return checkOutTime.toString().isNotEmpty;
      } else if (_statusFilter == 'Em Loja (Checked-in)') {
        return checkOutTime.toString().isEmpty && (checkInTime.toString().isNotEmpty || status == 'em_andamento');
      } else if (_statusFilter == 'Check-in Pendente') {
        return checkInTime.toString().isEmpty && status != 'em_andamento';
      }
      return true;
    }).toList();
  }

  Widget _buildAuditTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }
}
