import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/premium_theme.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class CheckInTabView extends StatefulWidget {
  final bool isDesktop;
  final String userCpf;
  const CheckInTabView({super.key, required this.isDesktop, required this.userCpf});

  @override
  State<CheckInTabView> createState() => _CheckInTabViewState();
}

class _CheckInTabViewState extends State<CheckInTabView> {
  bool _isLoadingLocation = false;
  bool _isLocationVerified = false;
  bool _isCheckingIn = false;
  bool _isCheckedIn = false;
  List<XFile> _photos = [];
  
  bool _isCheckingOut = false;
  bool _isCheckedOut = false;
  List<XFile> _checkoutPhotos = [];
  
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;

  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _activeApplication;
  bool _isLoadingApp = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadActiveApplication();
  }

  Future<void> _loadActiveApplication() async {
    if (!mounted) return;
    setState(() {
      _isLoadingApp = true;
      _errorMessage = '';
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('applications')
          .where('promoterCpf', isEqualTo: widget.userCpf)
          .orderBy('submittedAt', descending: true)
          .get();

      Map<String, dynamic>? active;
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status']?.toString() ?? '';
        
        if (status == 'tarefa_aprovada' || status == 'em_andamento' || status == 'em_analise' || status == 'liberado_pagamento' || status == 'pago' || status == 'nao_aprovada') {
          active = {
            'id': doc.id,
            'storeName':   data['storeName']?.toString() ?? '',
            'network':     data['network']?.toString() ?? '',
            'role':        data['role']?.toString() ?? '',
            'date':        data['date']?.toString() ?? '',
            'timeRange':   data['timeRange']?.toString() ?? '',
            'value':       (data['value'] ?? 0).toDouble(),
            'status':      status,
            'address':     data['address']?.toString() ?? '',
            'latitude':    (data['latitude'] ?? -23.5275).toDouble(),
            'longitude':   (data['longitude'] ?? -46.6853).toDouble(),
            'checkInTime': data['checkInTime']?.toString() ?? '',
            'checkOutTime': data['checkOutTime']?.toString() ?? '',
          };
          break;
        }
      }
      
      if (mounted) {
        setState(() {
          _activeApplication = active;
          _isLoadingApp = false;
          if (active != null) {
            final status = active['status'];
            if (status == 'em_andamento') {
              _isCheckedIn = true;
              _isCheckedOut = false;
              if (active['checkInTime'].toString().isNotEmpty) {
                try {
                  final checkInDt = DateTime.parse(active['checkInTime']);
                  _elapsedTime = DateTime.now().difference(checkInDt);
                  _startTimer();
                } catch (_) {}
              }
            } else if (status == 'em_analise' || status == 'liberado_pagamento' || status == 'pago' || status == 'nao_aprovada') {
              _isCheckedIn = true;
              _isCheckedOut = true;
            } else {
              _isCheckedIn = false;
              _isCheckedOut = false;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingApp = false;
          _errorMessage = 'Erro ao carregar jornada.';
        });
      }
    }
  }

  Future<void> _verifyLocation() async {
    setState(() => _isLoadingLocation = true);
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Serviço de GPS desativado no navegador.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Permissão de GPS negada.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showError('Permissões de GPS bloqueadas permanentemente.');
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // Coordenadas da Loja
      final double storeLat = _activeApplication?['latitude'] ?? -23.5275;
      final double storeLng = _activeApplication?['longitude'] ?? -46.6853;
      
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        storeLat,
        storeLng,
      );

      // Limite de 200 metros
      if (distance > 200) {
        _showError('Você está fora do raio da loja (${distance.toInt()} metros). Vá até a loja para continuar.');
        setState(() {
          _isLocationVerified = false;
          _isLoadingLocation = false;
        });
        return;
      }

      HapticFeedback.mediumImpact();
      setState(() {
        _isLoadingLocation = false;
        _isLocationVerified = true;
      });
    } catch (e) {
      _showError('Erro ao obter localização: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= 3) {
      _showError('Você já tirou o limite de 3 fotos.');
      return;
    }
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        HapticFeedback.lightImpact();
        final watermarked = await _addWatermark(photo);
        setState(() {
          _photos.add(watermarked);
        });
        _showCheckInConfirmation();
      }
    } catch (e) {
      _showError('Não foi possível acessar a câmera do navegador.');
    }
  }

  Future<XFile> _addWatermark(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return file;

      final dateStr = DateTime.now().toString().substring(0, 16);
      final text = "CheckFast | $dateStr | Local Valido";

      // Desenha uma barra preta no fundo para dar contraste
      img.fillRect(image, x1: 0, y1: image.height - 50, x2: image.width, y2: image.height, color: img.ColorRgba8(0, 0, 0, 150));
      
      // Desenha o texto da marca d'água
      img.drawString(image, text, font: img.arial24, x: 20, y: image.height - 35, color: img.ColorRgba8(255, 255, 255, 255));

      final encoded = img.encodeJpg(image);
      return XFile.fromData(Uint8List.fromList(encoded), mimeType: 'image/jpeg');
    } catch (e) {
      print('Erro ao adicionar marca dágua: $e');
      return file; // Se falhar, retorna a foto original
    }
  }

  Future<void> _submitCheckIn() async {
    if (_photos.isEmpty) {
      _showError('Tire pelo menos uma foto para confirmar.');
      return;
    }
    if (_activeApplication == null) {
      _showError('Nenhuma jornada ativa carregada.');
      return;
    }
    
    setState(() => _isCheckingIn = true);
    
    final now = DateTime.now().toIso8601String();
    
    try {
      // Envia via SDK do Firestore (evita cota de API REST e token manual)
      await FirebaseFirestore.instance.collection('applications').doc(_activeApplication!['id']).update({
        'status': 'em_andamento',
        'checkInTime': now,
        'updatedAt': now,
      });
      
      HapticFeedback.heavyImpact();
      
      final prefs = await SharedPreferences.getInstance();
      final presenceData = jsonEncode({
        'id': _activeApplication!['id'],
        'demandId': _activeApplication!['demandId'] ?? '',
        'promoterName': 'Promotor',
        'storeName': _activeApplication!['storeName'] ?? '',
        'checkInTime': '${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}',
        'checkOutTime': '--:--',
        'gpsValid': true,
        'photoValid': true,
        'status': 'EM ANDAMENTO',
      });
      await prefs.setString('current_presence', presenceData);

      setState(() {
        _isCheckingIn = false;
        _isCheckedIn = true;
        _elapsedTime = Duration.zero;
        _startTimer();
        _activeApplication!['status'] = 'em_andamento';
        _activeApplication!['checkInTime'] = now;
      });
    } catch (e) {
      _showError('Erro ao realizar check-in: $e');
      setState(() => _isCheckingIn = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = _elapsedTime + const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showError(String msg) {
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingApp) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              SizedBox(height: 16),
              Text('Carregando jornada...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Minha Jornada', style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 8),
                const Text('Gerencie seu ponto e atividades do dia.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                
                // Card da Demanda do Dia
                _buildDemandaCard(),
                
                const SizedBox(height: 32),
                
                // Cronômetro
                if (_isCheckedIn && !_isCheckedOut)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(IconsaxPlusLinear.clock, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tempo em loja: ${_formatDuration(_elapsedTime)}',
                            style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Botões de Check-in e Checkout
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'CHECK-IN',
                        icon: IconsaxPlusLinear.login,
                        color: _isCheckedIn ? AppColors.success : AppColors.primaryBlue,
                        isActive: !_isCheckedIn && _activeApplication != null && _activeApplication!['status'] == 'tarefa_aprovada',
                        onPressed: (_isCheckedIn || _activeApplication == null || _activeApplication!['status'] != 'tarefa_aprovada') ? null : _verifyLocationAndCheckIn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        label: 'CHECKOUT',
                        icon: IconsaxPlusLinear.logout,
                        color: Colors.redAccent,
                        isActive: _isCheckedIn && !_isCheckedOut && _activeApplication != null && _activeApplication!['status'] == 'em_andamento',
                        onPressed: (_isCheckedIn && !_isCheckedOut && _activeApplication != null && _activeApplication!['status'] == 'em_andamento') ? _verifyLocationAndCheckout : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Exibe as fotos tiradas
                if (_photos.isNotEmpty) ...[
                  const Text('Fotos do Check-in:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildPhotoList(_photos),
                  const SizedBox(height: 24),
                ],
                
                if (_checkoutPhotos.isNotEmpty) ...[
                  const Text('Fotos do Checkout:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildPhotoList(_checkoutPhotos),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemandaCard() {
    if (_activeApplication == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          children: [
            Icon(IconsaxPlusLinear.info_circle, color: Colors.orangeAccent, size: 48),
            SizedBox(height: 16),
            Text(
              'Aguardando Aprovação',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Nenhuma vaga com status "Tarefa Aprovada" encontrada. Você poderá fazer Check-in assim que o RH liberar a sua contratação.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(IconsaxPlusLinear.shop, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Demanda do Dia', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(_activeApplication!['storeName'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(IconsaxPlusLinear.location, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_activeApplication!['address'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : AppColors.background,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.background,
        disabledForegroundColor: AppColors.textSecondary.withOpacity(0.5),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isActive ? Colors.transparent : AppColors.cardBorder),
      ),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5, color: isActive ? Colors.white : AppColors.textSecondary.withOpacity(0.5))),
    );
  }

  Widget _buildPhotoList(List<XFile> photos) {
    return Row(
      children: photos.map((photo) => Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(photo.path, width: 60, height: 60, fit: BoxFit.cover),
        ),
      )).toList(),
    );
  }

  void _verifyLocationAndCheckIn() async {
    _verifyLocation().then((_) {
      if (_isLocationVerified) {
        _takePhoto();
      }
    });
  }

  void _verifyLocationAndCheckout() async {
    _verifyLocation().then((_) {
      if (_isLocationVerified) {
        _takeCheckoutPhoto();
      }
    });
  }

  void _takeCheckoutPhoto() async {
    if (_checkoutPhotos.length >= 3) {
      _showError('Você já tirou o limite de 3 fotos de checkout.');
      return;
    }
    
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        HapticFeedback.lightImpact();
        final watermarked = await _addWatermark(photo);
        setState(() {
          _checkoutPhotos.add(watermarked);
        });
        
        _showCheckoutConfirmation();
      }
    } catch (e) {
      _showError('Não foi possível acessar a câmera do navegador.');
    }
  }

  void _showCheckInConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in em andamento'),
        content: Text('Você tirou ${_photos.length} foto(s). Deseja finalizar o check-in ou tirar mais fotos?'),
        actions: [
          if (_photos.length < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takePhoto();
              },
              child: const Text('TIRAR MAIS FOTO'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitCheckIn();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout em andamento'),
        content: Text('Você tirou ${_checkoutPhotos.length} foto(s). Deseja finalizar ou tirar mais fotos?'),
        actions: [
          if (_checkoutPhotos.length < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takeCheckoutPhoto();
              },
              child: const Text('TIRAR MAIS FOTO'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitCheckout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckout() async {
    if (_checkoutPhotos.isEmpty) {
      _showError('Tire pelo menos uma foto para confirmar o checkout.');
      return;
    }
    if (_activeApplication == null) {
      _showError('Nenhuma jornada ativa carregada.');
      return;
    }
    
    setState(() => _isCheckingOut = true);
    final now = DateTime.now().toIso8601String();
    
    try {
      // Envia via SDK do Firestore (evita cota de API REST e token manual)
      await FirebaseFirestore.instance.collection('applications').doc(_activeApplication!['id']).update({
        'status': 'em_analise',
        'checkOutTime': now,
        'updatedAt': now,
      });

      _timer?.cancel();
      
      final prefs = await SharedPreferences.getInstance();
      final rawPres = prefs.getString('current_presence');
      if (rawPres != null) {
        try {
          final data = jsonDecode(rawPres) as Map<String, dynamic>;
          data['checkOutTime'] = '${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}';
          data['status'] = 'EM ANALISE';
          await prefs.setString('current_presence', jsonEncode(data));
        } catch (_) {}
      }
      
      setState(() {
        _isCheckingOut = false;
        _isCheckedOut = true;
        _activeApplication!['status'] = 'em_analise';
        _activeApplication!['checkOutTime'] = now;
      });
    } catch (e) {
      _showError('Erro de rede: $e');
      setState(() => _isCheckingOut = false);
    }
  }
}
