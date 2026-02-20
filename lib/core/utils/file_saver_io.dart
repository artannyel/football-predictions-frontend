import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveFileImpl(String filename, List<int> bytes) async {
  Directory? dir;
  if (Platform.isAndroid) {
    dir = Directory('/storage/emulated/0/Download');
  } else {
    dir = await getApplicationDocumentsDirectory();
  }

  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return 'Salvo em: ${file.path}';
}