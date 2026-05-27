import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';

class PixKeyView extends StatefulWidget {
  const PixKeyView({super.key});

  @override
  State<PixKeyView> createState() => _PixKeyViewState();
}

class _PixKeyViewState extends State<PixKeyView> {
  String _selectedType = 'CPF';
  final _keyController = TextEditingController(text: '123.456.789-00');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configurar Chave PIX', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seus pagamentos serão enviados para esta chave com segurança.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 40),
            
            const Text('TIPO DE CHAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: Colors.white,
                  isExpanded: true,
                  icon: const Icon(IconsaxPlusLinear.arrow_down_1, color: AppColors.primaryBlue),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  onChanged: (val) => setState(() => _selectedType = val!),
                  items: ['CPF', 'E-mail', 'Celular', 'Chave Aleatória'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('VALOR DA CHAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _keyController,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  prefixIcon: Icon(IconsaxPlusLinear.card_receive, color: AppColors.primaryBlue, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(18),
                  hintText: 'Digite sua chave pix...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave PIX atualizada com sucesso!'), backgroundColor: AppColors.success));
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
}
