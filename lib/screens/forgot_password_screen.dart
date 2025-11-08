import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookswap_flutter/constants.dart';
import 'package:bookswap_flutter/methods/custom_button.dart';
import 'package:bookswap_flutter/screens/sign_in_screen.dart';

class ForgotPassword extends StatefulWidget {
  static const id = 'forgotPasswordScreen';
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar('✅ Password reset email sent to $email');

      if (mounted) {
        Navigator.pushReplacementNamed(context, SignInScreen.id);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showSnackBar('⚠️ No user found for that email.');
      } else {
        _showSnackBar('⚠️ ${e.message}');
      }
    } catch (e) {
      _showSnackBar('⚠️ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
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
                        decoration:
                            kTextFieldDecoration.copyWith(hintText: 'Email'),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Reset Password',
                              onPressed: _resetPassword),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                              context, SignInScreen.id);
                        },
                        child: Text(
                          'Back to Sign In',
                          style: kSignUpTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
