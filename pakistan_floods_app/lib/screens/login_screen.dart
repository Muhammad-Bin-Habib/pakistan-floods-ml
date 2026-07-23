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
  bool _obscurePassword = true;
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

      Future.delayed(const Duration(milliseconds: 400), () {
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
        _errorMessage = 'Access denied. Invalid security credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const prGreen = Color(0xFF10B981);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.fingerprint_rounded, color: prGreen, size: 40),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your credentials to access the NDMA Predictive Intelligence Portal.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Officer Designation',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameCtrl,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Designation is required';
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'e.g. Commander Islam',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Security Passcode',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passcodeCtrl,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Passcode is required';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter your passcode',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF9CA3AF)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 20,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _performLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF9CA3AF), size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Restricted Area. Authorized Access Only (Test: ndma2024)',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
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
