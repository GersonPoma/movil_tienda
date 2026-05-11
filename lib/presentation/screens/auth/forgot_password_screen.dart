import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _currentStep = 1; // 1: Usuario, 2: Código/Nueva Pass

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _currentStep == 1 ? _buildStep1(authProvider) : _buildStep2(authProvider),
      ),
    );
  }

  Widget _buildStep1(AuthProvider authProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset, size: 80, color: Color(0xFF6366F1)),
        const SizedBox(height: 24),
        const Text(
          'Ingresa tu nombre de usuario para recibir un código de recuperación en tu correo registrado.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de Usuario',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () async {
                  final result = await authProvider.requestRecoveryCode(_usernameController.text);
                  if (!context.mounted) return;
                  
                  if (result['success'] == true) {
                    setState(() => _currentStep = 2);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['mensaje'] ?? 'Código enviado')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'] ?? 'Error al solicitar código')),
                    );
                  }
                },
          child: authProvider.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('SOLICITAR CÓDIGO'),
        ),
      ],
    );
  }

  Widget _buildStep2(AuthProvider authProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user_outlined, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Ingresa el código enviado a tu correo y tu nueva contraseña para el usuario ${_usernameController.text}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: 'Código de Verificación',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva Contraseña',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () async {
                  final result = await authProvider.changePassword(
                    _usernameController.text,
                    _codeController.text,
                    _passwordController.text,
                  );
                  if (!context.mounted) return;

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña actualizada con éxito')),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['error'] ?? 'Error al cambiar contraseña')),
                    );
                  }
                },
          child: authProvider.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text('CAMBIAR CONTRASEÑA'),
        ),
        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: const Text('Volver atrás'),
        ),
      ],
    );
  }
}
