import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';

class StoreDetailView extends StatelessWidget {
  final String storeName;
  final String network;
  
  const StoreDetailView({
    super.key, 
    required this.storeName,
    required this.network,
  });

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
        )
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumHeader(title: storeName, subtitle: network),
            const SizedBox(height: 30),

            // 1. INFORMAÇÕES DA LOJA
            _buildSectionTitle('INFORMAÇÕES DA LOJA'),
            PremiumCard(
              child: Column(
                children: [
                  _buildDetailRow(Icons.location_on_outlined, 'Endereço Completo', 'Rua Gago Coutinho, 350 - Lapa, São Paulo - SP'),
                  _buildDetailRow(Icons.map_outlined, 'Ponto de Referência', 'Próximo à Estação Lapa da CPTM'),
                  _buildDetailRow(Icons.person_outline, 'Responsável / Gerente', 'Sr. Marcos Oliveira'),
                  _buildDetailRow(Icons.phone_outlined, 'Telefone de Contato', '(11) 3641-0000'),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. O QUE PRECISA SER FEITO (DEMANDA)
            _buildSectionTitle('DESCRIÇÃO DA DEMANDA'),
            PremiumCard(
              child: Column(
                children: [
                  _buildDetailRow(Icons.work_outline, 'Função', 'Promotor de Vendas Especialista'),
                  _buildDetailRow(Icons.list_alt_outlined, 'Atividade Obrigatória', 'Reposição, limpeza de gôndola e aplicação de materiais de merchandising.'),
                  _buildDetailRow(Icons.ads_click, 'Passo a Passo', '1. Check-in\n2. Foto da gôndola antes\n3. Reposição\n4. Foto da gôndola depois\n5. Checkout'),
                  _buildDetailRow(Icons.access_time, 'Horário', 'Entrada: 08:00 | Saída: 14:00'),
                  _buildDetailRow(Icons.timer_outlined, 'Tempo Mínimo', '04 Horas para validação de pagamento'),
                  _buildDetailRow(Icons.payments_outlined, 'Valor da Diária', 'R\$ 150,00', valueColor: AppColors.successEmerald),
                  _buildDetailRow(Icons.checkroom, 'Vestimenta', 'Calça jeans escura, tênis preto e camiseta branca lisa.'),
                  _buildDetailRow(Icons.badge_outlined, 'Documentos', 'RG e CPF original com foto.'),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 3. REGRAS DE COMPROVAÇÃO
            _buildSectionTitle('REGRAS DE COMPROVAÇÃO'),
            PremiumCard(
              borderColor: AppColors.alertOrange.withOpacity(0.3),
              child: Column(
                children: [
                  _buildDetailRow(Icons.gps_fixed, 'Localização', 'Check-in e Checkout obrigatórios via GPS'),
                  _buildDetailRow(Icons.camera_alt_outlined, 'Fotos de Auditoria', 'Foto obrigatória no início e final da jornada'),
                  _buildDetailRow(Icons.radar, 'Raio de Validação', 'Até 200 metros da coordenada da loja'),
                ],
              ),
            ),

            const SizedBox(height: 40),
            
            // Botão Principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                child: const Text('ACEITAR LOJA E TAREFA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16))
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.neonCyan, size: 18),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
