import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SmartEVChargingApp());
}

class SmartEVChargingApp extends StatelessWidget {
  const SmartEVChargingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EzCharge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          return MainApp(userId: snapshot.data!.uid);
        }
        
        return const AuthScreen();
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) _showSnackBar('Login successful!', isError: false);
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'vehicleModel': null,
          'batteryCapacity': null,
          'isAdmin': false,
        });

        await userCredential.user!.updateDisplayName(_nameController.text.trim());
        if (mounted) _showSnackBar('Account created successfully!', isError: false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'user-not-found': message = 'No account found with this email'; break;
        case 'wrong-password': message = 'Incorrect password'; break;
        case 'email-already-in-use': message = 'An account already exists with this email'; break;
        case 'weak-password': message = 'Password must be at least 6 characters'; break;
        case 'invalid-email': message = 'Please enter a valid email address'; break;
        case 'invalid-credential': message = 'Invalid email or password'; break;
        default: message = e.message ?? 'Authentication failed';
      }
      if (mounted) _showSnackBar(message, isError: true);
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateName(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) return 'Name is required';
    if (!_isLogin && value!.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[600]!, Colors.blue[700]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.electric_car, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'EzCharge',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome back!' : 'Create your account',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _isLogin = true;
                                        _formKey.currentState?.reset();
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _isLogin ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Login',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _isLogin ? Colors.blue[600] : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _isLogin = false;
                                        _formKey.currentState?.reset();
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_isLogin ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Sign Up',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !_isLogin ? Colors.blue[600] : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                validator: _validateName,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  hintStyle: const TextStyle(color: Colors.white70),
                                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white30),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white30),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.white),
                                  ),
                                  errorStyle: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.email, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                                errorStyle: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              validator: _validatePassword,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(color: Colors.white70),
                                prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white30),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white),
                                ),
                                errorStyle: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.white60,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Login' : 'Sign Up',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  final String userId;
  const MainApp({Key? key, required this.userId}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedTab = 0;
  int batteryLevel = 65;
  int currentSpeed = 85;
  int recommendedSpeed = 70;
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ChargingStation> chargingStations = [];
  bool _isLoadingStations = true;
  String? userName;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadChargingStations();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() => userName = userDoc.get('name') ?? 'User');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadChargingStations() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('charging_stations')
          .orderBy('distance')
          .get();

      setState(() {
        chargingStations = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          GeoPoint? location = data['location'];
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
            address: data['address'],
            pricePerKwh: data['pricePerKwh'] != null ? (data['pricePerKwh'] as num).toDouble() : null,
            operator: data['operator'],
            latitude: location?.latitude ?? 3.1390,
            longitude: location?.longitude ?? 101.6869,
          );
        }).toList();
        _isLoadingStations = false;
      });
    } catch (e) {
      print('Error loading stations: $e');
      setState(() => _isLoadingStations = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  Color getBatteryColor() {
    if (batteryLevel > 50) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  String getBatteryLabel() {
    if (batteryLevel > 50) return 'Good';
    if (batteryLevel > 20) return 'Low';
    return 'Critical';
  }

  String getEfficiencyLabel() {
    int speedDiff = currentSpeed - recommendedSpeed;
    if (speedDiff <= 0) return 'Efficient';
    if (speedDiff <= 15) return 'Moderate';
    return 'Inefficient';
  }

  Color getEfficiencyColor() {
    int speedDiff = currentSpeed - recommendedSpeed;
    if (speedDiff <= 0) return Colors.green;
    if (speedDiff <= 15) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[600],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.electric_car, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EzCharge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (userName != null)
                  Text('Hello, $userName', style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(children: [Icon(Icons.person, size: 18), SizedBox(width: 8), Text('Profile')]),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(children: [Icon(Icons.settings, size: 18), SizedBox(width: 8), Text('Settings')]),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') _handleLogout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue[600],
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    icon: Icons.battery_full,
                    value: '$batteryLevel%',
                    label: '${(batteryLevel * 3.5).toStringAsFixed(0)} km',
                    color: getBatteryColor(),
                  ),
                  Container(width: 1, height: 50, color: Colors.white30),
                  _buildStatCard(
                    icon: Icons.speed,
                    value: '$currentSpeed',
                    label: 'km/h',
                    color: Colors.orange,
                  ),
                  Container(width: 1, height: 50, color: Colors.white30),
                  _buildStatCard(
                    icon: Icons.location_on,
                    value: '${chargingStations.where((s) => s.reachable).length}',
                    label: 'Stations',
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Map', 0),
                _buildTab('Stations', 1),
                _buildTab('Speed', 2),
                _buildTab('Battery', 3),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingStations
                ? const Center(child: CircularProgressIndicator())
                : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildTab(String label, int index) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? Colors.blue[600]! : Colors.transparent, width: 3)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.blue[600] : Colors.grey[500],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildMapTab();
      case 1:
        return _buildStationsTab();
      case 2:
        return _buildSpeedTab();
      case 3:
        return _buildBatteryTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMapTab() {
    if (_isLoadingStations) {
      return const Center(child: CircularProgressIndicator());
    }

    final LatLng center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(3.1390, 101.6869);

    // Check if running on web - show placeholder with list
    return LayoutBuilder(
      builder: (context, constraints) {
        // For web or if map fails, show a visual map placeholder with station markers
        return Column(
          children: [
            // Map Placeholder
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[100]!, Colors.green[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Mock map background
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 60, color: Colors.blue[600]),
                          const SizedBox(height: 12),
                          Text(
                            'Map View',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kuala Lumpur, Malaysia',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${chargingStations.length} stations nearby',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Station markers overlay
                    ...chargingStations.take(5).map((station) {
                      return Positioned(
                        left: (station.distance * 10).clamp(20, constraints.maxWidth - 60),
                        top: (station.distance * 8).clamp(30, 200),
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_pin,
                              color: station.availableChargers > 0 
                                  ? Colors.green[600] 
                                  : Colors.red[600],
                              size: 32,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${station.distance.toStringAsFixed(1)}km',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            // Quick station list
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Stations',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selectedTab = 1),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: chargingStations.take(3).length,
                        itemBuilder: (context, index) {
                          final station = chargingStations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.ev_station,
                                color: station.availableChargers > 0 
                                    ? Colors.green[600] 
                                    : Colors.red[600],
                              ),
                              title: Text(
                                station.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${station.distance.toStringAsFixed(1)} km • ${station.availableChargers}/${station.totalChargers} available',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Set<Marker> _buildMarkers() {
    return chargingStations.map((station) {
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: '${station.distance} km • ${station.availableChargers}/${station.totalChargers} available',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          station.availableChargers > 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
      );
    }).toSet();
  }

  Widget _buildStationsTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (batteryLevel < 50)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border(left: BorderSide(color: Colors.orange[500]!, width: 4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Range Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800], fontSize: 12)),
                          Text('Consider charging within 30 km.', style: TextStyle(color: Colors.orange[700], fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (chargingStations.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No charging stations found')))
            else
              ...chargingStations.map((station) => _buildStationCard(station)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(ChargingStation station) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      if (station.address != null) ...[
                        const SizedBox(height: 4),
                        Text(station.address!, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildBadge(station.chargerType, Colors.blue),
                          if (station.operator != null) _buildBadge(station.operator!, Colors.purple),
                          if (!station.reachable) _buildBadge('Out of Range', Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(station.distance.toStringAsFixed(1), 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[600])),
                    Text('km', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailBox('Available', '${station.availableChargers}/${station.totalChargers}', 
                  station.availableChargers > 0 ? Colors.green[600] : Colors.red[600]),
                const SizedBox(width: 8),
                _buildDetailBox('Time', '${station.estimatedTime} min', Colors.grey[700]),
                const SizedBox(width: 8),
                _buildDetailBox('Energy', '${station.energyRequired}%', Colors.grey[700]),
              ],
            ),
            if (station.pricePerKwh != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 6),
                    Text('RM ${station.pricePerKwh!.toStringAsFixed(2)}/kWh',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (station.reachable) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Navigation to ${station.name}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Start Navigation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color baseColor) {
    // Define badge colors based on the base color
    Color backgroundColor;
    Color textColor;
    
    if (baseColor == Colors.blue) {
      backgroundColor = Colors.blue[100]!;
      textColor = Colors.blue[700]!;
    } else if (baseColor == Colors.purple) {
      backgroundColor = Colors.purple[100]!;
      textColor = Colors.purple[700]!;
    } else if (baseColor == Colors.red) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[700]!;
    } else {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[700]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label, 
        style: TextStyle(
          color: textColor, 
          fontSize: 10, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, Color? color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.grey[800], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text('Speed Monitor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.blue[100]!]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Current Speed', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('$currentSpeed', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        Text('km/h', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (currentSpeed / 120).clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(Colors.blue[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Recommended Speed', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 12),
                        Text('$recommendedSpeed', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green[600])),
                        Text('km/h', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: getEfficiencyColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${getEfficiencyLabel()} Driving', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  Text(
                    currentSpeed > recommendedSpeed
                        ? 'Reduce speed by ${currentSpeed - recommendedSpeed} km/h to optimize range.'
                        : 'You are maintaining optimal speed. Keep it up!',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eco-Driving Tips', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 16),
                  Text(
                    '• Maintain steady speed\n• Avoid rapid acceleration\n• Use regenerative braking\n• Plan routes to avoid steep inclines',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatteryTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.battery_full, color: getBatteryColor()),
                      const SizedBox(width: 8),
                      Text('Battery Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('$batteryLevel%', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: getBatteryColor())),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: getBatteryColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(getBatteryLabel(), style: TextStyle(fontWeight: FontWeight.bold, color: getBatteryColor(), fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: batteryLevel / 100,
                      minHeight: 24,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(getBatteryColor()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Battery Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Estimated Range', '${(batteryLevel * 3.5).toStringAsFixed(0)} km'),
                  _buildDetailRow('Battery Capacity', '60 kWh'),
                  _buildDetailRow('Residual Charge', '${(batteryLevel * 0.6).toStringAsFixed(0)} kWh'),
                  _buildDetailRow('Battery Health', 'Excellent (98%)', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Energy Consumption', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        List<int> heights = [65, 80, 55, 70, 60, 75, 65];
                        List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 24,
                              height: (heights[index] * 0.8).toDouble(),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(days[index], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text('Average consumption: 18.5 kWh/100km', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13)),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey[200], height: 1),
      ],
    );
  }
}

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
  final String? address;
  final double? pricePerKwh;
  final String? operator;
  final double latitude;
  final double longitude;

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
    this.address,
    this.pricePerKwh,
    this.operator,
    required this.latitude,
    required this.longitude,
  });
}