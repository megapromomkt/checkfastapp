import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';


class MLKitAntiFraudService {
  final FaceDetector _faceDetector;

  MLKitAntiFraudService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: false,
            enableClassification: true, // Necessário para ver se os olhos estão abertos
            enableTracking: false,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

  /// Recebe o caminho da foto tirada na hora do Check-in e verifica se há um rosto humano válido.
  Future<bool> containsValidHumanFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // Regra 1: Tem que ter exatamente 1 rosto na foto (evitar foto com grupo de pessoas)
      if (faces.isEmpty || faces.length > 1) {
        return false;
      }

      final face = faces.first;

      // Regra 2: Verificação de vivacidade (Liveness detection básico)
      // Checa se pelo menos um olho está aberto com uma probabilidade aceitável (> 40%)
      if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.4 && face.rightEyeOpenProbability! < 0.4) {
          return false; // Olhos fechados / Foto de foto estática ruim
        }
      }

      return true; // Rosto válido detectado
    } catch (e) {
      print("Erro no Anti-Fraude Facial: \$e");
      return false; // Em caso de erro de leitura, barra por segurança
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
