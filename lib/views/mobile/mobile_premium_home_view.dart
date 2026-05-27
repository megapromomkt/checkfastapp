import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/services/ranking_routing_service.dart';

class MobilePremiumHomeView extends StatelessWidget {
  const MobilePremiumHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.cardDark,
        selectedItemColor: AppColors.neonCyan,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Vagas'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Minhas Idas'),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Financeiro'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Premium
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CheckFast', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      Text('SISTEMA DE AUDITORIA', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.glassBorderDark)),
                    child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text('Bom dia, João!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Você tem uma demanda hoje às 08h.', style: TextStyle(color: AppColors.textSecondary)),
              
              const SizedBox(height: 25),
              
              // Widget de Ranking e Gamificação
              const WorkerRankingWidget(rating: 4.9, points: 1250),
              
              const SizedBox(height: 30),
              const Text('SUA PRÓXIMA MISSÃO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 15),
              
              // Card de Missão com Estética de Tecnologia
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.electricBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.storefront, color: AppColors.electricBlue),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Atacadão Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Vaga: Promotor de Vendas', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Text('R\$ 150', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('ROTA'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.glassBorderDark, padding: const EdgeInsets.symmetric(horizontal: 20)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('CHECK-IN'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue, padding: const EdgeInsets.symmetric(horizontal: 25)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
