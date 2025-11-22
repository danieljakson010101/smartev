import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/charging_station.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'vehicleModel': null,
      'batteryCapacity': null,
      'isAdmin': false,
    });

    await userCredential.user!.updateDisplayName(name);
    return userCredential;
  }

  // Sign in
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get charging stations as stream
  Stream<List<ChargingStation>> getChargingStationsStream() {
    return _firestore
        .collection('charging_stations')
        .orderBy('distance')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChargingStation.fromFirestore(doc))
          .toList();
    });
  }

  // Get charging stations once
  Future<List<ChargingStation>> getChargingStations() async {
    QuerySnapshot snapshot = await _firestore
        .collection('charging_stations')
        .orderBy('distance')
        .get();

    return snapshot.docs
        .map((doc) => ChargingStation.fromFirestore(doc))
        .toList();
  }

  // Save charging session
  Future<void> saveChargingSession({
    required String stationId,
    required int batteryLevelBefore,
    required int batteryLevelAfter,
    required double energyConsumed,
  }) async {
    await _firestore.collection('charging_sessions').add({
      'userId': currentUser!.uid,
      'stationId': stationId,
      'startTime': FieldValue.serverTimestamp(),
      'batteryLevelBefore': batteryLevelBefore,
      'batteryLevelAfter': batteryLevelAfter,
      'energyConsumed': energyConsumed,
    });
  }

  // Save trip data
  Future<void> saveTrip({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required int startBatteryLevel,
    required int endBatteryLevel,
    required double distance,
    required double avgSpeed,
  }) async {
    await _firestore.collection('user_trips').add({
      'userId': currentUser!.uid,
      'startLocation': GeoPoint(startLat, startLng),
      'endLocation': GeoPoint(endLat, endLng),
      'startBatteryLevel': startBatteryLevel,
      'endBatteryLevel': endBatteryLevel,
      'distance': distance,
      'avgSpeed': avgSpeed,
      'date': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile
  Future<DocumentSnapshot> getUserProfile() async {
    return await _firestore.collection('users').doc(currentUser!.uid).get();
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? vehicleModel,
    int? batteryCapacity,
  }) async {
    Map<String, dynamic> updates = {};
    if (vehicleModel != null) updates['vehicleModel'] = vehicleModel;
    if (batteryCapacity != null) updates['batteryCapacity'] = batteryCapacity;

    await _firestore.collection('users').doc(currentUser!.uid).update(updates);
  }
}