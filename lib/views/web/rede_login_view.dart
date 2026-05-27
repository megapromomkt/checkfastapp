import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/security_service.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';

class RedeLoginView extends StatefulWidget {
  const RedeLoginView({super.key});

  @override
  State<RedeLoginView> createState() => _RedeLoginViewState();
}

class _RedeLoginViewState extends State<RedeLoginView> {
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
        // Busca os dados do usuário no Firestore pelo e-mail
        user = await _api.getUserByEmail(email);

        if (user == null) {
          // Conta excluída no Firestore, mas ativa no Auth. Desloga.
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
            (user.type == 'rede' || user.type == 'gerente')) {
          // Cria o usuário no Firebase Auth
          final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          user.authUid = newCred.user!.uid;
          user.password = SecurityService.hashPassword(password);
          await _api.saveUser(user);
        } else {
          setState(() => _error = 'E-mail ou senha incorretos, ou sem perfil de acesso à Rede.');
          return;
        }
      }

      // Valida status e tipo de acesso
      if (user.status == 'Ativo' && (user.type == 'rede' || user.type == 'gerente')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rede_user_id', user.id);
        await prefs.setString('rede_user_name', user.name);
        await prefs.setString('rede_user_role', user.role);
        await prefs.setString('rede_store_id', user.storeId);
        await prefs.setString('rede_regional', user.regional);
        await prefs.setStringList('rede_store_ids', user.storeIds);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/rede_dashboard', arguments: user);
        }
      } else {
        setState(() => _error = 'Usuário inativo ou sem acesso. Contate o administrador.');
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
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Cabeçalho premium
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(IconsaxPlusLinear.global, color: AppColors.primaryBlue, size: 14),
                      SizedBox(width: 8),
                      Text('AMBIENTE REDE', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Card de login
                Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111F35),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF1E3A5F), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 60,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ícone e título
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [AppColors.primaryBlue.withOpacity(0.3), Colors.transparent],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0055CC), Color(0xFF0099FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(IconsaxPlusLinear.global, color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Ambiente Rede',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Acesso para Líder de Frente de Caixa e Regional',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF6B8CAD),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Perfis disponíveis
                      Row(
                        children: [
                          Expanded(child: _buildProfileChip(IconsaxPlusLinear.profile_2user, 'Líder de Frente de Caixa')),
                          const SizedBox(width: 12),
                          Expanded(child: _buildProfileChip(IconsaxPlusLinear.map, 'Regional')),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // E-mail
                      _buildFieldLabel('E-MAIL'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(hint: 'seu@email.com.br', icon: IconsaxPlusLinear.sms),
                      ),
                      const SizedBox(height: 20),

                      // Senha
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
                              color: const Color(0xFF6B8CAD),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),

                      // Erro
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Botão
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
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('ENTRAR NO AMBIENTE REDE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  '© 2026 CheckFast • Ambiente Rede',
                  style: TextStyle(color: Color(0xFF3A5A7A), fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 14),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: const TextStyle(color: Color(0xFF6B8CAD), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2));
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF0A1628),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF3A5A7A), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF6B8CAD), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3A5F))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
    );
  }
}
