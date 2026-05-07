import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import '../shared/auth_modals.dart';

class LandingPageView extends StatelessWidget {
  const LandingPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            _buildHero(context),
            _buildHowItWorks(),
            _buildBenefits(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.spaceBlack.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: AppColors.glassBorderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(IconsaxPlusBold.verify, color: AppColors.neonCyan, size: 32),
              SizedBox(width: 10),
              Text('CheckFast', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('Como funciona', style: TextStyle(color: AppColors.textSecondary))),
              const SizedBox(width: 20),
              TextButton(onPressed: () {}, child: const Text('Benefícios', style: TextStyle(color: AppColors.textSecondary))),
              const SizedBox(width: 20),
              TextButton(onPressed: () => AuthModals.showPromoterLogin(context), child: const Text('Entrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => AuthModals.showPromoterRegister(context), 
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Criar cadastro', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.spaceBlack, AppColors.electricBlue.withOpacity(0.1), AppColors.successEmerald.withOpacity(0.05)]
        )
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trabalhe por diária com\npresença comprovada e\npagamento seguro.', style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -2)),
                const SizedBox(height: 30),
                const Text(
                  'O CheckFast conecta você a oportunidades próximas, permite aceitar tarefas em loja, registrar presença e acompanhar seus recebimentos em um só lugar.', 
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 18, height: 1.5)
                ),
                const SizedBox(height: 50),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => AuthModals.showPromoterRegister(context), 
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Quero me cadastrar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16))
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () => AuthModals.showPromoterLogin(context), 
                      style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.neonCyan.withOpacity(0.5)), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Já tenho cadastro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 50),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 300,
                    height: 600,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppColors.glassBorderDark, width: 8),
                      boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.2), blurRadius: 100)]
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Icon(IconsaxPlusBold.verify, color: AppColors.successEmerald, size: 80),
                        const SizedBox(height: 20),
                        const Text('Check-in Validado', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text('Atacadão Lapa', style: TextStyle(color: AppColors.textSecondary)),
                        const Spacer(),
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.successEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Diária Aprovada', style: TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.bold)),
                              Text('R\$ 150,00', style: TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.w900, fontSize: 18))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    left: -50,
                    top: 100,
                    child: _buildFloatingGlassCard(IconsaxPlusLinear.location, '12 Lojas Próximas', AppColors.neonCyan),
                  ),
                  Positioned(
                    right: -50,
                    bottom: 150,
                    child: _buildFloatingGlassCard(IconsaxPlusLinear.card_receive, 'Pagamento Seguro', AppColors.successEmerald),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingGlassCard(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)]
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
      color: AppColors.spaceBlack,
      child: Column(
        children: [
          const Text('COMO FUNCIONA', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 10),
          const Text('Sua jornada em 5 passos', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 60),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStepCard('1', 'Cadastre-se', 'Crie seu perfil com seus dados, experiências e disponibilidade.')),
              const SizedBox(width: 20),
              Expanded(child: _buildStepCard('2', 'Encontre lojas', 'Veja oportunidades disponíveis conforme sua localização.')),
              const SizedBox(width: 20),
              Expanded(child: _buildStepCard('3', 'Aceite a tarefa', 'Confira detalhes, horário, valor e regras antes de aceitar.')),
              const SizedBox(width: 20),
              Expanded(child: _buildStepCard('4', 'Check-in e Checkout', 'Registre presença com foto, horário e localização gps.')),
              const SizedBox(width: 20),
              Expanded(child: _buildStepCard('5', 'Recebimentos', 'Acompanhe pagamentos pendentes, aprovados e pagos.')),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(color: AppColors.neonCyan, fontSize: 48, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
      color: AppColors.cardDark,
      child: Column(
        children: [
          const Text('BENEFÍCIOS', style: TextStyle(color: AppColors.successEmerald, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 10),
          const Text('Por que usar o CheckFast?', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 60),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 30,
            crossAxisSpacing: 30,
            childAspectRatio: 2.5,
            children: [
              _buildBenefitItem(IconsaxPlusLinear.location, 'Oportunidades próximas'),
              _buildBenefitItem(IconsaxPlusLinear.security_safe, 'Comprovação segura'),
              _buildBenefitItem(IconsaxPlusLinear.wallet_check, 'Pagamentos organizados'),
              _buildBenefitItem(IconsaxPlusLinear.clock, 'Histórico de tarefas'),
              _buildBenefitItem(IconsaxPlusLinear.eye, 'Transparência no status'),
              _buildBenefitItem(IconsaxPlusLinear.setting_4, 'Controle pelo próprio sistema'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.spaceBlack, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.glassBorderDark)),
          child: Icon(icon, color: AppColors.neonCyan, size: 30),
        ),
        const SizedBox(width: 20),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(50),
      color: AppColors.spaceBlack,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('© 2026 CheckFast Plataforma Tecnológica.', style: TextStyle(color: AppColors.textSecondary)),
          Text('Termos de Uso • Política de Privacidade', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
