// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final user = credential.user!;

      // BLOCK UNVERIFIED USERS
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackBar('Please verify your email first. Check your inbox.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      await _ensureUserProfile(user);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          msg = 'Invalid email or password';
          break;
        case 'invalid-email':
          msg = 'Invalid email';
          break;
        default:
          msg = e.message ?? 'Sign in failed';
      }
      _showSnackBar(msg);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _ensureUserProfile(User user) async {
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final doc = await docRef.get();
    if (!doc.exists) {
      final name = user.displayName ?? user.email?.split('@').first ?? 'User';
      await docRef.set({
        'displayName': name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.book, size: 80, color: Color(0xFFFFD700)),
              const Text('BookSwap',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Text('Swap Your Books With Other Students',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Sign In'),
                    ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                ),
                child: const Text('Create Account',
                    style: TextStyle(color: Color(0xFFFFD700))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
