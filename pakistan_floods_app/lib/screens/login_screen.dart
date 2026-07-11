import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'analyst_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'Command Officer');
  final _passcodeCtrl = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  void _performLogin() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final code = _passcodeCtrl.text.trim();
    const securePasscode = String.fromEnvironment('NDMA_PASSCODE', defaultValue: 'ndma2024');

    if (code == securePasscode) {
      AppState().isLoggedIn = true;
      AppState().isGovernmentUser = true;
      AppState().userName = _usernameCtrl.text.trim();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AnalystShell()),
          );
        }
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'SECURE LOG: ACCESS DENIED. Invalid security code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const prNavy = Color(0xFF1B365D);
    const scForest = Color(0xFF2D6A4F);
    const bgLight = Color(0xFFF1F5F9);
    const borderSlate = Color(0xFFCBD5E1);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF475569);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // State Emblem/Branding
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderSlate, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: prNavy, size: 24),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GOVERNMENT OF PAKISTAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: scForest,
                                ),
                              ),
                              Text(
                                'DISASTER MANAGEMENT AUTHORITY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: prNavy,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'NATIONAL DISASTER ANALYTICS COMMAND',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: prNavy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'EOC Platform — System Access Control Portal',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderSlate, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'SECURE LOGIN REQUEST',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: prNavy,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Designation
                          const Text(
                            'Designation / Officer ID',
                            style: TextStyle(
                              fontSize: 10,
                              color: textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _usernameCtrl,
                            style: const TextStyle(color: textDark, fontSize: 13, fontFamily: 'monospace'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                  return 'Required field: Officer designation';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Security Passcode
                          const Text(
                            'Emergency Security Passcode',
                            style: TextStyle(
                              fontSize: 10,
                              color: textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passcodeCtrl,
                            obscureText: true,
                            style: const TextStyle(color: textDark, fontSize: 13, fontFamily: 'monospace'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required field: Security Passcode';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC53030).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFC53030).withOpacity(0.3), width: 1.2),
                              ),
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Color(0xFFC53030), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Action button
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _performLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: prNavy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text('AUTHENTICATE REQUEST & ENTER'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Official Notice & Build-time warning (Accessibility & compliance)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Soft blue
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: prNavy, size: 14),
                            SizedBox(width: 8),
                            Text(
                              'DEVELOPMENT DEPLOYMENT FLAG',
                              style: TextStyle(color: prNavy, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Temporary Passcode: ndma2024. For test validation purposes only. Strip credential flags prior to staging production release.',
                          style: TextStyle(color: textMuted, fontSize: 10, height: 1.4),
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
    );
  }
}
