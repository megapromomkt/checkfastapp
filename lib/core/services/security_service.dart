import 'package:safe_device/safe_device.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class SecurityService {
  /// Retorna as violações de segurança do aparelho. 
  /// Se a lista for vazia, o aparelho é seguro.
  static Future<List<String>> checkDeviceSecurity() async {
    List<String> violations = [];
    
    // Ignorar no modo web (Admin)
    if (kIsWeb) return violations;
    if (!Platform.isAndroid && !Platform.isIOS) return violations;

    try {
      final isJailBroken = await SafeDevice.isJailBroken;
      final isRealDevice = await SafeDevice.isRealDevice;
      final isMockLocation = await SafeDevice.isMockLocation;

      if (isJailBroken) {
        violations.add('O aparelho possui Root ou Jailbreak. Por segurança financeira, o acesso foi bloqueado.');
      }
      if (!isRealDevice) {
        violations.add('Emuladores não são permitidos para realizar Check-in em loja.');
      }
      if (isMockLocation) {
        violations.add('Falsificação de GPS (Fake GPS) detectada! Desative o Mock Location para realizar a diária.');
      }
    } catch (e) {
      // Falha na checagem
      violations.add('Falha ao validar a segurança do aparelho: $e');
    }

    return violations;
  }
}
