import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _cityController = TextEditingController();
  final _bairroController = TextEditingController();
  final _ufController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _cpfController.text = prefs.getString('user_cpf') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _phoneController.text = prefs.getString('user_phone') ?? '';
      _cepController.text = prefs.getString('user_cep') ?? '';
      _cityController.text = prefs.getString('user_city') ?? '';
      _bairroController.text = prefs.getString('user_bairro') ?? '';
      _ufController.text = prefs.getString('user_uf') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Editar Perfil', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildField('NOME COMPLETO', _nameController, IconsaxPlusLinear.profile),
            const SizedBox(height: 24),
            _buildField('CPF (NÃO EDITÁVEL)', _cpfController, IconsaxPlusLinear.personalcard, enabled: false),
            const SizedBox(height: 24),
            _buildField('E-MAIL', _emailController, IconsaxPlusLinear.sms),
            const SizedBox(height: 24),
            _buildField('CELULAR / WHATSAPP *', _phoneController, IconsaxPlusLinear.call),
            const SizedBox(height: 24),
            _buildField('CEP', _cepController, IconsaxPlusLinear.location),
            const SizedBox(height: 24),
            _buildField('CIDADE', _cityController, IconsaxPlusLinear.building),
            const SizedBox(height: 24),
            _buildField('BAIRRO', _bairroController, IconsaxPlusLinear.map),
            const SizedBox(height: 24),
            _buildField('ESTADO (UF)', _ufController, IconsaxPlusLinear.map_1),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () async {
                  final cleanCPF = _cpfController.text.replaceAll(RegExp(r'\D'), '');
                  
                  if (cleanCPF.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CPF inválido.'), backgroundColor: Colors.redAccent));
                    }
                    return;
                  }

                  if (_phoneController.text.trim().isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O celular / WhatsApp é obrigatório.'), backgroundColor: Colors.redAccent));
                    }
                    return;
                  }

                  setState(() => _isSaving = true);

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    // Salva localmente
                    await prefs.setString('user_name', _nameController.text);
                    await prefs.setString('user_email', _emailController.text);
                    await prefs.setString('user_phone', _phoneController.text);
                    await prefs.setString('user_cep', _cepController.text);
                    await prefs.setString('user_city', _cityController.text);
                    await prefs.setString('user_bairro', _bairroController.text);
                    await prefs.setString('user_uf', _ufController.text);
                    
                    // Salva no Firestore via SDK (evita cota de API REST e token manual)
                    await FirebaseFirestore.instance.collection('users').doc(cleanCPF).update({
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'address_city': _cityController.text,
                      'address_bairro': _bairroController.text,
                      'address_cep': _cepController.text,
                      'address_uf': _ufController.text,
                    });
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: AppColors.success));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.redAccent));
                    }
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.all(22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(color: enabled ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
        ),
      ],
    );
  }
}
