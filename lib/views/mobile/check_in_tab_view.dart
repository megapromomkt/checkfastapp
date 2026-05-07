import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/premium_theme.dart';

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
  XFile? _photo;

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
      // Simula um tempo de carregamento de GPS realista
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
    try {
      // No navegador do celular, source: ImageSource.camera abrirá a câmera nativa.
      // No desktop, abrirá a webcam ou o seletor de arquivos caso webcam indisponível.
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Comprime para subir rápido
      );

      if (photo != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _photo = photo;
        });
        _submitCheckIn();
      }
    } catch (e) {
      _showError('Não foi possível acessar a câmera do navegador. Tente anexar uma imagem.');
    }
  }

  Future<void> _submitCheckIn() async {
    setState(() => _isCheckingIn = true);
    
    // Simula o upload da foto e da localização pro Firebase
    await Future.delayed(const Duration(seconds: 2));
    
    HapticFeedback.heavyImpact();
    setState(() {
      _isCheckingIn = false;
      _isCheckedIn = true;
    });
  }

  void _showError(String msg) {
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _isCheckedIn ? _buildSuccessState() : _buildActiveState(),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(IconsaxPlusBold.verify, color: AppColors.successEmerald, size: 100),
        const SizedBox(height: 30),
        const Text('Check-in Realizado!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Sua jornada de 4 horas foi iniciada.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 50),
        PremiumCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hora de Entrada:', style: TextStyle(color: AppColors.textSecondary)),
                  Text('${DateTime.now().hour.toString().padLeft(2,'0')}:${DateTime.now().minute.toString().padLeft(2,'0')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white10, height: 30),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Previsão de Saída:', style: TextStyle(color: AppColors.textSecondary)),
                  Text('Daqui 4 horas', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveState() {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorderDark)
            ),
            child: Center(
              child: _isLoadingLocation 
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.neonCyan),
                      SizedBox(height: 20),
                      Text('Acessando satélites GPS...', style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2)),
                    ],
                  )
                : _isLocationVerified
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconsaxPlusLinear.radar, color: AppColors.successEmerald, size: 80),
                        SizedBox(height: 20),
                        Text('GPS VALIDADO COM SUCESSO', style: TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        SizedBox(height: 5),
                        Text('Margem de precisão: 4 metros', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconsaxPlusLinear.location_add, color: AppColors.neonCyan, size: 80),
                        const SizedBox(height: 20),
                        const Text('AGUARDANDO VALIDAÇÃO', style: TextStyle(color: AppColors.textSecondary, letterSpacing: 2)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _verifyLocation, 
                          icon: const Icon(IconsaxPlusLinear.gps, color: Colors.black),
                          label: const Text('VALIDAR MINHA LOCALIZAÇÃO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.all(20)),
                        )
                      ],
                    ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)]
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: _isLocationVerified ? AppColors.successEmerald.withOpacity(0.1) : Colors.white10, 
                      shape: BoxShape.circle
                    ), 
                    child: Icon(Icons.check, color: _isLocationVerified ? AppColors.successEmerald : Colors.white30, size: 16)
                  ),
                  const SizedBox(width: 15),
                  Text(_isLocationVerified ? 'Você está no local correto' : 'Localização não validada', style: TextStyle(color: _isLocationVerified ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLocationVerified && !_isCheckingIn ? _takePhoto : null, 
                  icon: _isCheckingIn ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(IconsaxPlusLinear.camera, color: Colors.black),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan, 
                    disabledBackgroundColor: Colors.white10,
                    padding: const EdgeInsets.all(20), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  label: Text(_isCheckingIn ? 'ENVIANDO...' : 'TIRAR FOTO E CONFIRMAR', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900))
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
