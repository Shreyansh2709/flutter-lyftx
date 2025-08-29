import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mongo_dart/mongo_dart.dart' show where, modify;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Database.connect();
  runApp(MyApp());
}

// Database class
class Database {
  static late mongo.Db _db;
  static late mongo.DbCollection users;
  static late mongo.DbCollection ambulances;
  static late mongo.DbCollection bookings;
  
  static Future connect() async {
    _db = await mongo.Db.create("mongodb://localhost:27017/lyftx_db");
    await _db.open();
    users = _db.collection('users');
    ambulances = _db.collection('ambulances');
    bookings = _db.collection('bookings');  
    print('Connected to database');
  }
  
  static Future close() async {
    await _db.close();
  }
}

// Main App
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LyftX',
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ColorScheme.light(
          primary: Colors.green,
          secondary: Colors.green.shade300,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
      ),
      home: IndexPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Index Page
class IndexPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital,
              size: 80,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'LyftX',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Emergency Ambulance Service',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInUser()),
                  );
                },
                child: Text('Sign In as User'),
              ),
            ),
            SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInAmbulance()),
                  );
                },
                child: Text('Sign In as Ambulance'),
              ),
            ),
            SizedBox(height: 30),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? "),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpUser()),
                    );
                  },
                  child: Text('Sign Up as User'),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpAmbulance()),
                );
              },
              child: Text('Sign Up as Ambulance Service'),
            ),
          ],
        ),
      ),
    );
  }
}

// User Sign Up
class SignUpUser extends StatefulWidget {
  @override
  @override
  State<SignUpUser> createState() => _SignUpUserState();
}

