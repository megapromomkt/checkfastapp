import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController(text: 'Ricardo Souza');
  final _cpfController = TextEditingController(text: '123.456.789-00');
  final _emailController = TextEditingController(text: 'ricardo.souza@email.com');
  final _phoneController = TextEditingController(text: '(11) 98765-4321');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _buildField('NOME COMPLETO', _nameController, IconsaxPlusLinear.profile),
            const SizedBox(height: 20),
            _buildField('CPF (NÃO EDITÁVEL)', _cpfController, IconsaxPlusLinear.personalcard, enabled: false),
            const SizedBox(height: 20),
            _buildField('E-MAIL', _emailController, IconsaxPlusLinear.sms),
            const SizedBox(height: 20),
            _buildField('CELULAR / WHATSAPP', _phoneController, IconsaxPlusLinear.call),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados com sucesso!')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SALVAR ALTERAÇÕES', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorderDark),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(color: enabled ? Colors.white : AppColors.textSecondary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.neonCyan, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
        ),
      ],
    );
  }
}
