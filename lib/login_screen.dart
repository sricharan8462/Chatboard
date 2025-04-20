import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  final String firstName;
  final String lastName;
  final String role;
  final DateTime registrationDate;

  UserDetails({
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.registrationDate,
  });

  factory UserDetails.fromMap(Map<String, dynamic> data) {
    return UserDetails(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      role: data['role'] ?? 'user',
      registrationDate:
          (data['registrationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'registrationDate': Timestamp.fromDate(registrationDate),
    };
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLogin = true;

  Future<void> _authUser() async {
    try {
      UserCredential userCredential;
      if (_isLogin) {
        // Login with email and password
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Verify user data after login
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          UserDetails user = UserDetails.fromMap(data);
          print(
            'User data after login: ${user.firstName} ${user.lastName}, Role: ${user.role}',
          );
        } else {
          print(
            'User document does not exist for UID: ${userCredential.user!.uid}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User data not found. Please register first.'),
            ),
          );
          return;
        }
      } else {
        // Register new user
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        // Create UserDetails object
        UserDetails userDetails = UserDetails(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          role: 'user',
          registrationDate: DateTime.now(),
        );
        // Save user data as a single document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userDetails.toMap());
        print(
          'User data saved: ${userDetails.firstName} ${userDetails.lastName}',
        );
      }

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Auth error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isLogin) ...[
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
            ],
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authUser,
              child: Text(_isLogin ? 'Login' : 'Register'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Register instead' : 'Login instead'),
            ),
          ],
        ),
      ),
    );
  }
}
