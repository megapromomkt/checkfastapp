import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'welcome_demands_modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/security_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthModals {
  static void showPromoterLogin(BuildContext context) {
    final cpfController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool obscurePassword = true;
        
        return StatefulBuilder(
          builder: (context, setState) {
            void submitForm() async {
              if (cpfController.text.isEmpty || passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, preencha CPF e Senha.'), backgroundColor: Colors.orange)
                );
                return;
              }
              
              final cleanCPF = cpfController.text.replaceAll(RegExp(r'\D'), '');
              if (cleanCPF.length != 11) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CPF inválido. Digite os 11 números.'), backgroundColor: Colors.redAccent)
                );
                return;
              }

              try {
                // Busca os dados do usuário usando o SDK do Firestore para evitar quota REST (429)
                final doc = await FirebaseFirestore.instance.collection('users').doc(cleanCPF).get();
                
                if (!doc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CPF não cadastrado.'), backgroundColor: Colors.redAccent)
                  );
                  return;
                }
                
                final data = doc.data() as Map<String, dynamic>;
                final storedPassword = data['password']?.toString() ?? '';
                final name = data['name']?.toString() ?? '';
                final city = data['address_city']?.toString() ?? '';
                final bairro = data['address_bairro']?.toString() ?? '';
                final email = data['email']?.toString() ?? '';
                final phone = data['phone']?.toString() ?? '';
                final cep = (data['cep'] != null && data['cep'].toString().isNotEmpty)
                    ? data['cep'].toString()
                    : (data['address_cep']?.toString() ?? '');
                final uf = data['address_uf']?.toString() ?? '';
                final rua = data['address_rua']?.toString() ?? '';
                
                // Verifica senha — suporta hash SHA-256 (cadastrado pelo admin) e texto simples (cadastro próprio)
                if (!SecurityService.verifyPassword(passwordController.text, storedPassword)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Senha incorreta.'), backgroundColor: Colors.redAccent)
                  );
                  return;
                }

                // Salva os dados na sessão local do navegador
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_cpf', cleanCPF);
                await prefs.setString('user_name', name);
                await prefs.setString('user_city', city);
                await prefs.setString('user_bairro', bairro);
                await prefs.setString('user_email', email);
                await prefs.setString('user_phone', phone);
                await prefs.setString('user_cep', cep);
                await prefs.setString('user_uf', uf);
                await prefs.setString('user_rua', rua);

                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/promoter');
              } catch (e) {
                final msg = e.toString();
                final isQuota = msg.contains('RESOURCE_EXHAUSTED') || msg.contains('quota') || msg.contains('429');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isQuota 
                      ? 'Serviço temporariamente indisponível. Tente novamente em alguns instantes.'
                      : 'Erro ao fazer login. Verifique CPF e senha.'
                    ),
                    backgroundColor: Colors.redAccent,
                  )
                );
              }
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final isMobileCtx = screenWidth < 600;
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.all(isMobileCtx ? 24 : 48),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobileCtx ? 16 : 40,
                vertical: 24,
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobileCtx ? double.infinity : 420,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(IconsaxPlusBold.user, color: AppColors.primaryBlue, size: 32),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Column(
                        children: [
                          Text('Acesso ao Prestador', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          SizedBox(height: 8),
                          Text('Bem-vindo de volta! Acesse sua conta.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildFieldLabel('CPF'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cpfController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: '000.000.000-00',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        prefixIcon: const Icon(IconsaxPlusLinear.personalcard, color: AppColors.textSecondary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildFieldLabel('SENHA'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitForm(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        prefixIcon: const Icon(IconsaxPlusLinear.lock, color: AppColors.textSecondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? IconsaxPlusLinear.eye : IconsaxPlusLinear.eye_slash, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text('ENTRAR NO SISTEMA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showForgotPassword(context);
                        }, 
                        child: const Text('Esqueceu sua senha?', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13))
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  static void showAdminLogin(BuildContext context) {
    final userController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool obscurePassword = true;
        
        return StatefulBuilder(
          builder: (context, setState) {
            void submitForm() {
              if (userController.text == 'admin' && passwordController.text == 'admin123') {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/admin');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Usuário ou senha incorretos.'), backgroundColor: Colors.redAccent)
                );
              }
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final isMobileCtx = screenWidth < 600;
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: EdgeInsets.all(isMobileCtx ? 24 : 48),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobileCtx ? 16 : 40,
                vertical: 24,
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobileCtx ? double.infinity : 420,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(IconsaxPlusBold.security_safe, color: Colors.orange, size: 32),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Center(
                      child: Column(
                        children: [
                          Text('Acesso Administrativo', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Text('Restrito para usuários autorizados.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildFieldLabel('USUÁRIO'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: userController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: 'Digite seu usuário',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        prefixIcon: const Icon(IconsaxPlusLinear.user, color: AppColors.textSecondary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildFieldLabel('SENHA'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitForm(),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        prefixIcon: const Icon(IconsaxPlusLinear.lock, color: AppColors.textSecondary, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? IconsaxPlusLinear.eye : IconsaxPlusLinear.eye_slash, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.all(22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text('ACESSAR PAINEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  static void showPromoterRegister(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _RegisterDialog(),
    );
  }

  static void showForgotPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isMobileCtx = MediaQuery.of(context).size.width < 600;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: EdgeInsets.all(isMobileCtx ? 24 : 48),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobileCtx ? 16 : 40,
            vertical: 24,
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobileCtx ? double.infinity : 420,
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recuperar Senha', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('Informe seu e-mail para receber as instruções.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 40),
              
              _buildFieldLabel('E-MAIL CADASTRADO'),
              const SizedBox(height: 8),
              _buildTextField(hint: 'exemplo@email.com', icon: IconsaxPlusLinear.sms),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link enviado! Verifique seu e-mail.'), backgroundColor: AppColors.primaryBlue)
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.all(22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('ENVIAR INSTRUÇÕES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Voltar para o login', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700))
                ),
              )
            ],
          ),
        ),
      );
    },
  );
  }

  static Widget _buildFieldLabel(String label) {
    return Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8));
  }

  static Widget _buildTextField({required String hint, required IconData icon, bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
      ),
    );
  }
}

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog();

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthController = TextEditingController();
  final _cpfController = TextEditingController();
  
  final _addressController = TextEditingController();
  final _cepController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cityController = TextEditingController();
  final _ufController = TextEditingController();
  
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  final _pixController = TextEditingController();
  final _bankController = TextEditingController();
  final _agencyController = TextEditingController();
  final _accountController = TextEditingController();
  final _digitController = TextEditingController();
  
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _cpfError;

  bool _isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;
    
    List<int> numbers = cpf.split('').map(int.parse).toList();
    
    // Valida primeiro dígito
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += numbers[i] * (10 - i);
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;
    if (numbers[9] != digit1) return false;
    
    // Valida segundo dígito
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += numbers[i] * (11 - i);
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;
    if (numbers[10] != digit2) return false;
    
    return true;
  }

  Future<void> _lookupCEP(String cep) async {
    cep = cep.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return;

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] != true) {
          setState(() {
            _addressController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cityController.text = data['localidade'] ?? '';
            _ufController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Erro ao buscar CEP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileCtx = screenWidth < 600;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobileCtx ? 8 : 40,
        vertical: isMobileCtx ? 8 : 24,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobileCtx ? double.infinity : 650,
          maxHeight: MediaQuery.of(context).size.height * (isMobileCtx ? 0.97 : 0.9),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cadastro de Profissional', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      SizedBox(height: 4),
                      Text('Preencha seus dados para começar a trabalhar.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  )
                ],
              ),
            ),
            
            // Formulário
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BLOCO 1: DADOS PESSOAIS
                      _buildSectionTitle('1. Dados Pessoais'),
                      const SizedBox(height: 16),
                      _buildLabel('NOME COMPLETO *'),
                      _buildInputField(controller: _nameController, hint: 'Ex: João Silva', icon: IconsaxPlusLinear.user),
                      const SizedBox(height: 16),
                      
                      Responsive.row(
                        context: context,
                        gap: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('TELEFONE *'),
                              _buildInputField(controller: _phoneController, hint: '(11) 99999-9999', icon: IconsaxPlusLinear.call, keyboardType: TextInputType.phone),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('DATA DE NASCIMENTO *'),
                              _buildInputField(controller: _birthController, hint: 'DD/MM/AAAA', icon: IconsaxPlusLinear.calendar_1, keyboardType: TextInputType.datetime),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLabel('CPF *'),
                      _buildInputField(
                        controller: _cpfController, 
                        hint: '000.000.000-00', 
                        icon: IconsaxPlusLinear.personalcard,
                        keyboardType: TextInputType.number,
                        errorText: _cpfError,
                        onChanged: (val) {
                          if (_cpfError != null) {
                            setState(() => _cpfError = null);
                          }
                        }
                      ),
                      const SizedBox(height: 32),

                      // BLOCO 2: ENDEREÇO
                      _buildSectionTitle('2. Endereço Completo'),
                      const SizedBox(height: 16),
                      
                      Responsive.row(
                        context: context,
                        gap: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CEP *'),
                              _buildInputField(
                                controller: _cepController, 
                                hint: '00000-000', 
                                icon: IconsaxPlusLinear.location, 
                                keyboardType: TextInputType.number,
                                onChanged: _lookupCEP,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('ENDEREÇO *'),
                              _buildInputField(controller: _addressController, hint: 'Rua, número, complemento', icon: IconsaxPlusLinear.map),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Responsive.row(
                        context: context,
                        gap: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('BAIRRO *'),
                              _buildInputField(controller: _bairroController, hint: 'Seu bairro', icon: IconsaxPlusLinear.map_1),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CIDADE *'),
                              _buildInputField(controller: _cityController, hint: 'Sua cidade', icon: IconsaxPlusLinear.building),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('UF *'),
                              _buildInputField(controller: _ufController, hint: 'SP', icon: IconsaxPlusLinear.global),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // BLOCO 3: EMERGÊNCIA
                      _buildSectionTitle('3. Contato de Emergência'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('NOME DO CONTATO *'),
                      _buildInputField(controller: _emergencyNameController, hint: 'Nome do familiar ou amigo', icon: IconsaxPlusLinear.user_tag),
                      const SizedBox(height: 16),
                      
                      _buildLabel('TELEFONE DE EMERGÊNCIA *'),
                      _buildInputField(controller: _emergencyPhoneController, hint: '(11) 99999-9999', icon: IconsaxPlusLinear.call, keyboardType: TextInputType.phone),
                      const SizedBox(height: 32),

                      // BLOCO 4: DADOS BANCÁRIOS
                      _buildSectionTitle('4. Dados Financeiros'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('CHAVE PIX *'),
                      _buildInputField(controller: _pixController, hint: 'CPF, E-mail, Celular ou Aleatória', icon: IconsaxPlusLinear.empty_wallet),
                      const SizedBox(height: 16),
                      
                      _buildLabel('BANCO *'),
                      _buildInputField(controller: _bankController, hint: 'Ex: Itaú, Bradesco, Nubank', icon: IconsaxPlusLinear.bank),
                      const SizedBox(height: 16),
                      
                      Responsive.row(
                        context: context,
                        gap: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('AGÊNCIA *'),
                              _buildInputField(controller: _agencyController, hint: '0000', icon: IconsaxPlusLinear.element_3, keyboardType: TextInputType.number),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('CONTA *'),
                              _buildInputField(controller: _accountController, hint: '00000000', icon: IconsaxPlusLinear.card, keyboardType: TextInputType.number),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('DÍGITO *'),
                              _buildInputField(controller: _digitController, hint: '0', icon: IconsaxPlusLinear.verify, keyboardType: TextInputType.number),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // BLOCO 5: SENHA
                      _buildSectionTitle('5. Senha de Acesso'),
                      const SizedBox(height: 16),
                      
                      _buildLabel('SENHA (MÍNIMO 6 DÍGITOS) *'),
                      _buildInputField(controller: _passwordController, hint: '••••••••', icon: IconsaxPlusLinear.lock, obscureText: true),
                      const SizedBox(height: 16),
                      
                      _buildLabel('CONFIRMAÇÃO DE SENHA *'),
                      _buildInputField(controller: _confirmPasswordController, hint: '••••••••', icon: IconsaxPlusLinear.lock, obscureText: true),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botões
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        foregroundColor: AppColors.textPrimary
                      ),
                      child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                        onPressed: () async {
                          // Validação de campos vazios básica
                          if (_nameController.text.isEmpty || 
                              _cpfController.text.isEmpty || 
                              _phoneController.text.isEmpty ||
                              _passwordController.text.isEmpty ||
                              _confirmPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.orange)
                            );
                            return;
                          }

                          // Validação de tamanho da senha
                          if (_passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('A senha deve ter no mínimo 6 dígitos.'), backgroundColor: Colors.redAccent)
                            );
                            return;
                          }

                          // Validação de confirmação de senha
                          if (_passwordController.text != _confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('As senhas não coincidem.'), backgroundColor: Colors.redAccent)
                            );
                            return;
                          }

                          // Validação de CPF
                          if (!_isValidCPF(_cpfController.text)) {
                            setState(() {
                              _cpfError = 'CPF inválido. Verifique os números.';
                            });
                            return;
                          }

                          // Salva no Firestore de forma achatada (Flatten) para evitar erro de tipo no JS
                          final cleanCPF = _cpfController.text.replaceAll(RegExp(r'\D'), '');
                          
                          try {
                            // Prepara os dados achatados
                            final flatData = <String, String>{
                              'id': cleanCPF,
                              'role': 'worker',
                              'name': _nameController.text,
                              'phone': _phoneController.text,
                              'birthDate': _birthController.text,
                              'cpf': cleanCPF,
                              'address_rua': _addressController.text,
                              'address_cep': _cepController.text,
                              'address_bairro': _bairroController.text,
                              'address_city': _cityController.text,
                              'address_uf': _ufController.text,
                              'emergency_name': _emergencyNameController.text,
                              'emergency_phone': _emergencyPhoneController.text,
                              'pixKey': _pixController.text,
                              'bank_name': _bankController.text,
                              'bank_agency': _agencyController.text,
                              'bank_account': _accountController.text,
                              'bank_digit': _digitController.text,
                              'password': _passwordController.text,
                              'status': 'Aprovado',
                              'createdAt': DateTime.now().toIso8601String(),
                            };

                            // Salva usando o SDK do Firestore
                            await FirebaseFirestore.instance.collection('users').doc(cleanCPF).set(flatData);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao cadastrar: $e'), backgroundColor: Colors.redAccent)
                            );
                            return;
                          }

                          Navigator.pop(context);
                          // Mostra mensagem de sucesso
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cadastro realizado com sucesso! Faça login para continuar.'), backgroundColor: Colors.green)
                          );
                          
                          // Abre o modal de login
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (context.mounted) {
                              AuthModals.showPromoterLogin(context);
                            }
                          });
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      child: const Text('FINALIZAR CADASTRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5))
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    TextInputType? keyboardType,
    String? errorText,
    Function(String)? onChanged,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}
