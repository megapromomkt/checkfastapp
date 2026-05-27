import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import 'location_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Mostra notificação de risco de falta
  static Future<void> showAbsenceRiskAlert(String storeName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'risk_channel', 
      'Alertas de Risco',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFD32F2F), // Red Alert
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      '🚨 Risco de Atraso Detectado',
      'Você tem uma demanda em $storeName em 30 min, mas está muito distante. Confirme sua ida!',
      platformChannelSpecifics,
    );
  }

  /// Função que roda em background (Cron Job simulado) 30 minutos antes da vaga
  static Future<void> checkWorkerDistanceRisk(double storeLat, double storeLng, String storeName) async {
    Position? currentPosition = await LocationService.getCurrentLocation();
    
    if (currentPosition != null) {
      double distance = LocationService.calculateDistanceInMeters(
        currentPosition.latitude, 
        currentPosition.longitude, 
        storeLat, 
        storeLng
      );

      // Se 30 minutos antes a pessoa está a mais de 10km da loja (10000 metros)
      if (distance > 10000) {
        // Dispara notificação no celular do colaborador
        await showAbsenceRiskAlert(storeName);
        
        // Aqui também enviaria um sinal pro Firebase alertando o painel Admin do CheckFast!
        // FirebaseService().flagWorkerRisk(workerId, demandId);
      }
    }
  }
}
