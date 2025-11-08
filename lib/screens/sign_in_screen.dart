// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookswap_flutter/constants.dart';
import 'package:bookswap_flutter/methods/custom_button.dart';
import 'package:bookswap_flutter/screens/home_screen.dart';
import 'package:bookswap_flutter/screens/forgot_password_screen.dart';
import 'package:bookswap_flutter/screens/sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  static const id = 'sign_in_screen'; // ← Ensures navigation works
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      if (!user.emailVerified) {
        _showSnackBar('Please verify your email before signing in.');
        await user.sendEmailVerification();
        return;
      }

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
          msg = 'No user found for that email.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        default:
          msg = e.message ?? 'Sign in failed';
      }
      _showSnackBar(msg);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(text: 'Sign In', onPressed: _signIn),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, SignUpScreen.id);
                      },
                      child: Text(
                        'Create an account',
                        style: kSignUpTextStyle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, ForgotPassword.id);
                      },
                      child: Text(
                        'Forgot Password?',
                        style: kSignUpTextStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
