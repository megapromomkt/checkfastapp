class PixBatchService {
  
  /// Gera um arquivo TXT de Lote PIX (Formato simplificado CNAB)
  /// Recebe uma lista de pagamentos aprovados do dia.
  static Future<String?> generatePixBatchFile(List<Map<String, dynamic>> approvedPayments) async {
    try {
      if (approvedPayments.isEmpty) return null;

      StringBuffer batchContent = StringBuffer();
      
      // HEADER DO ARQUIVO (Padrão Banco)
      String dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
      batchContent.writeln('01REMESSACHECKFAST          $dateStr');

      // DETALHES (Linhas de Pagamento PIX)
      double totalAmount = 0.0;
      int recordCount = 0;

      for (var payment in approvedPayments) {
        String name = (payment['name'] ?? 'DESCONHECIDO').toString().padRight(30).substring(0, 30);
        String pixKey = (payment['pixKey'] ?? '').toString().padRight(40).substring(0, 40);
        
        // Formatar valor: remover pontos e ter 2 casas decimais fixas (ex: 150.00 -> 0000015000)
        double amount = payment['amount'] ?? 0.0;
        totalAmount += amount;
        String amountStr = (amount * 100).toInt().toString().padLeft(10, '0');

        // Linha de transação tipo PIX
        batchContent.writeln('02PIX$pixKey$name$amountStr');
        recordCount++;
      }

      // TRAILER DO ARQUIVO
      String totalAmountStr = (totalAmount * 100).toInt().toString().padLeft(15, '0');
      String countStr = recordCount.toString().padLeft(6, '0');
      batchContent.writeln('99$countStr$totalAmountStr');

      // No Web, poderíamos disparar o download do Blob aqui.
      // Por enquanto, apenas retornamos sucesso simulado.
      return "Lote_Gerado_Web";
    } catch (e) {
      print("Erro ao gerar lote PIX: $e");
      return null;
    }
  }
}
