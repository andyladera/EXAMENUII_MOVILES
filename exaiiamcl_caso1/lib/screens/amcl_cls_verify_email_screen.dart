import 'dart:async';
import 'package:flutter/material.dart';
import '../services/amcl_cls_auth_service.dart';

class AMCLclsVerifyEmailScreen extends StatefulWidget {
  const AMCLclsVerifyEmailScreen({super.key});

  @override
  State<AMCLclsVerifyEmailScreen> createState() => _AMCLclsVerifyEmailScreenState();
}

class _AMCLclsVerifyEmailScreenState extends State<AMCLclsVerifyEmailScreen> {
  final _authService = AMCLclsAuthService();
  Timer? _timer;
  bool _isChecking = false;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool isVerified = await _authService.checkEmailVerified();
      
      if (isVerified && mounted) {
        timer.cancel();
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  Future<void> _resendEmail() async {
    if (!_canResend) return;

    setState(() => _canResend = false);

    try {
      await _authService.resendVerificationEmail();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email de verificación enviado'),
          backgroundColor: Colors.green,
        ),
      );

      // Esperar 60 segundos antes de permitir reenviar
      await Future.delayed(const Duration(seconds: 60));
      if (mounted) {
        setState(() => _canResend = true);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar email'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _canResend = true);
    }
  }

  Future<void> _checkNow() async {
    setState(() => _isChecking = true);

    bool isVerified = await _authService.checkEmailVerified();
    
    if (!mounted) return;

    if (isVerified) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email aún no verificado. Por favor revisa tu correo.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 100,
                color: Colors.blue.shade700,
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Verifica tu Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Hemos enviado un enlace de verificación a tu correo electrónico.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Por favor, haz clic en el enlace para verificar tu cuenta.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Botón Verificar Ahora
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkNow,
                icon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isChecking ? 'Verificando...' : 'Ya verifiqué mi email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botón Reenviar Email
              TextButton.icon(
                onPressed: _canResend ? _resendEmail : null,
                icon: const Icon(Icons.send),
                label: Text(_canResend ? 'Reenviar email' : 'Espera 60s para reenviar'),
              ),
              
              const SizedBox(height: 32),
              
              // Cerrar sesión
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
