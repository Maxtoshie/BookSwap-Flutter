// lib/screens/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookswap_flutter/constants.dart';
import 'package:bookswap_flutter/methods/custom_button.dart';
import 'package:bookswap_flutter/screens/sign_in_screen.dart';
import 'package:bookswap_flutter/screens/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  static const id = 'signUpScreen';
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _verificationSent = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (username.length < 3) {
      _showSnackBar('Username must be at least 3 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final uid = user.uid;

      // 2. Save profile
      await _firestore.collection('users').doc(uid).set({
        'displayName': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Update display name
      await user.updateDisplayName(username);

      // 4. SEND VERIFICATION EMAIL
      await user.sendEmailVerification();

      setState(() => _verificationSent = true);

      _showSnackBar('Verification email sent! Check your inbox.');

      // Auto-check every 3 seconds
      _startVerificationCheck(user);
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'weak-password':
          msg = 'Password too weak (min 6 characters)';
          break;
        case 'email-already-in-use':
          msg = 'Email already registered';
          break;
        case 'invalid-email':
          msg = 'Invalid email';
          break;
        default:
          msg = e.message ?? 'Signup failed';
      }
      _showSnackBar(msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startVerificationCheck(User user) {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      await user.reload();
      if (user.emailVerified) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        return false; // Stop loop
      }
      return true; // Continue
    });
  }

  Future<void> _resendVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      _showSnackBar('Verification email resent!');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificationSent) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, size: 80, color: Color(0xFFFFD700)),
                const SizedBox(height: 24),
                const Text(
                  'Check Your Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'We sent a verification link to:\n${emailController.text}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _resendVerification,
                  child: const Text('Resend Email'),
                ),
                const SizedBox(height: 16),
                const Text('Click the link in your email to continue.'),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(tag: 'logo', child: Image.asset(kLogoPath)),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration:
                      kTextFieldDecoration.copyWith(hintText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  decoration:
                      kTextFieldDecoration.copyWith(hintText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: 'Confirm Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(text: 'Sign Up', onPressed: _signUp),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                  ),
                  child: Text('Already have an account? Sign In',
                      style: kSignUpTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
