import 'package:flutter/foundation.dart';
import 'package:football_predictions/main.dart';
import 'firebase_options_prod.dart' as prod;

void main() async {
  // Inicia o app passando as configurações de Produção
  await initApp(kIsWeb ? prod.DefaultFirebaseOptions.currentPlatform : null);
}