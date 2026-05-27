import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/security_service.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';

class ManagerLoginView extends StatefulWidget {
  const ManagerLoginView({super.key});

  @override
  State<ManagerLoginView> createState() => _ManagerLoginViewState();
}

class _ManagerLoginViewState extends State<ManagerLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  final _api = RegisterService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Preencha todos os campos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Tenta logar via Firebase Authentication primeiro
      UserCredential? credential;
      try {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (authError) {
        print("Auth falhou, tentando migração: $authError");
      }

      AppUser? user;

      if (credential != null) {
        // Logado com sucesso no Firebase Auth!
        user = await _api.getUserByEmail(email);

        if (user == null) {
          // Conta excluída no Firestore, desloga.
          await FirebaseAuth.instance.signOut();
          setState(() => _error = 'Usuário não cadastrado ou removido.');
          return;
        }

        // Garante que o authUid esteja atualizado no Firestore
        if (user.authUid != credential.user!.uid) {
          user.authUid = credential.user!.uid;
          await _api.saveUser(user);
        }
      } else {
        // Se falhou no Auth, tenta a Lazy Migration
        user = await _api.getUserByEmail(email);

        if (user != null && 
            SecurityService.verifyPassword(password, user.password) &&
            user.type == 'gerente') {
          // Cria o usuário no Firebase Auth
          final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          user.authUid = newCred.user!.uid;
          user.password = SecurityService.hashPassword(password);
          await _api.saveUser(user);
        } else {
          setState(() => _error = 'E-mail ou senha incorretos, ou sem perfil de gerente.');
          return;
        }
      }

      // Valida status e tipo de acesso
      if (user.status == 'Ativo' && user.type == 'gerente') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('manager_user_id', user.id);
        await prefs.setString('manager_user_name', user.name);
        await prefs.setString('manager_user_role', user.role);
        await prefs.setString('manager_store_id', user.storeId);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/gerente_dashboard', arguments: user);
        }
      } else {
        setState(() => _error = 'Este usuário está inativo. Contate o administrador.');
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      setState(() => _error = 'Erro ao autenticar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Fundo escuro diferenciado
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B3C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2D4A6A), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo e título
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066FF), Color(0xFF00BFFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          IconsaxPlusLinear.buildings_2,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Portal do Gerente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Acesso restrito à sua loja',
                        style: TextStyle(
                          color: Color(0xFF7A9BB5),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Campo e-mail
                _buildFieldLabel('E-MAIL'),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration(
                    hint: 'gerente@loja.com.br',
                    icon: IconsaxPlusLinear.sms,
                  ),
                ),
                const SizedBox(height: 20),

                // Campo senha
                _buildFieldLabel('SENHA'),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  onSubmitted: (_) => _login(),
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: IconsaxPlusLinear.lock,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? IconsaxPlusLinear.eye_slash : IconsaxPlusLinear.eye,
                        color: const Color(0xFF7A9BB5),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                // Mensagem de erro
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Botão entrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ACESSAR PORTAL DO GERENTE',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                  ),
                ),

                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    '© 2026 CheckFast • Gerência de Loja',
                    style: TextStyle(color: Color(0xFF4A6A85), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF7A9BB5),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0D1B2A),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF4A6A85), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF7A9BB5), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D4A6A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D4A6A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
    );
  }
}
