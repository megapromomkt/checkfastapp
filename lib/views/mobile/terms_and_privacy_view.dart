import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class TermsAndPrivacyView extends StatelessWidget {
  const TermsAndPrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceBlack,
      appBar: AppBar(
        title: const Text('Termos e Privacidade', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.cardDark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Uso de Dados de Localização (GPS)'),
            _buildText('O CheckFast coleta dados de localização para validar sua presença na loja vinculada à demanda aceita. Esses dados são coletados apenas durante os processos de Check-in e Check-out.'),
            
            const SizedBox(height: 25),
            _buildSectionTitle('2. Reconhecimento Facial'),
            _buildText('Para evitar fraudes e garantir que você é o executor da tarefa, utilizamos tecnologia de biometria facial. A imagem capturada no check-in é processada localmente e armazenada de forma segura para auditoria da agência.'),
            
            const SizedBox(height: 25),
            _buildSectionTitle('3. Pagamentos e Regras'),
            _buildText('O pagamento da diária está condicionado ao cumprimento mínimo de 4 horas de jornada e à validação de GPS/Facial. O descumprimento dessas regras pode resultar na reprovação automática da diária.'),
            
            const SizedBox(height: 25),
            _buildSectionTitle('4. Compartilhamento com Clientes'),
            _buildText('Suas evidências de trabalho (fotos e horários) serão compartilhadas com o cliente contratante (ex: Atacadão) para fins de comprovação de serviço prestado.'),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Última atualização: Abril de 2026',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.neonCyan, fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      ),
    );
  }
}
