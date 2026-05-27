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

class CheckInTabView extends StatefulWidget {
  final bool isDesktop;
  const CheckInTabView({super.key, required this.isDesktop});

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
      
      // Coordenadas do Atacadão Lapa (Rua Clélia, 2200)
      const double storeLat = -23.5275;
      const double storeLng = -46.6853;
      
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
    
    setState(() => _isCheckingIn = true);
    
    // Simula o upload da foto e da localização pro Firebase
    await Future.delayed(const Duration(seconds: 2));
    
    HapticFeedback.heavyImpact();
    
    // Salva a presença no SharedPreferences para o Gerente ler
    final prefs = await SharedPreferences.getInstance();
    final presenceData = jsonEncode({
      'id': 'p1',
      'demandId': 'd1',
      'promoterName': 'Thabata Reco',
      'storeName': 'ATACADÃO LAPA',
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
      _startTimer();
    });
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
                        isActive: !_isCheckedIn,
                        onPressed: _isCheckedIn ? null : _verifyLocationAndCheckIn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        label: 'CHECKOUT',
                        icon: IconsaxPlusLinear.logout,
                        color: Colors.redAccent,
                        isActive: _isCheckedIn && !_isCheckedOut,
                        onPressed: (_isCheckedIn && !_isCheckedOut) ? _verifyLocationAndCheckout : null,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demanda do Dia', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('ATACADÃO LAPA', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(IconsaxPlusLinear.location, color: AppColors.textSecondary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text('Rua Clélia, 2200 - Lapa, São Paulo - SP', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
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
    setState(() => _isCheckingOut = true);
    await Future.delayed(const Duration(seconds: 2));
    _timer?.cancel();
    setState(() {
      _isCheckingOut = false;
      _isCheckedOut = true;
    });
  }
}