class _SignUpUserState extends State<SignUpUser> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var existingUser = await Database.users.findOne({
          'phoneNumber': _phoneController.text
        });

        if (existingUser != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User with this phone number already exists')),
          );
          return;
        }

        await Database.users.insertOne({
          'name': _nameController.text,
          'phoneNumber': _phoneController.text,
          'password': _passwordController.text,
          'status': 'open'
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating account: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up as User')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signUp,
                        child: Text('Sign Up'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ambulance Sign Up
class SignUpAmbulance extends StatefulWidget {
  @override
  _SignUpAmbulanceState createState() => _SignUpAmbulanceState();
}

class _SignUpAmbulanceState extends State<SignUpAmbulance> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedType = 'BLS';

  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var existingAmbulance = await Database.ambulances.findOne({
          'license': _licenseController.text
        });

        if (existingAmbulance != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ambulance with this license already exists')),
          );
          return;
        }

        var existingPhone = await Database.ambulances.findOne({
          'phoneNumber': _phoneController.text
        });

        if (existingPhone != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Phone number already registered')),
          );
          return;
        }

        await Database.ambulances.insertOne({
          'license': _licenseController.text,
          'phoneNumber': _phoneController.text,
          'password': _passwordController.text,
          'type': _selectedType,
          'status': 'closed'
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ambulance registered successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering ambulance: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up as Ambulance Service')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _licenseController,
                decoration: InputDecoration(
                  labelText: 'License Number',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter license number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField(
                value: _selectedType,
                items: [
                  DropdownMenuItem(value: 'BLS', child: Text('Basic Life Support (BLS)')),
                  DropdownMenuItem(value: 'ALS', child: Text('Advanced Life Support (ALS)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value.toString();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Ambulance Type',
                  prefixIcon: Icon(Icons.airport_shuttle),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signUp,
                        child: Text('Register Ambulance'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// User Sign In
class SignInUser extends StatefulWidget {
  @override
  _SignInUserState createState() => _SignInUserState();
}

class _SignInUserState extends State<SignInUser> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var user = await Database.users.findOne({
          'phoneNumber': _phoneController.text,
          'password': _passwordController.text
        });

        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserDashboard(user: user)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid phone number or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In as User')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        child: Text('Sign In'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ambulance Sign In
class SignInAmbulance extends StatefulWidget {
  @override
  _SignInAmbulanceState createState() => _SignInAmbulanceState();
}

class _SignInAmbulanceState extends State<SignInAmbulance> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var ambulance = await Database.ambulances.findOne({
          'phoneNumber': _phoneController.text,
          'password': _passwordController.text
        });

        if (ambulance != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AmbulanceDashboard(ambulance: ambulance)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid phone number or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In as Ambulance')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        child: Text('Sign In'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// User Dashboard
class UserDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  UserDashboard({required this.user});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  List<Map<String, dynamic>> _bookings = [];
  bool _hasActiveBooking = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _checkActiveBooking();
  }

  Future<void> _loadBookings() async {
    try {
      var bookings = await Database.bookings.find({
        'userPhoneNumber': widget.user['phoneNumber']
      }).toList();

      setState(() {
        _bookings = bookings;
      });
    } catch (e) {
      print('Error loading bookings: $e');
    }
  }

  Future<void> _checkActiveBooking() async {
    try {
      var activeBooking = await Database.bookings.findOne({
        'userPhoneNumber': widget.user['phoneNumber'],
        'status': 'unverified'
      });

      setState(() {
        _hasActiveBooking = activeBooking != null;
      });
    } catch (e) {
      print('Error checking active booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserAccount(user: widget.user)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasActiveBooking
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BookAmbulance(user: widget.user)),
                        ).then((_) {
                          _loadBookings();
                          _checkActiveBooking();
                        });
                      },
                child: Text(_hasActiveBooking ? 'Active Booking in Progress' : 'Book Ambulance'),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: _bookings.isEmpty
                        ? Center(child: Text('No booking history'))
                        : ListView.builder(
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              var booking = _bookings[index];
                              return Card(
                                child: ListTile(
                                  title: Text('Ambulance: ${booking['ambulanceType']}'),
                                  subtitle: Text('Status: ${booking['status']}'),
                                  trailing: Text('\$${booking['cost']?.toStringAsFixed(2) ?? '0.00'}'),
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
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserFinance(user: widget.user)),
                  );
                },
                child: Text('Finance'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserAccount(user: widget.user)),
                  );
                },
                child: Text('Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ambulance Dashboard
class AmbulanceDashboard extends StatefulWidget {
  final Map<String, dynamic> ambulance;

  AmbulanceDashboard({required this.ambulance});

  @override
  _AmbulanceDashboardState createState() => _AmbulanceDashboardState();
}

class _AmbulanceDashboardState extends State<AmbulanceDashboard> {
  bool _bookingEnabled = false;
  Timer? _bookingCheckTimer;

  @override
  void initState() {
    super.initState();
    _bookingEnabled = widget.ambulance['status'] == 'open';
    _startBookingCheckTimer();
  }

  @override
  void dispose() {
    _bookingCheckTimer?.cancel();
    super.dispose();
  }

  void _startBookingCheckTimer() {
    _bookingCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_bookingEnabled) {
        _checkForBookings();
      }
    });
  }

  Future<void> _checkForBookings() async {
    try {
      var booking = await Database.bookings.findOne({
        'ambulanceType': widget.ambulance['type'],
        'status': 'unverified'
      });

      if (booking != null) {
        var allAmbulances = await Database.ambulances.find({
          'type': widget.ambulance['type'],
          'status': 'open'
        }).toList();

        if (allAmbulances.isNotEmpty && allAmbulances[0]['_id'] == widget.ambulance['_id']) {
          await Database.bookings.update(
            where.id(booking['_id']),
            modify.set('ambulancePhoneNumber', widget.ambulance['phoneNumber'])
          );

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookingFound(booking: booking, ambulance: widget.ambulance)),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking for bookings: $e');
    }
  }

  Future<void> _toggleBookingStatus() async {
    try {
      String newStatus = _bookingEnabled ? 'closed' : 'open';
      
      await Database.ambulances.update(
        where.id(widget.ambulance['_id']),
        modify.set('status', newStatus)
      );

      setState(() {
        _bookingEnabled = !_bookingEnabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking ${_bookingEnabled ? 'enabled' : 'disabled'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ambulance Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AmbulanceAccount(ambulance: widget.ambulance)),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.airport_shuttle,
              size: 100,
              color: Colors.green,
            ),
            SizedBox(height: 20),
            Text(
              'License: ${widget.ambulance['license']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Type: ${widget.ambulance['type']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 30),
            SwitchListTile(
              title: Text('Accept Bookings'),
              value: _bookingEnabled,
              onChanged: (value) {
                _toggleBookingStatus();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AmbulanceFinance(ambulance: widget.ambulance)),
                  );
                },
                child: Text('Finance'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AmbulanceAccount(ambulance: widget.ambulance)),
                  );
                },
                child: Text('Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Book Ambulance
class BookAmbulance extends StatefulWidget {
  final Map<String, dynamic> user;

  BookAmbulance({required this.user});

  @override
  _BookAmbulanceState createState() => _BookAmbulanceState();
}

class _BookAmbulanceState extends State<BookAmbulance> {
  String _selectedType = 'BLS';
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _bookAmbulance() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please wait for location to be determined')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var availableAmbulances = await Database.ambulances.find({
        'type': _selectedType,
        'status': 'open'
      }).toList();

      if (availableAmbulances.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No ambulances available at this moment')),
        );
        return;
      }

      String otp = _generateOTP();
      double cost = _selectedType == 'BLS' ? 50.0 : 100.0;

      var booking = await Database.bookings.insertOne({
        'userPhoneNumber': widget.user['phoneNumber'],
        'userLoc': {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude
        },
        'ambulanceType': _selectedType,
        'otp': otp,
        'status': 'unverified',
        'cost': cost,
        'createdAt': DateTime.now()
      });

      await Database.users.update(
        where.id(widget.user['_id']),
        modify.set('status', 'booked')
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BookingSuccessful(bookingId: booking.id, user: widget.user)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking ambulance: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateOTP() {
    return (1000 + Random().nextInt(9000)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Ambulance')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _selectedType,
              items: [
                DropdownMenuItem(value: 'BLS', child: Text('Basic Life Support (BLS)')),
                DropdownMenuItem(value: 'ALS', child: Text('Advanced Life Support (ALS)')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value.toString();
                });
              },
              decoration: InputDecoration(
                labelText: 'Ambulance Type',
                prefixIcon: Icon(Icons.airport_shuttle),
              ),
            ),
            SizedBox(height: 20),
            _currentPosition == null
                ? CircularProgressIndicator()
                : Text(
                    'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                  ),
            SizedBox(height: 30),
            _isLoading
                ? CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _bookAmbulance,
                      child: Text('Book Ambulance'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// Booking Successful
class BookingSuccessful extends StatefulWidget {
  final mongo.ObjectId bookingId;
  final Map<String, dynamic> user;

  BookingSuccessful({required this.bookingId, required this.user});

  @override
  _BookingSuccessfulState createState() => _BookingSuccessfulState();
}

class _BookingSuccessfulState extends State<BookingSuccessful> {
  Map<String, dynamic>? _booking;
  Timer? _statusCheckTimer;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _startStatusCheckTimer();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkBookingStatus();
    });
  }

  Future<void> _loadBooking() async {
    try {
      var booking = await Database.bookings.findOne(where.id(widget.bookingId));
      setState(() {
        _booking = booking;
      });
    } catch (e) {
      print('Error loading booking: $e');
    }
  }

  Future<void> _checkBookingStatus() async {
    try {
      var booking = await Database.bookings.findOne(where.id(widget.bookingId));
      
      if (booking != null) {
        if (booking['status'] == 'verified') {
          _statusCheckTimer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserDashboard(user: widget.user)),
          );
        } else if (booking['ambulancePhoneNumber'] == null) {
          _statusCheckTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking was cancelled')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error checking booking status: $e');
    }
  }

  Future<void> _cancelBooking() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      await Database.bookings.remove(where.id(widget.bookingId));
      
      await Database.users.update(
        where.id(widget.user['_id']),
        modify.set('status', 'open')
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking cancelled')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: $e')),
      );
    } finally {
      setState(() {
        _isCancelling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Successful')),
      body: _booking == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Booking Confirmed!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text('OTP: ${_booking!['otp']}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text('Ambulance Type: ${_booking!['ambulanceType']}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text('Estimated Cost: \$${_booking!['cost']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 30),
                  _isCancelling
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _cancelBooking,
                            child: Text('Cancel Booking'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

// Booking Found
class BookingFound extends StatefulWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> ambulance;

  BookingFound({required this.booking, required this.ambulance});

  @override
  _BookingFoundState createState() => _BookingFoundState();
}

class _BookingFoundState extends State<BookingFound> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _statusCheckTimer;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startStatusCheckTimer();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkBookingStatus();
    });
  }

  Future<void> _loadUser() async {
    try {
      var user = await Database.users.findOne({
        'phoneNumber': widget.booking['userPhoneNumber']
      });
      setState(() {
        _user = user;
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _checkBookingStatus() async {
    try {
      var booking = await Database.bookings.findOne(where.id(widget.booking['_id']));
      
      if (booking == null || booking['ambulancePhoneNumber'] != widget.ambulance['phoneNumber']) {
        _statusCheckTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking was cancelled')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error checking booking status: $e');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text != widget.booking['otp']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wrong OTP')),
      );
      return;
    }

    try {
      await Database.bookings.update(
        where.id(widget.booking['_id']),
        modify.set('status', 'verified')
      );

      await Database.ambulances.update(
        where.id(widget.ambulance['_id']),
        modify.set('status', 'booked')
      );

      await Database.users.update(
        where.eq('phoneNumber', widget.booking['userPhoneNumber']),
        modify.set('status', 'booked')
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verified successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AmbulanceDashboard(ambulance: widget.ambulance)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying OTP: $e')),
      );
    }
  }

  Future<void> _cancelBooking() async {
    try {
      await Database.bookings.update(
        where.id(widget.booking['_id']),
        modify.unset('ambulancePhoneNumber')
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking cancelled')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking Found')),
      body: _user == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Name: ${_user!['name']}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text('Phone: ${_user!['phoneNumber']}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text('Location: ${widget.booking['userLoc'] != null ? '${widget.booking['userLoc']['latitude'].toStringAsFixed(4)}, ${widget.booking['userLoc']['longitude'].toStringAsFixed(4)}' : 'Unknown'}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _verifyOTP,
                          child: Text('Verify OTP'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _cancelBooking,
                          child: Text('Cancel'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// User Account Management
class UserAccount extends StatefulWidget {
  final Map<String, dynamic> user;

  UserAccount({required this.user});

  @override
  _UserAccountState createState() => _UserAccountState();
}

class _UserAccountState extends State<UserAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'];
    _phoneController.text = widget.user['phoneNumber'];
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var updateData = {
          'name': _nameController.text,
        };

        if (_passwordController.text.isNotEmpty) {
          updateData['password'] = _passwordController.text;
        }

        var modifier = modify;
        updateData.forEach((key, value) {
          modifier = modifier.set(key, value);
        });
        await Database.users.update(
          where.id(widget.user['_id']),
          modifier
        );

        await Database.bookings.updateMany(
          where.eq('userPhoneNumber', widget.user['phoneNumber']),
          modify.set('userPhoneNumber', _phoneController.text),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );

        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });

                try {
                  await Database.users.remove(where.id(widget.user['_id']));
                  await Database.bookings.remove(
                    where.eq('userPhoneNumber', widget.user['phoneNumber'])
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account deleted successfully')),
                  );

                  Navigator.popUntil(context, (route) => route.isFirst);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Management'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _nameController.text = widget.user['name'];
                  _phoneController.text = widget.user['phoneNumber'];
                  _passwordController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      enabled: false,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password (leave empty to keep current)',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateUser,
                          child: Text('Save Changes'),
                        ),
                      ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _deleteAccount,
                        child: Text('Delete Account'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Ambulance Account Management
class AmbulanceAccount extends StatefulWidget {
  final Map<String, dynamic> ambulance;

  AmbulanceAccount({required this.ambulance});

  @override
  _AmbulanceAccountState createState() => _AmbulanceAccountState();
}

class _AmbulanceAccountState extends State<AmbulanceAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedType = 'BLS';

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _licenseController.text = widget.ambulance['license'];
    _phoneController.text = widget.ambulance['phoneNumber'];
    _selectedType = widget.ambulance['type'];
  }

  Future<void> _updateAmbulance() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        var updateData = {
          'license': _licenseController.text,
          'type': _selectedType,
        };

        if (_passwordController.text.isNotEmpty) {
          updateData['password'] = _passwordController.text;
        }

        var modifier = modify;
        updateData.forEach((key, value) {
          modifier = modifier.set(key, value);
        });
        await Database.ambulances.update(
          where.id(widget.ambulance['_id']),
          modifier
        );

        if (widget.ambulance['phoneNumber'] != _phoneController.text) {
          await Database.bookings.updateMany(
            where.eq('ambulancePhoneNumber', widget.ambulance['phoneNumber']),
            modify.set('ambulancePhoneNumber', _phoneController.text),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );

        setState(() {
          _isEditing = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete your ambulance account? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });

                try {
                  await Database.ambulances.remove(where.id(widget.ambulance['_id']));

                  await Database.bookings.updateMany(
                    where.eq('ambulancePhoneNumber', widget.ambulance['phoneNumber']),
                    modify.unset('ambulancePhoneNumber'),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Account deleted successfully')),
                  );

                  Navigator.popUntil(context, (route) => route.isFirst);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting account: $e')),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ambulance Account'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _licenseController.text = widget.ambulance['license'];
                  _phoneController.text = widget.ambulance['phoneNumber'];
                  _selectedType = widget.ambulance['type'];
                  _passwordController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _licenseController,
                      decoration: InputDecoration(
                        labelText: 'License Number',
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      enabled: _isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter license number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField(
                      value: _selectedType,
                      items: [
                        DropdownMenuItem(value: 'BLS', child: Text('Basic Life Support (BLS)')),
                        DropdownMenuItem(value: 'ALS', child: Text('Advanced Life Support (ALS)')),
                      ],
                      onChanged: _isEditing
                          ? (value) {
                              setState(() {
                                _selectedType = value.toString();
                              });
                            }
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Ambulance Type',
                        prefixIcon: Icon(Icons.airport_shuttle),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      enabled: false,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password (leave empty to keep current)',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      enabled: _isEditing,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateAmbulance,
                          child: Text('Save Changes'),
                        ),
                      ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _deleteAccount,
                        child: Text('Delete Account'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// User Finance
class UserFinance extends StatefulWidget {
  final Map<String, dynamic> user;

  UserFinance({required this.user});

  @override
  _UserFinanceState createState() => _UserFinanceState();
}

class _UserFinanceState extends State<UserFinance> {
  List<Map<String, dynamic>> _transactions = [];
  double _totalExpenditure = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var selector = where.eq('userPhoneNumber', widget.user['phoneNumber']);
      
      if (_startDate != null && _endDate != null) {
        selector = where
          .eq('userPhoneNumber', widget.user['phoneNumber'])
          .and(where.gte('createdAt', _startDate!).lte('createdAt', _endDate!));
      }

      var transactions = await Database.bookings.find(selector).toList();
      
      double total = 0.0;
      for (var transaction in transactions) {
        if (transaction['cost'] != null) {
          total += transaction['cost'];
        }
      }

      setState(() {
        _transactions = transactions;
        _totalExpenditure = total;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finance')),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Total Expenditure',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\$${_totalExpenditure.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, color: Colors.green),
                  ),
                  if (_startDate != null && _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectDateRange,
                    child: Text(_startDate == null ? 'Select Date Range' : 'Change Date Range'),
                  ),
                ),
                if (_startDate != null)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadTransactions();
                    },
                  ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(child: Text('No transactions found'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          var transaction = _transactions[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text('Ambulance: ${transaction['ambulanceType']}'),
                              subtitle: Text(
                                transaction['createdAt'] != null
                                    ? DateFormat('MMM d, y - hh:mm a').format(transaction['createdAt'])
                                    : 'Unknown date',
                              ),
                              trailing: Text(
                                '\$${transaction['cost']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Ambulance Finance
class AmbulanceFinance extends StatefulWidget {
  final Map<String, dynamic> ambulance;

  AmbulanceFinance({required this.ambulance});

  @override
  _AmbulanceFinanceState createState() => _AmbulanceFinanceState();
}

class _AmbulanceFinanceState extends State<AmbulanceFinance> {
  List<Map<String, dynamic>> _transactions = [];
  double _totalEarnings = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var selector = where.eq('ambulancePhoneNumber', widget.ambulance['phoneNumber']);
      
      if (_startDate != null && _endDate != null) {
        selector = where
          .eq('ambulancePhoneNumber', widget.ambulance['phoneNumber'])
          .and(where.gte('createdAt', _startDate!).lte('createdAt', _endDate!));
      }

      var transactions = await Database.bookings.find(selector).toList();
      
      double total = 0.0;
      for (var transaction in transactions) {
        if (transaction['cost'] != null) {
          total += transaction['cost'];
        }
      }

      setState(() {
        _transactions = transactions;
        _totalEarnings = total;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Finance')),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Total Earnings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\$${_totalEarnings.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 24, color: Colors.green),
                  ),
                  if (_startDate != null && _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${DateFormat('MMM d, y').format(_startDate!)} - ${DateFormat('MMM d, y').format(_endDate!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectDateRange,
                    child: Text(_startDate == null ? 'Select Date Range' : 'Change Date Range'),
                  ),
                ),
                if (_startDate != null)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadTransactions();
                    },
                  ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? Center(child: Text('No transactions found'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          var transaction = _transactions[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              title: Text('User: ${transaction['userPhoneNumber']}'),
                              subtitle: Text(
                                transaction['createdAt'] != null
                                    ? DateFormat('MMM d, y - hh:mm a').format(transaction['createdAt'])
                                    : 'Unknown date',
                              ),
                              trailing: Text(
                                '\$${transaction['cost']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}