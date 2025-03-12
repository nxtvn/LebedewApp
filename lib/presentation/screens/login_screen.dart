import 'package:flutter/material.dart';
import 'package:lebedew_app/src/screens/trouble_report_screen.dart';
import 'package:lebedew_app/src/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  void _handleLogin() {
    if (_passwordController.text == AppConstants.password) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TroubleReportScreen(),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Falsches Passwort. Bitte versuchen Sie es erneut.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 120,
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Passwort',
                            prefixIcon: const Icon(Icons.lock_outline),
                            errorText: _errorMessage.isEmpty ? null : _errorMessage,
                          ),
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Anmelden',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
} 