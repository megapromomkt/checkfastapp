import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';

class PhotosGalleryView extends StatefulWidget {
  const PhotosGalleryView({super.key});

  @override
  State<PhotosGalleryView> createState() => _PhotosGalleryViewState();
}

class PhotoRecord {
  final String url;
  final String promoterName;
  final String promoterCpf;
  final String storeName;
  final String date;
  final String time;
  final String type; // 'Check-in' or 'Checkout'

  PhotoRecord({
    required this.url,
    required this.promoterName,
    required this.promoterCpf,
    required this.storeName,
    required this.date,
    required this.time,
    required this.type,
  });
}

class _PhotosGalleryViewState extends State<PhotosGalleryView> {
  // Temporary filter states (bound to dropdowns and pickers)
  String _tempSelectedPromoter = 'Todos';
  String _tempSelectedStore = 'Todos';
  DateTime? _tempSelectedDate;

  // Applied filter states (copied from temp states on clicking "CONSULTAR")
  String _appliedPromoter = 'Todos';
  String _appliedStore = 'Todos';
  DateTime? _appliedDate;

  // Track if user clicked "CONSULTAR"
  bool _hasQueried = false;

  // Set of selected photo URLs
  Set<String> _selectedPhotoUrls = {};



  String _formatTime(String? timeIso) {
    if (timeIso == null || timeIso.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(timeIso);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return timeIso;
    }
  }

  void _clearFilters() {
    setState(() {
      _tempSelectedPromoter = 'Todos';
      _tempSelectedStore = 'Todos';
      _tempSelectedDate = null;
      _appliedPromoter = 'Todos';
      _appliedStore = 'Todos';
      _appliedDate = null;
      _hasQueried = false;
      _selectedPhotoUrls.clear();
    });
  }

