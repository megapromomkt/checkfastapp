import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/premium_theme.dart';
import '../../core/services/security_service.dart';

class DailyExecutionView extends StatefulWidget {
  const DailyExecutionView({super.key});

  @override
  State<DailyExecutionView> createState() => _DailyExecutionViewState();
}

class _DailyExecutionViewState extends State<DailyExecutionView> {
  bool _checkedIn = false;
  bool _isNearStore = true; // Simulação de Geofencing (GPS < 200m)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18)
        ),
        title: const Text('Execução de Diária', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Loja
            _buildStoreHeader(),
            const SizedBox(height: 30),

            // Card de Ação (Coração da Operação)
            _buildActionCard(),
            const SizedBox(height: 40),

            // Briefing e Regras
            const Text('REGRAS E BRIEFING', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _buildRuleItem(Icons.timer_outlined, 'Jornada mínima obrigatória: 04 horas.'),
            _buildRuleItem(Icons.camera_alt_outlined, 'Foto de check-in e out com biometria facial.'),
            _buildRuleItem(Icons.location_on_outlined, 'Check-in permitido apenas a menos de 200m.'),
            _buildRuleItem(Icons.assignment_outlined, 'Reposição de estoque e relatório fotográfico.'),

            const SizedBox(height: 40),

            // Preview Financeiro
            _buildFinancePreview(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ATACADÃO LAPA', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.storefront, color: AppColors.primaryBlue, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Rua Gago Coutinho, 350 - Lapa, São Paulo - SP', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _checkedIn ? AppColors.primaryBlue : AppColors.cardBorder, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))
        ]
      ),
      child: Column(
        children: [
          Text(
            _checkedIn ? 'DIÁRIA EM ANDAMENTO' : 'DISPONÍVEL PARA CHECK-IN', 
            style: TextStyle(color: _checkedIn ? AppColors.primaryBlue : AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)
          ),
          const SizedBox(height: 32),
          if (_checkedIn) ...[
            const Text('02:45:12', style: TextStyle(color: AppColors.textPrimary, fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const Text('TEMPO DE JORNADA ATUAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ] else ...[
            const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 64),
            const SizedBox(height: 16),
            Text(
              _isNearStore ? 'VOCÊ ESTÁ NO LOCAL' : 'FORA DO RAIO DA LOJA', 
              style: TextStyle(color: _isNearStore ? AppColors.success : AppColors.error, fontWeight: FontWeight.w800, fontSize: 14)
            ),
          ],
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isNearStore ? () => _handleSecurityAndCheckin() : null, 
              icon: Icon(_checkedIn ? Icons.logout : Icons.login, color: Colors.white, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: _checkedIn ? AppColors.error : AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                disabledBackgroundColor: AppColors.background
              ),
              label: Text(
                _checkedIn ? 'REALIZAR CHECK-OUT' : 'CONFIRMAR CHECK-IN', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5)
              )
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSecurityAndCheckin() async {
    if (_checkedIn) {
      // Faz o checkout sem bloquear
      setState(() => _checkedIn = false);
      return;
    }

    // Varredura de Segurança antes de liberar o Check-in
    final violations = await SecurityService.checkDeviceSecurity();
    
    if (violations.isNotEmpty) {
      // Bloqueia e mostra o motivo
      if(!mounted) return;
      showDialog(
        context: context, 
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Row(
            children: [
              Icon(Icons.gpp_bad, color: AppColors.error),
              SizedBox(width: 12),
              Text('Acesso Bloqueado', style: TextStyle(color: AppColors.error, fontSize: 20, fontWeight: FontWeight.w900))
            ]
          ),
          content: Text(violations.first, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c), 
              child: const Text('Entendi', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w800))
            )
          ],
        )
      );
      return;
    }

    // Tudo seguro, usando "Server Time" (Simulação) ao invés do relógio local
    HapticFeedback.heavyImpact();
    setState(() => _checkedIn = true);
  }

  Widget _buildRuleItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildFinancePreview() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VALOR TOTAL DA DIÁRIA', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              SizedBox(height: 8),
              Text('R\$ 150,00', style: TextStyle(color: AppColors.success, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryBlue.withOpacity(0.3), size: 40),
        ],
      ),
    );
  }
}
