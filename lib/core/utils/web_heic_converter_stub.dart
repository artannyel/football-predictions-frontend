import 'dart:typed_data';

// Esta é a implementação "stub" para plataformas não-web.
// Ela nunca será chamada se o código estiver protegido por `kIsWeb`.
Future<Uint8List> convertHeicToJpgWeb(Uint8List bytes) async {
  throw UnsupportedError('Cannot convert HEIC on this platform');
}