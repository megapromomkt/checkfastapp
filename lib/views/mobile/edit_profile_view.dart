import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? 'Ricardo Souza';
      _cpfController.text = prefs.getString('user_cpf') ?? '123.456.789-00';
      _emailController.text = prefs.getString('user_email') ?? 'ricardo.souza@email.com';
      _phoneController.text = prefs.getString('user_phone') ?? '(11) 98765-4321';
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
            _buildField('CELULAR / WHATSAPP', _phoneController, IconsaxPlusLinear.call),
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
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_name', _nameController.text);
                  await prefs.setString('user_email', _emailController.text);
                  await prefs.setString('user_phone', _phoneController.text);
                  await prefs.setString('user_cep', _cepController.text);
                  await prefs.setString('user_city', _cityController.text);
                  await prefs.setString('user_bairro', _bairroController.text);
                  await prefs.setString('user_uf', _ufController.text);
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: AppColors.success));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.all(22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SALVAR ALTERAÇÕES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
