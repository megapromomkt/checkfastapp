import 'package:flutter/material.dart';
import '../../core/constants/premium_theme.dart';
import '../../models/app_models.dart';

class StoreDetailView extends StatelessWidget {
  final AppDemand? demand;
  
  const StoreDetailView({
    super.key, 
    this.demand,
  });

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
        )
      ), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PremiumHeader(
              title: demand?.storeName ?? 'Detalhes da Loja', 
              subtitle: demand?.network ?? 'Rede não informada'
            ),
            const SizedBox(height: 35),

            // 1. INFORMAÇÕES DA LOJA
            _buildSectionTitle('INFORMAÇÕES DA LOJA'),
            PremiumCard(
              child: Column(
                children: [
                  _buildDetailRow(Icons.location_on_outlined, 'Endereço Completo', demand?.address ?? 'Endereço não informado'),
                  _buildDetailRow(Icons.map_outlined, 'Ponto de Referência', 'Verificar no mapa'),
                  _buildDetailRow(Icons.person_outline, 'Responsável / Gerente', 'Solicitar na chegada'),
                  _buildDetailRow(Icons.phone_outlined, 'Telefone de Contato', 'Não disponível'),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. O QUE PRECISA SER FEITO (DEMANDA)
            _buildSectionTitle('DESCRIÇÃO DA DEMANDA'),
            PremiumCard(
              child: Column(
                children: [
                  _buildDetailRow(Icons.work_outline, 'Função', demand?.role ?? 'Promotor'),
                  if (demand != null)
                    _buildDetailRow(
                      Icons.calendar_today_outlined, 
                      demand!.date.contains(' - ') ? 'Período da Ação' : 'Data', 
                      demand!.date
                    ),
                  _buildDetailRow(Icons.list_alt_outlined, 'Atividade Obrigatória', demand?.requiredActivity ?? 'Reposição e limpeza.'),
                  _buildDetailRow(Icons.ads_click, 'Passo a Passo', demand?.stepByStep ?? '1. Check-in\n2. Execução\n3. Check-out'),
                  _buildDetailRow(Icons.access_time, 'Horário', demand?.timeRange ?? '08:00 - 14:00'),
                  _buildDetailRow(Icons.timer_outlined, 'Tempo Mínimo', demand?.minTime ?? '04 Horas'),
                  _buildDetailRow(Icons.payments_outlined, 'Valor da Diária', 'R\$ ${demand?.value.toStringAsFixed(2) ?? '150,00'}', valueColor: AppColors.success),
                  _buildDetailRow(Icons.checkroom, 'Vestimenta', demand?.dressCode ?? 'Camiseta branca e calça jeans.'),
                  _buildDetailRow(Icons.badge_outlined, 'Documentos', demand?.requiredDocuments ?? 'RG e CPF.'),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 3. REGRAS DE COMPROVAÇÃO
            _buildSectionTitle('REGRAS DE COMPROVAÇÃO'),
            PremiumCard(
              borderColor: AppColors.warning.withOpacity(0.3),
              child: Column(
                children: [
                  _buildDetailRow(Icons.gps_fixed, 'Localização', demand?.requiresLocation == true ? 'Check-in e Checkout obrigatórios via GPS' : 'Localização não exigida'),
                  _buildDetailRow(Icons.camera_alt_outlined, 'Fotos de Auditoria', demand?.requiresPhoto == true ? 'Foto obrigatória no início e final' : 'Fotos não exigidas'),
                  _buildDetailRow(Icons.radar, 'Raio de Validação', 'Até ${demand?.allowedRadius ?? 100} metros da coordenada da loja'),
                ],
              ),
            ),

            const SizedBox(height: 40),
            
            // Aviso de Período
            if (demand != null && demand!.date.contains(' - ')) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATENÇÃO AO PERÍODO',
                            style: TextStyle(
                              color: AppColors.warning, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 12,
                              letterSpacing: 0.5
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ao aceitar esta demanda, você estará escalado para todos os ${_calculateDays(demand!.date)} dias de ação deste período (${demand!.date}). Certifique-se de que possui disponibilidade para todos os dias.',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Botão Principal
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.all(22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                child: const Text('ACEITAR LOJA E TAREFA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5))
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  int _calculateDays(String dateStr) {
    if (!dateStr.contains(' - ')) return 1;
    final parts = dateStr.split(' - ');
    if (parts.length != 2) return 1;
    try {
      final startParts = parts[0].trim().split('/');
      final endParts = parts[1].trim().split('/');
      if (startParts.length != 3 || endParts.length != 3) return 1;
      
      final startDate = DateTime(
        int.parse(startParts[2]),
        int.parse(startParts[1]),
        int.parse(startParts[0]),
      );
      final endDate = DateTime(
        int.parse(endParts[2]),
        int.parse(endParts[1]),
        int.parse(endParts[0]),
      );
      
      return endDate.difference(startDate).inDays + 1;
    } catch (_) {
      return 3; // Fallback para 3 dias de ação
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: valueColor ?? AppColors.textPrimary, fontSize: 14, height: 1.4, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
