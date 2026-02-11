import 'package:football_predictions/main.dart';
import 'firebase_options_dev.dart' as dev;

void main() async {
  // Inicia o app passando as configurações de Desenvolvimento
  await initApp(dev.DefaultFirebaseOptions.currentPlatform);
}