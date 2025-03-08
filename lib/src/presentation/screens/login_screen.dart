import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'trouble_report_screen.dart';
import '../../core/security/password_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  /// Login-Funktion mit Passwortvalidierung
  Future<void> _login() async {
    if (Platform.isIOS || (_formKey.currentState?.validate() ?? false)) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final isValid = await PasswordManager.verifyPassword(_passwordController.text);

        if (isValid && mounted) {
          Navigator.pushReplacement(
            context,
            Platform.isIOS
                ? CupertinoPageRoute(builder: (context) => const TroubleReportScreen())
                : MaterialPageRoute(builder: (context) => const TroubleReportScreen()),
          );
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Falsches Passwort';
          });
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isIOS ? _buildCupertinoLogin(context) : _buildMaterialLogin(context);
  }

  /// Cupertino Login für iOS
  Widget _buildCupertinoLogin(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 120,
                ),
                const SizedBox(height: 60),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                    color: CupertinoColors.white,
                  ),
                  child: CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Passwort',
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: CupertinoColors.black),
                    placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(
                        CupertinoIcons.lock,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        color: CupertinoColors.systemGrey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    onSubmitted: (_) => _login(),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: CupertinoColors.destructiveRed),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: const Color(0xFF007AFF), // iOS Blau
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(color: CupertinoColors.white),
                              SizedBox(width: 8),
                              Text(
                                'Anmelden...',
                                style: TextStyle(color: CupertinoColors.white),
                              ),
                            ],
                          )
                        : const Text(
                            'Anmelden',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.white,
                            ),
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

  /// Material Login für Android
  Widget _buildMaterialLogin(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 120,
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Passwort',
                              prefixIcon: const Icon(Icons.lock_outline),
                              errorText: _errorMessage.isEmpty ? null : _errorMessage,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty 
                                ? 'Bitte Passwort eingeben' 
                                : null,
                            onFieldSubmitted: (_) => _login(),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Anmelden...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Anmelden',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
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
      ),
    );
  }
} 