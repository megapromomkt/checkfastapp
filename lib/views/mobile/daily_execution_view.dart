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
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18)
        ),
        title: const Text('Execução de Diária', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 30),

            // Briefing e Regras
            const Text('REGRAS E BRIEFING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 20),
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
              const Text('ATACADÃO LAPA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.successEmerald.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.storefront, color: AppColors.successEmerald, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Rua Gago Coutinho, 350 - Lapa, São Paulo - SP', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _checkedIn ? AppColors.neonCyan.withOpacity(0.3) : AppColors.glassBorderDark),
        boxShadow: [
          if (_checkedIn) BoxShadow(color: AppColors.neonCyan.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)
        ]
      ),
      child: Column(
        children: [
          Text(
            _checkedIn ? 'DIÁRIA EM ANDAMENTO' : 'DISPONÍVEL PARA CHECK-IN', 
            style: TextStyle(color: _checkedIn ? AppColors.neonCyan : AppColors.textSecondary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)
          ),
          const SizedBox(height: 25),
          if (_checkedIn) ...[
            const Text('02:45:12', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const Text('TEMPO DE JORNADA ATUAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ] else ...[
            const Icon(Icons.location_on, color: AppColors.neonCyan, size: 60),
            const SizedBox(height: 15),
            Text(
              _isNearStore ? 'VOCÊ ESTÁ NO LOCAL' : 'FORA DO RAIO DA LOJA', 
              style: TextStyle(color: _isNearStore ? AppColors.successEmerald : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)
            ),
          ],
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isNearStore ? () => _handleSecurityAndCheckin() : null, 
              icon: Icon(_checkedIn ? Icons.logout : Icons.login, color: Colors.black, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: _checkedIn ? Colors.redAccent : AppColors.neonCyan,
                padding: const EdgeInsets.all(22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.white.withOpacity(0.05)
              ),
              label: Text(
                _checkedIn ? 'REALIZAR CHECK-OUT' : 'CONFIRMAR CHECK-IN', 
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)
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
          backgroundColor: AppColors.cardDark,
          title: const Row(
            children: [
              Icon(Icons.gpp_bad, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Acesso Bloqueado', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold))
            ]
          ),
          content: Text(violations.first, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c), 
              child: const Text('Entendi', style: TextStyle(color: AppColors.textSecondary))
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
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 18),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFinancePreview() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.neonCyan.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.1))
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VALOR TOTAL DA DIÁRIA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 8),
              Text('R\$ 150,00', style: TextStyle(color: AppColors.successEmerald, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          Icon(Icons.account_balance_wallet_outlined, color: AppColors.neonCyan, size: 35),
        ],
      ),
    );
  }
}
