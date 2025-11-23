import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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
          return VehicleSelectionWrapper(userId: snapshot.data!.uid);
        }
        
        return const AuthScreen();
      },
    );
  }
}

class VehicleSelectionWrapper extends StatelessWidget {
  final String userId;
  
  const VehicleSelectionWrapper({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final vehicleId = userData['selectedVehicleId'];
          
          if (vehicleId == null || vehicleId.isEmpty) {
            return VehicleSelectionScreen(userId: userId);
          }
          
          return MainApp(userId: userId, vehicleId: vehicleId);
        }
        
        return VehicleSelectionScreen(userId: userId);
      },
    );
  }
}

class VehicleSelectionScreen extends StatefulWidget {
  final String userId;
  
  const VehicleSelectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Vehicle> vehicles = [];
  bool _isLoading = true;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('vehicles').get();
      setState(() {
        vehicles = snapshot.docs.map((doc) => Vehicle.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectVehicle(Vehicle vehicle) async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'selectedVehicleId': vehicle.id,
        'vehicleModel': vehicle.model,
        'batteryCapacity': vehicle.batteryCapacity,
        'vehicleEfficiency': vehicle.efficiency,
        'vehicleRange': vehicle.range,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vehicle.model} selected!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[600]!, Colors.indigo[600]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.electric_bolt, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'EzCharge',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.indigo[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select Your Vehicle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your EV for accurate charging predictions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (vehicles.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No vehicles available'),
                      ),
                    )
                  else
                    ...vehicles.map((vehicle) => _buildVehicleCard(vehicle)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final isSelected = _selectedVehicleId == vehicle.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleId = vehicle.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[200]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: Image.network(
                      vehicle.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.directions_car,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Name & Year
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.manufacturer,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vehicle.model,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vehicle.year.toString(),
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Specs Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildSpecItem(
                          icon: Icons.battery_charging_full,
                          label: 'Battery Capacity',
                          value: '${vehicle.batteryCapacity.toStringAsFixed(0)} kWh',
                          color: Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        _buildSpecItem(
                          icon: Icons.route,
                          label: 'Range',
                          value: '${vehicle.range} km',
                          color: Colors.blue,
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        _buildSpecItem(
                          icon: Icons.energy_savings_leaf,
                          label: 'Efficiency',
                          value: '${vehicle.efficiency}',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Select Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => isSelected ? _selectVehicle(vehicle) : setState(() => _selectedVehicleId = vehicle.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[300],
                        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
                        elevation: isSelected ? 4 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_circle, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            isSelected ? 'Confirm Selection' : 'Select Vehicle',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
          'selectedVehicleId': null,
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
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
        default:
          message = e.message ?? 'Authentication failed';
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

class Vehicle {
  final String id;
  final String model;
  final String manufacturer;
  final double batteryCapacity;
  final int range;
  final double efficiency;
  final Map<String, dynamic> chargingSpeed;
  final double acceleration;
  final int topSpeed;
  final String imageUrl;
  final int year;
  final int price;
  final List<String> features;
  final int weight;
  

  Vehicle({
    required this.id,
    required this.model,
    required this.manufacturer,
    required this.batteryCapacity,
    required this.range,
    required this.efficiency,
    required this.chargingSpeed,
    required this.acceleration,
    required this.topSpeed,
    required this.imageUrl,
    required this.year,
    required this.price,
    required this.features,
    required this.weight,
  });

  factory Vehicle.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Vehicle(
      id: doc.id,
      model: data['model'] ?? '',
      manufacturer: data['manufacturer'] ?? '',
      batteryCapacity: (data['batteryCapacity'] ?? 0).toDouble(),
      range: data['range'] ?? 0,
      efficiency: (data['efficiency'] ?? 0).toDouble(),
      chargingSpeed: data['chargingSpeed'] ?? {'ac': 0, 'dc': 0},
      acceleration: (data['acceleration'] ?? 0).toDouble(),
      topSpeed: data['topSpeed'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      year: data['year'] ?? 2024,
      price: data['price'] ?? 0,
      features: List<String>.from(data['features'] ?? []),
      weight: data['weight'] ?? 0,
    );
  }
}

class MainApp extends StatefulWidget {
  final String userId;
  final String vehicleId;

  const MainApp({Key? key, required this.userId, required this.vehicleId}) : super(key: key);

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
  Vehicle? selectedVehicle;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVehicleData();
    _loadChargingStations();
    _getCurrentLocation();
  }

  Future<void> _loadVehicleData() async {
    try {
      DocumentSnapshot vehicleDoc = await _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();
      
      if (vehicleDoc.exists) {
        setState(() {
          selectedVehicle = Vehicle.fromFirestore(vehicleDoc);
          recommendedSpeed = _calculateOptimalSpeed();
        });
      }
    } catch (e) {
      print('Error loading vehicle: $e');
    }
  }

  int _calculateOptimalSpeed() {
    if (selectedVehicle == null) return 70;
    double efficiencyFactor = 100 / selectedVehicle!.efficiency;
    int optimalSpeed = (60 + (efficiencyFactor * 5)).round();
    return optimalSpeed.clamp(60, 90);
  }

  double _calculateRemainingRange() {
    if (selectedVehicle == null) return batteryLevel * 3.5;
    return (batteryLevel / 100) * selectedVehicle!.range;
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

  Future<void> _changeVehicle() async {
    try {
      await _firestore.collection('users').doc(widget.userId).update({
        'selectedVehicleId': null,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startNavigation(ChargingStation station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.navigation, color: Colors.blue[600], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Navigate to Station', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(station.name, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.route, color: Colors.blue[600], size: 24),
                        const SizedBox(height: 4),
                        Text('${station.distance.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Distance', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Column(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange[600], size: 24),
                        const SizedBox(height: 4),
                        Text('${station.estimatedTime} min', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Est. Time', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Column(
                      children: [
                        Icon(Icons.battery_charging_full, color: Colors.green[600], size: 24),
                        const SizedBox(height: 4),
                        Text('${station.energyRequired}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Energy', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildNavigationOption(
                icon: Icons.map,
                title: 'Google Maps',
                subtitle: 'Open in Google Maps',
                onTap: () {
                  _openGoogleMaps(station);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildNavigationOption(
                icon: Icons.location_on,
                title: 'Waze',
                subtitle: 'Open in Waze',
                onTap: () {
                  _openWaze(station);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue[600], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(ChargingStation station) async {
    final String googleMapsUrl = 
        'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}&travelmode=driving';
    
    final Uri url = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening Google Maps to ${station.name}'),
              backgroundColor: Colors.green[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open navigation: $e'), backgroundColor: Colors.red[700]),
        );
      }
    }
  }

  Future<void> _openWaze(ChargingStation station) async {
    final String wazeUrl = 
        'https://waze.com/ul?ll=${station.latitude},${station.longitude}&navigate=yes';
    
    final Uri url = Uri.parse(wazeUrl);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening Waze to ${station.name}'),
              backgroundColor: Colors.blue[700],
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Waze: $e'), backgroundColor: Colors.red[700]),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.indigo[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.electric_bolt, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EzCharge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                  if (selectedVehicle != null)
                    Text(selectedVehicle!.model, style: const TextStyle(fontSize: 11, color: Colors.white70), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person, size: 18), SizedBox(width: 8), Text('Profile')])),
              const PopupMenuItem(value: 'vehicle', child: Row(children: [Icon(Icons.directions_car, size: 18), SizedBox(width: 8), Text('Change Vehicle')])),
              const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 18), SizedBox(width: 8), Text('Settings')])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('Logout', style: TextStyle(color: Colors.red))])),
            ],
            onSelected: (value) {
              if (value == 'logout') _handleLogout();
              else if (value == 'vehicle') _changeVehicle();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[600]!, Colors.indigo[600]!],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    icon: Icons.battery_full,
                    value: '$batteryLevel%',
                    label: '${_calculateRemainingRange().toStringAsFixed(0)} km',
                    color: getBatteryColor(),
                  ),
                  Container(width: 1, height: 50, color: Colors.white30),
                  _buildStatCard(icon: Icons.speed, value: '$currentSpeed', label: 'km/h', color: Colors.orange),
                  Container(width: 1, height: 50, color: Colors.white30),
                  _buildStatCard(
                    icon: Icons.ev_station,
                    value: '${chargingStations.where((s) => s.reachable).length}',
                    label: 'Stations',
                    color: Colors.lightBlue,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('Map', 0, Icons.map_outlined),
                _buildTab('Stations', 1, Icons.ev_station),
                _buildTab('Speed', 2, Icons.speed),
                _buildTab('Battery', 3, Icons.battery_full),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingStations ? const Center(child: CircularProgressIndicator()) : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? Colors.blue[600]! : Colors.transparent, width: 3)),
            color: isActive ? Colors.blue[50] : Colors.white,
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isActive ? Colors.blue[600] : Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.blue[600] : Colors.grey[500],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: return _buildMapTab();
      case 1: return _buildStationsTab();
      case 2: return _buildSpeedTab();
      case 3: return _buildBatteryTab();
      default: return const SizedBox();
    }
  }

  Widget _buildMapTab() {
    return CustomPaint(
      painter: MapPainter(stations: chargingStations),
      child: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Charging Station', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Your Location', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _selectedTab = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('View All Stations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
                  gradient: LinearGradient(
                    colors: [Colors.orange[100]!, Colors.orange[50]!],
                  ),
                  border: Border(left: BorderSide(color: Colors.orange[600]!, width: 4)),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Low Battery Alert', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900], fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Consider charging soon. ${chargingStations.where((s) => s.reachable).length} stations within range.', 
                            style: TextStyle(color: Colors.orange[800], fontSize: 12)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
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
                          Text(station.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (station.address != null) ...[
                            const SizedBox(height: 4),
                            Text(station.address!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildBadge(station.chargerType, Colors.blue),
                              if (station.operator != null) _buildBadge(station.operator!, Colors.purple),
                              if (!station.reachable) _buildBadge('Out of Range', Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.blue[100]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            station.distance.toStringAsFixed(1), 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                          ),
                          Text('km', style: TextStyle(color: Colors.blue[600], fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildDetailBox(
                        'Available', 
                        '${station.availableChargers}/${station.totalChargers}', 
                        station.availableChargers > 0 ? Colors.green[600] : Colors.red[600],
                      ),
                      const SizedBox(width: 8),
                      _buildDetailBox('Time', '${station.estimatedTime} min', Colors.orange[600]),
                      const SizedBox(width: 8),
                      _buildDetailBox('Energy', '${station.energyRequired}%', Colors.blue[600]),
                    ],
                  ),
                ),
                if (station.pricePerKwh != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.green[100]!],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments, size: 18, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'RM ${station.pricePerKwh!.toStringAsFixed(2)}/kWh',
                          style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
                if (station.reachable) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _startNavigation(station),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Start Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color baseColor) {
    Color backgroundColor;
    Color textColor;
    
    if (baseColor == Colors.blue) {
      backgroundColor = Colors.blue[100]!;
      textColor = Colors.blue[800]!;
    } else if (baseColor == Colors.purple) {
      backgroundColor = Colors.purple[100]!;
      textColor = Colors.purple[800]!;
    } else if (baseColor == Colors.red) {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[800]!;
    } else {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[800]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor, 
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label, 
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, Color? color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.grey[800], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (selectedVehicle != null) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.indigo[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedVehicle!.model, 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Efficiency: ${selectedVehicle!.efficiency} kWh/100km', 
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.speed, color: Colors.blue[600], size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Speed Monitor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Current Speed', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Text(
                          '$currentSpeed', 
                          style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                        ),
                        Text('km/h', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (currentSpeed / 120).clamp(0, 1),
                            minHeight: 10,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(Colors.blue[600]!),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.green[100]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Recommended Speed', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        Text(
                          '$recommendedSpeed', 
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                        Text('km/h', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 10),
                        Text(
                          'Optimized for ${selectedVehicle?.model ?? "your vehicle"}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: getEfficiencyColor().withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${getEfficiencyLabel()} Driving', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentSpeed > recommendedSpeed
                        ? 'Reduce speed by ${currentSpeed - recommendedSpeed} km/h to optimize range for your ${selectedVehicle?.model ?? "vehicle"}.'
                        : 'You are maintaining optimal speed. Keep it up!',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.lightbulb, color: Colors.green[600], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Eco-Driving Tips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '• Maintain steady speed\n• Avoid rapid acceleration\n• Use regenerative braking\n• Plan routes to avoid steep inclines',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.8),
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
            if (selectedVehicle != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text('${selectedVehicle!.model} Specs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVehicleSpecBox(
                            'Battery Capacity', 
                            '${selectedVehicle!.batteryCapacity.toStringAsFixed(0)} kWh', 
                            Icons.battery_charging_full, 
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVehicleSpecBox(
                            'Max Range', 
                            '${selectedVehicle!.range} km', 
                            Icons.route, 
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [getBatteryColor().withOpacity(0.9), getBatteryColor()],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: getBatteryColor().withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.battery_full, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text('Battery Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('$batteryLevel%', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getBatteryLabel(), 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: batteryLevel / 100,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Battery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Estimated Range', '${_calculateRemainingRange().toStringAsFixed(0)} km'),
                  _buildDetailRow('Battery Capacity', '${selectedVehicle?.batteryCapacity.toStringAsFixed(0) ?? "60"} kWh'),
                  _buildDetailRow('Residual Charge', '${((selectedVehicle?.batteryCapacity ?? 60) * batteryLevel / 100).toStringAsFixed(1)} kWh'),
                  _buildDetailRow('Battery Health', 'Excellent (98%)', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Energy Consumption', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 140,
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
                              width: 32,
                              height: heights[index].toDouble(),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(days[index], style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Average: ${selectedVehicle?.efficiency.toStringAsFixed(1) ?? "18.5"} kWh/100km', 
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSpecBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey[200], height: 1),
      ],
    );
  }
}

class MapPainter extends CustomPainter {
  final List<ChargingStation> stations;

  MapPainter({required this.stations});

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue[50]!, Colors.indigo[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid pattern
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Roads
    final roadPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final road1 = Path();
    road1.moveTo(50, size.height * 0.2);
    road1.quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.8, size.height * 0.25);
    canvas.drawPath(road1, roadPaint);

    final road2 = Path();
    road2.moveTo(size.width * 0.3, size.height * 0.4);
    road2.lineTo(size.width * 0.7, size.height * 0.5);
    canvas.drawPath(road2, roadPaint);

    final road3 = Path();
    road3.moveTo(size.width * 0.2, size.height * 0.6);
    road3.quadraticBezierTo(size.width * 0.5, size.height * 0.55, size.width * 0.8, size.height * 0.7);
    canvas.drawPath(road3, roadPaint);

    // Station markers
    final stationPositions = [
      Offset(size.width * 0.3, size.height * 0.25),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.45),
      Offset(size.width * 0.35, size.height * 0.65),
      Offset(size.width * 0.75, size.height * 0.6),
    ];

    for (int i = 0; i < stationPositions.length && i < stations.length; i++) {
      // Pulse circle
      final pulsePaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(stationPositions[i], 25, pulsePaint);

      // Main marker
      final markerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(stationPositions[i], 12, markerPaint);

      final markerBorderPaint = Paint()
        ..color = Colors.blue[600]!
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(stationPositions[i], 12, markerBorderPaint);

      // Lightning bolt
      final boltPaint = Paint()
        ..color = Colors.blue[600]!
        ..style = PaintingStyle.fill;
      
      final boltPath = Path();
      boltPath.moveTo(stationPositions[i].dx - 4, stationPositions[i].dy - 6);
      boltPath.lineTo(stationPositions[i].dx, stationPositions[i].dy);
      boltPath.lineTo(stationPositions[i].dx - 2, stationPositions[i].dy);
      boltPath.lineTo(stationPositions[i].dx + 4, stationPositions[i].dy + 6);
      boltPath.lineTo(stationPositions[i].dx, stationPositions[i].dy + 2);
      boltPath.lineTo(stationPositions[i].dx + 2, stationPositions[i].dy + 2);
      boltPath.close();
      canvas.drawPath(boltPath, boltPaint);
    }

    // Current location
    final locationPos = Offset(size.width * 0.5, size.height * 0.75);
    
    final locationPulsePaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(locationPos, 20, locationPulsePaint);

    final locationPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawCircle(locationPos, 10, locationPaint);

    final locationCenterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(locationPos, 4, locationCenterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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