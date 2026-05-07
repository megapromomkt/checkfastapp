import 'package:flutter/material.dart';

enum OperationStatus { pending, inProgress, validated, rejected, paid }

class TradeStore {
  final String id;
  final String name;
  final String address;
  final String cnpj;
  final double lat;
  final double lng;

  TradeStore({
    required this.id, 
    required this.name, 
    required this.address, 
    required this.cnpj,
    required this.lat, 
    required this.lng
  });
}

class TradeDemand {
  final String id;
  final TradeStore store;
  final String workerId;
  final String workerName;
  final OperationStatus status;
  final String? evidencePhotoUrl;
  final DateTime scheduledDate;
  final double? checkInLat;
  final double? checkInLng;

  TradeDemand({
    required this.id,
    required this.store,
    required this.workerId,
    required this.workerName,
    required this.status,
    this.evidencePhotoUrl,
    required this.scheduledDate,
    this.checkInLat,
    this.checkInLng,
  });
}

class UserDocuments {
  final String rgFrenteUrl;
  final String rgVersoUrl;
  final String cpfUrl;
  final String selfieUrl;
  final bool isVerified;

  UserDocuments({
    required this.rgFrenteUrl,
    required this.rgVersoUrl,
    required this.cpfUrl,
    required this.selfieUrl,
    this.isVerified = false,
  });
}
