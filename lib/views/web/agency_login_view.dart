import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';

class AgencyLoginView extends StatelessWidget {
  const AgencyLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorderDark),
            boxShadow: [
              BoxShadow(color: AppColors.neonCyan.withOpacity(0.05), blurRadius: 30, spreadRadius: 5)
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.electricBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(IconsaxPlusBold.setting_2, color: AppColors.electricBlue, size: 28),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acesso Gerencial', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        Text('Mega Promo', style: TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),
              const Text('Área restrita para gestão de clientes, projetos, lojas, presença e financeiro.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
              const SizedBox(height: 40),
              
              const Text('E-mail corporativo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.spaceBlack,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  hintText: 'exemplo@megapromo.com.br',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(IconsaxPlusLinear.sms, color: AppColors.textSecondary)
                ),
              ),
              const SizedBox(height: 20),
              
              const Text('Senha', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.spaceBlack,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(IconsaxPlusLinear.lock, color: AppColors.textSecondary)
                ),
              ),
              const SizedBox(height: 15),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {}, 
                  child: const Text('Esqueci minha senha', style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold))
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text('ENTRAR NO PAINEL GERENCIAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1))
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
