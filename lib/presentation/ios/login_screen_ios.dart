import 'package:flutter/cupertino.dart';
import '../../core/security/password_manager.dart';
import '../../presentation/screens/trouble_report_screen.dart';
import '../../presentation/screens/privacy_policy_screen.dart';
import '../../core/logging/app_logger.dart';

class LoginScreenIOS extends StatefulWidget {
  const LoginScreenIOS({Key? key}) : super(key: key);

  @override
  State<LoginScreenIOS> createState() => _LoginScreenIOSState();
}

class _LoginScreenIOSState extends State<LoginScreenIOS> {
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _rememberPassword = false;
  final _log = AppLogger.getLogger('LoginScreenIOS');

  @override
  void initState() {
    super.initState();
    _log.info('LoginScreenIOS initialisiert');
    _checkForSavedPassword();
  }

  Future<void> _checkForSavedPassword() async {
    _log.info('Prüfe auf gespeichertes Passwort');
    
    final isEnabled = await PasswordManager.isRememberPasswordEnabled();
    if (isEnabled) {
      _log.info('Passwort merken ist aktiviert');
      
      final savedPassword = await PasswordManager.getRememberedPassword();
      if (savedPassword.isNotEmpty) {
        _log.info('Gespeichertes Passwort gefunden');
        
        setState(() {
          _passwordController.text = savedPassword;
          _rememberPassword = true;
        });
      } else {
        _log.info('Kein gespeichertes Passwort gefunden');
      }
    } else {
      _log.info('Passwort merken ist deaktiviert');
    }
  }

  Future<void> _handleLogin() async {
    _log.info('Login-Versuch gestartet');
    
    final password = _passwordController.text;
    
    // Validiere das Passwort
    if (password.isEmpty) {
      _log.warning('Leeres Passwort eingegeben');
      setState(() {
        _errorMessage = 'Bitte geben Sie ein Passwort ein.';
      });
      return;
    }
    
    _log.info('Überprüfe Passwort');
    final isValid = await PasswordManager.verifyPassword(password);
    
    if (isValid) {
      _log.info('Passwort korrekt, Login erfolgreich');
      
      // Speichere das Passwort, wenn "Passwort merken" aktiviert ist
      if (_rememberPassword) {
        _log.info('Speichere Passwort für "Passwort merken"');
        await PasswordManager.saveRememberedPassword(password);
      } else {
        _log.info('Lösche gespeichertes Passwort');
        await PasswordManager.clearRememberedPassword();
      }
      
      if (!mounted) return;
      
      _log.info('Navigiere zur Störungsmeldungs-Ansicht');
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => const TroubleReportScreen(),
        ),
      );
    } else {
      _log.warning('Falsches Passwort eingegeben');
      
      setState(() {
        _errorMessage = 'Falsches Passwort. Bitte versuchen Sie es erneut.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey4.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 120,
                        semanticLabel: 'Lebedew Logo',
                      ),
                      const SizedBox(height: 32),
                      Semantics(
                        label: 'Passwort eingeben',
                        child: CupertinoTextField(
                          controller: _passwordController,
                          obscureText: true,
                          placeholder: 'Passwort',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(
                              CupertinoIcons.lock,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: CupertinoColors.systemGrey4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // "Passwort merken" Checkbox
                      Semantics(
                        label: 'Passwort merken',
                        child: Row(
                          children: [
                            CupertinoSwitch(
                              value: _rememberPassword,
                              onChanged: (value) {
                                setState(() {
                                  _rememberPassword = value;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Passwort merken',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        label: 'Mit Passwort anmelden',
                        child: SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            onPressed: () => _handleLogin(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: const Text('Anmelden'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'Datenschutzerklärung öffnen',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Datenschutzerklärung',
                            style: TextStyle(fontSize: 14),
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
    );
  }

  @override
  void dispose() {
    _log.info('LoginScreenIOS wird entfernt');
    _passwordController.dispose();
    super.dispose();
  }
} 