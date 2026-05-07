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
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Chave PIX', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seus pagamentos serão enviados para esta chave.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 30),
            
            const Text('TIPO DE CHAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorderDark),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  dropdownColor: AppColors.cardDark,
                  isExpanded: true,
                  icon: const Icon(IconsaxPlusLinear.arrow_down_1, color: AppColors.neonCyan),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (val) => setState(() => _selectedType = val!),
                  items: ['CPF', 'E-mail', 'Celular', 'Chave Aleatória'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            const Text('VALOR DA CHAVE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorderDark),
              ),
              child: TextField(
                controller: _keyController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(IconsaxPlusLinear.card_receive, color: AppColors.neonCyan, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(18),
                  hintText: 'Digite sua chave pix...',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave PIX atualizada!')));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successEmerald,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('CADASTRAR CHAVE PIX', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