  void _applyFilters() {
    setState(() {
      _appliedPromoter = _tempSelectedPromoter;
      _appliedStore = _tempSelectedStore;
      _appliedDate = _tempSelectedDate;
      _hasQueried = true;
      _selectedPhotoUrls.clear();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tempSelectedDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tempSelectedDate = picked;
      });
    }
  }

  void _generatePhotoBook(List<PhotoRecord> photos) {
    final selectedPhotos = photos.where((p) => _selectedPhotoUrls.contains(p.url)).toList();
    if (selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma foto para gerar o book.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final dateFilterStr = _appliedDate != null 
        ? DateFormat('dd/MM/yyyy').format(_appliedDate!) 
        : 'Todas as Datas';
    final promoterFilterStr = _appliedPromoter;
    final storeFilterStr = _appliedStore;

    final String photoCardsHtml = selectedPhotos.map((p) {
      return '''
      <div class="photo-card">
        <div class="photo-container">
          <img src="${p.url}" alt="Foto de Execução" />
        </div>
        <div class="photo-details">
          <p><strong>Loja:</strong> ${p.storeName}</p>
          <p><strong>Prestador:</strong> ${p.promoterName} (${p.promoterCpf})</p>
          <p><strong>Data:</strong> ${p.date} às ${p.time}</p>
          <p><strong>Etapa:</strong> <span class="badge ${p.type.toLowerCase() == 'check-in' ? 'checkin' : 'checkout'}">${p.type}</span></p>
        </div>
      </div>
      ''';
    }).join('\n');

    final String printHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Book de Fotos - CheckFast</title>
  <style>
    @media print {
      body {
        margin: 0;
        padding: 1.5cm;
        background-color: #ffffff;
        color: #000000;
      }
      .no-print {
        display: none;
      }
      .photo-card {
        page-break-inside: avoid;
      }
    }
    body {
      font-family: Arial, sans-serif;
      margin: 2cm auto;
      max-width: 900px;
      color: #333333;
      background-color: #ffffff;
      padding: 0 20px;
    }
    .header {
      border-bottom: 3px solid #1A3C70;
      padding-bottom: 15px;
      margin-bottom: 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .header h1 {
      margin: 0;
      font-size: 24px;
      color: #1A3C70;
    }
    .header p {
      margin: 5px 0 0 0;
      font-size: 13px;
      color: #666666;
    }
    .filters-summary {
      background-color: #f8f9fa;
      border: 1px solid #e9ecef;
      padding: 15px;
      border-radius: 6px;
      margin-bottom: 30px;
      font-size: 13px;
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 15px;
    }
    .filters-summary p {
      margin: 0;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
    }
    .photo-card {
      border: 1px solid #dee2e6;
      border-radius: 8px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      background-color: #ffffff;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }
    .photo-container {
      width: 100%;
      height: 280px;
      background-color: #f1f3f5;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }
    .photo-container img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    .photo-details {
      padding: 15px;
      font-size: 12px;
    }
    .photo-details p {
      margin: 4px 0;
    }
    .badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 4px;
      font-weight: bold;
      font-size: 10px;
      text-transform: uppercase;
    }
    .badge.checkin {
      background-color: #d1e7dd;
      color: #0f5132;
    }
    .badge.checkout {
      background-color: #cfe2ff;
      color: #084298;
    }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <h1>BOOK DE EXECUÇÕES - CHECKFAST</h1>
      <p>Megapromo Merchandising & Trade Marketing</p>
    </div>
    <div style="text-align: right; font-size: 12px; color: #666666;">
      Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}
    </div>
  </div>

  <div class="filters-summary">
    <p><strong>Prestador:</strong> $promoterFilterStr</p>
    <p><strong>Loja:</strong> $storeFilterStr</p>
    <p><strong>Data:</strong> $dateFilterStr</p>
  </div>

  <div class="grid">
    $photoCardsHtml
  </div>

  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 500);
    }
  </script>
</body>
</html>
''';

    final blob = html.Blob([printHtml], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').get().asStream(),
        builder: (context, usersSnapshot) {
          if (usersSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }

          final userDocs = usersSnapshot.data?.docs ?? [];
          final Map<String, String> promoterMap = {};
          final List<String> pNames = [];
          for (var doc in userDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final cpf = data['cpf'] ?? doc.id;
            final type = data['type'] ?? '';
            final role = data['role'] ?? '';

            if (type == 'prestador' || role == 'worker' || role == 'prestador') {
              if (name.isNotEmpty) {
                promoterMap[cpf] = name;
                promoterMap[doc.id] = name;
                if (!pNames.contains(name)) pNames.add(name);
              }
            }
          }
          pNames.sort();
          pNames.insert(0, 'Todos');

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('applications').get().asStream(),
            builder: (context, appsSnapshot) {
              if (appsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
              }

              final appDocs = appsSnapshot.data?.docs ?? [];
              final List<PhotoRecord> allPhotos = [];
              final List<String> sNames = [];

              for (var doc in appDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final String cpf = data['promoterCpf'] ?? '';
                final String promoterName = data['promoterName'] ?? promoterMap[cpf] ?? 'Prestador Desconhecido';
                final String storeName = data['storeName'] ?? 'Loja Desconhecida';
                final String dateVal = data['date'] ?? '';

                if (storeName.isNotEmpty && !sNames.contains(storeName)) {
                  sNames.add(storeName);
                }

                // Extrair fotos de check-in
                final checkInPhotos = data['checkInPhotos'] as List<dynamic>? ?? [];
                final checkInTime = data['checkInTime'] ?? '';
                for (var photoUrl in checkInPhotos) {
                  if (photoUrl is String && photoUrl.isNotEmpty) {
                    allPhotos.add(PhotoRecord(
                      url: photoUrl,
                      promoterName: promoterName,
                      promoterCpf: cpf,
                      storeName: storeName,
                      date: dateVal,
                      time: _formatTime(checkInTime),
                      type: 'Check-in',
                    ));
                  }
                }

                // Extrair fotos de checkout
                final checkOutPhotos = data['checkOutPhotos'] as List<dynamic>? ?? [];
                final checkOutTime = data['checkOutTime'] ?? '';
                for (var photoUrl in checkOutPhotos) {
                  if (photoUrl is String && photoUrl.isNotEmpty) {
                    allPhotos.add(PhotoRecord(
                      url: photoUrl,
                      promoterName: promoterName,
                      promoterCpf: cpf,
                      storeName: storeName,
                      date: dateVal,
                      time: _formatTime(checkOutTime),
                      type: 'Checkout',
                    ));
                  }
                }
              }

              sNames.sort();
              sNames.insert(0, 'Todos');

              // Aplicar filtros
              final filteredPhotos = allPhotos.where((p) {
                if (_appliedPromoter != 'Todos' && p.promoterName != _appliedPromoter) {
                  return false;
                }
                if (_appliedStore != 'Todos' && p.storeName != _appliedStore) {
                  return false;
                }
                if (_appliedDate != null) {
                  final formattedFilterDate = DateFormat('yyyy-MM-dd').format(_appliedDate!);
                  final formattedFilterDateBR = DateFormat('dd/MM/yyyy').format(_appliedDate!);
                  // Suporta ambos formatos de data gravados
                  if (p.date != formattedFilterDate && p.date != formattedFilterDateBR && !p.date.contains(formattedFilterDateBR)) {
                    return false;
                  }
                }
                return true;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumHeader(
                      title: 'Galeria de Fotos',
                      subtitle: 'Audite as fotos de check-in e checkout tiradas pelos prestadores.',
                      actions: [
                        ElevatedButton.icon(
                          onPressed: _selectedPhotoUrls.isEmpty ? null : () => _generatePhotoBook(filteredPhotos),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                          label: Text(
                            _selectedPhotoUrls.isEmpty ? 'GERAR BOOK PDF' : 'GERAR BOOK PDF (${_selectedPhotoUrls.length})',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filtros
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.cardBorder),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Prestador Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PRESTADOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: pNames.contains(_tempSelectedPromoter) ? _tempSelectedPromoter : 'Todos',
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        items: pNames.map((name) {
                                          return DropdownMenuItem(
                                            value: name,
                                            child: Text(name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _tempSelectedPromoter = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Loja Dropdown
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LOJA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: sNames.contains(_tempSelectedStore) ? _tempSelectedStore : 'Todos',
                                        isExpanded: true,
                                        dropdownColor: Colors.white,
                                        items: sNames.map((store) {
                                          return DropdownMenuItem(
                                            value: store,
                                            child: Text(store, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _tempSelectedStore = val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Data Picker
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DATA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context),
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _tempSelectedDate == null 
                                                ? 'Todas as datas' 
                                                : DateFormat('dd/MM/yyyy').format(_tempSelectedDate!),
                                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                          ),
                                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Consultar Button
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: ElevatedButton.icon(
                                onPressed: _applyFilters,
                                icon: const Icon(Icons.search, color: Colors.white, size: 18),
                                label: const Text('CONSULTAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Limpar Filtros
                            Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: OutlinedButton(
                                onPressed: _clearFilters,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  side: const BorderSide(color: AppColors.cardBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  foregroundColor: AppColors.textSecondary,
                                ),
                                child: const Text('LIMPAR', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Seletor de Todas as fotos e Grid de Fotos
                    Expanded(
                      child: !_hasQueried
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_search, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Busque as fotos de execução',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Selecione os filtros acima e clique em CONSULTAR.',
                                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho do Grid (Quantidade e Selecionar Todas)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Fotos encontradas: ${filteredPhotos.length}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                    ),
                                    if (filteredPhotos.isNotEmpty)
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _selectedPhotoUrls.length == filteredPhotos.length,
                                            activeColor: AppColors.primaryBlue,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedPhotoUrls = filteredPhotos.map((p) => p.url).toSet();
                                                } else {
                                                  _selectedPhotoUrls.clear();
                                                }
                                              });
                                            },
                                          ),
                                          const Text(
                                            'Selecionar Todas',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Grid de Fotos
                                Expanded(
                                  child: filteredPhotos.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Nenhuma foto encontrada para os filtros selecionados.',
                                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                          ),
                                        )
                                      : GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 4,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 0.8,
                                          ),
                                          itemCount: filteredPhotos.length,
                                          itemBuilder: (context, index) {
                                            final photo = filteredPhotos[index];
                                            final isSelected = _selectedPhotoUrls.contains(photo.url);
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (isSelected) {
                                                    _selectedPhotoUrls.remove(photo.url);
                                                  } else {
                                                    _selectedPhotoUrls.add(photo.url);
                                                  }
                                                });
                                              },
                                              child: Card(
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
                                                    width: isSelected ? 2 : 1,
                                                  ),
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                color: Colors.white,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Image
                                                    Expanded(
                                                      child: Stack(
                                                        fit: StackFit.expand,
                                                        children: [
                                                          Image.network(
                                                            photo.url,
                                                            fit: BoxFit.cover,
                                                            loadingBuilder: (context, child, loadingProgress) {
                                                              if (loadingProgress == null) return child;
                                                              return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                                                            },
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Container(
                                                                color: AppColors.background,
                                                                child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                                                              );
                                                            },
                                                          ),
                                                          // Badge Checkin/Checkout
                                                          Positioned(
                                                            top: 10,
                                                            left: 10,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: photo.type == 'Check-in' ? Colors.green : AppColors.primaryBlue,
                                                                borderRadius: BorderRadius.circular(4),
                                                              ),
                                                              child: Text(
                                                                photo.type.toUpperCase(),
                                                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ),
                                                          // Checkbox Overlay
                                                          Positioned(
                                                            top: 10,
                                                            right: 10,
                                                            child: Container(
                                                              decoration: const BoxDecoration(
                                                                color: Colors.white,
                                                                shape: BoxShape.circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors.black12,
                                                                    blurRadius: 4,
                                                                  )
                                                                ],
                                                              ),
                                                              child: Icon(
                                                                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                                                color: isSelected ? AppColors.primaryBlue : Colors.grey.shade400,
                                                                size: 24,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Details
                                                    Padding(
                                                      padding: const EdgeInsets.all(12),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            photo.storeName,
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            photo.promoterName,
                                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                photo.date,
                                                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                              ),
                                                              Text(
                                                                photo.time,
                                                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
