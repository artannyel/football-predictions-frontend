import 'dart:io';

Future<String> saveFileImpl(String filename, List<int> bytes) async {
  // Usa o diretório temporário para garantir que funciona sem permissões extras
  // Em um app real, você usaria path_provider para getApplicationDocumentsDirectory
  final dir = Directory.systemTemp;
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return 'Salvo em: ${file.path}';
}