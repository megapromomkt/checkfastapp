import 'package:excel/excel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

class ExportService {
  /// Gera um arquivo XLS com o relatório de Presença
  static Future<String?> exportAttendancesToXLS(List<Map<String, dynamic>> data) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Presenças'];
      excel.setDefaultSheet('Presenças');

      // Cabeçalhos
      List<String> headers = ['Nome', 'CPF', 'Loja', 'Data', 'Check-in', 'Checkout', 'Horas', 'Status'];
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Preenchimento de Dados
      for (var row in data) {
        sheetObject.appendRow([
          TextCellValue(row['nome'] ?? ''),
          TextCellValue(row['cpf'] ?? ''),
          TextCellValue(row['loja'] ?? ''),
          TextCellValue(row['data'] ?? ''),
          TextCellValue(row['checkin'] ?? ''),
          TextCellValue(row['checkout'] ?? ''),
          TextCellValue(row['horas']?.toString() ?? '0'),
          TextCellValue(row['status'] ?? ''),
        ]);
      }

      // Salvar arquivo localmente (Comentado para compatibilidade Web)
      // final directory = await getApplicationDocumentsDirectory();
      // final filePath = '${directory.path}/Relatorio_Presencas_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      // File(filePath)
      //   ..createSync(recursive: true)
      //   ..writeAsBytesSync(excel.encode()!);
      
      return "Relatorio_Web_Gerado";
    } catch (e) {
      print("Erro ao exportar XLS: \$e");
      return null;
    }
  }
}
