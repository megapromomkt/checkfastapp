import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/security_service.dart';
import '../../core/services/register_service.dart';
import '../../models/register_models.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyLoginView extends StatefulWidget {
  const AgencyLoginView({super.key});

  @override
  State<AgencyLoginView> createState() => _AgencyLoginViewState();
}

class _AgencyLoginViewState extends State<AgencyLoginView> {
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
        // Se falhar com a senha normal, tenta com o hash da senha (caso tenha sido criado com o hash no Auth)
        try {
          final hashed = SecurityService.hashPassword(password);
          credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: hashed,
          );
        } catch (authError2) {
          print("Auth falhou com senha normal e hash, tentando migração: $authError2");
        }
      }

      AppUser? user;
      
      if (credential != null) {
        // Logado com sucesso no Firebase Auth!
        // Busca os dados do usuário no Firestore pelo e-mail
        user = await _api.getUserByEmail(email);

        if (user == null) {
          // Se for o admin@checkfast.com que acabou de logar mas não tem documento no banco, cria o perfil dele
          if (email == 'admin@checkfast.com') {
            user = AppUser(
              id: 'admin',
              name: 'Admin Central',
              email: email,
              role: 'Master Access',
              status: 'Ativo',
              type: 'interno',
            );
            user.password = SecurityService.hashPassword(password);
            await _api.saveUser(user);
          } else {
            // Conta excluída no Firestore, mas ativa no Auth. Desloga.
            await FirebaseAuth.instance.signOut();
            setState(() => _error = 'Usuário não cadastrado ou removido.');
            return;
          }
        }

        // Garante que o authUid esteja atualizado no Firestore
        if (user.authUid != credential.user!.uid) {
          user.authUid = credential.user!.uid;
          await _api.saveUser(user);
        }
      } else {
        // Se falhou no Auth, tenta a Lazy Migration
        user = await _api.getUserByEmail(email);

        bool credentialsValid = false;
        
        if (user != null) {
          credentialsValid = SecurityService.verifyPassword(password, user.password);
        } else if (email == 'admin@checkfast.com' && password == 'admin123') {
          // Trata caso inicial do admin padrão
          credentialsValid = true;
          user = AppUser(
            id: 'admin',
            name: 'Admin Central',
            email: email,
            role: 'Master Access',
            status: 'Ativo',
            type: 'interno',
          );
        }

        if (credentialsValid && user != null) {
          // Cria o usuário no Firebase Auth
          final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          user.authUid = newCred.user!.uid;
          user.password = SecurityService.hashPassword(password);
          await _api.saveUser(user);
        } else {
          setState(() => _error = 'E-mail ou senha incorretos.');
          return;
        }
      }

      // Valida status do usuário
      if (user.status == 'Ativo') {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? user.authUid;
        if (uid.isNotEmpty) {
          await FirebaseFirestore.instance.collection('agency_users').doc(uid).set({
            'uid': uid,
            'cpf': user.id,
            'role': user.role.isEmpty ? 'Admin' : user.role,
            'email': user.email,
            'updatedAt': DateTime.now().toIso8601String(),
          }).catchError((err) {
            print("Erro ao atualizar agency_users: $err");
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_user_name', user.name);
        await prefs.setString('admin_user_role', user.role);
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin', arguments: user);
        }
      } else {
        setState(() => _error = 'Este usuário está inativo.');
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
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.06), 
                blurRadius: 40, 
                offset: const Offset(0, 12)
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1), 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(IconsaxPlusBold.flash, color: AppColors.primaryBlue, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Column(
                  children: [
                    Text('CheckFast Admin', style: TextStyle(
                      color: AppColors.textPrimary, 
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: -0.8
                    )),
                    SizedBox(height: 8),
                    Text('Controle total da sua operação', style: TextStyle(
                      color: AppColors.textSecondary, 
                      fontSize: 16,
                      fontWeight: FontWeight.w500
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              _buildFieldLabel('E-MAIL CORPORATIVO'),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                decoration: _inputDecoration(
                  hint: 'exemplo@megapromo.com.br',
                  icon: IconsaxPlusLinear.sms,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildFieldLabel('SENHA'),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                onSubmitted: (_) => _login(),
                decoration: _inputDecoration(
                  hint: '••••••••',
                  icon: IconsaxPlusLinear.lock,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? IconsaxPlusLinear.eye_slash : IconsaxPlusLinear.eye, color: AppColors.textSecondary, size: 22),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, 
                  child: const Text('Esqueceu a senha?', style: TextStyle(
                    color: AppColors.primaryBlue, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w700
                  ))
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ENTRAR NO SISTEMA', style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800, 
                        letterSpacing: 0.5
                      ))
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('© 2026 CheckFast • Gestão Inteligente', style: TextStyle(
                  color: AppColors.textSecondary, 
                  fontSize: 12,
                  fontWeight: FontWeight.w500
                )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: const TextStyle(
      color: AppColors.textSecondary, 
      fontSize: 11, 
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2
    ));
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.background,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 22),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
    );
  }
}
