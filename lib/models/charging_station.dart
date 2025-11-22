import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingStation {
  final String id;
  final String name;
  final double distance;
  final int availableChargers;
  final int totalChargers;
  final int estimatedTime;
  final String chargerType;
  final bool reachable;
  final int energyRequired;
  final GeoPoint? location;
  final String? address;
  final double? pricePerKwh;
  final String? operator;
  final List<String>? amenities;

  ChargingStation({
    required this.id,
    required this.name,
    required this.distance,
    required this.availableChargers,
    required this.totalChargers,
    required this.estimatedTime,
    required this.chargerType,
    required this.reachable,
    required this.energyRequired,
    this.location,
    this.address,
    this.pricePerKwh,
    this.operator,
    this.amenities,
  });

  factory ChargingStation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChargingStation(
      id: doc.id,
      name: data['name'] ?? '',
      distance: (data['distance'] ?? 0).toDouble(),
      availableChargers: data['availableChargers'] ?? 0,
      totalChargers: data['totalChargers'] ?? 0,
      estimatedTime: data['estimatedTime'] ?? 0,
      chargerType: data['chargerType'] ?? 'Unknown',
      reachable: data['reachable'] ?? false,
      energyRequired: data['energyRequired'] ?? 0,
      location: data['location'],
      address: data['address'],
      pricePerKwh: data['pricePerKwh'] != null 
          ? (data['pricePerKwh'] as num).toDouble() 
          : null,
      operator: data['operator'],
      amenities: data['amenities'] != null 
          ? List<String>.from(data['amenities']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'distance': distance,
      'availableChargers': availableChargers,
      'totalChargers': totalChargers,
      'estimatedTime': estimatedTime,
      'chargerType': chargerType,
      'reachable': reachable,
      'energyRequired': energyRequired,
      'location': location,
      'address': address,
      'pricePerKwh': pricePerKwh,
      'operator': operator,
      'amenities': amenities,
    };
  }
}