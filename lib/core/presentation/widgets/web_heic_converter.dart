import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

Future<Uint8List> convertHeicToJpgWeb(Uint8List bytes) async {
  final blob = html.Blob([bytes]);
  
  // Configura as opções: { blob: blob, toType: "image/jpeg", quality: 0.9 }
  final options = js_util.newObject();
  js_util.setProperty(options, 'blob', blob);
  js_util.setProperty(options, 'toType', 'image/jpeg');
  js_util.setProperty(options, 'quality', 0.7);

  // Chama a função global heic2any(options)
  final promise = js_util.callMethod(html.window, 'heic2any', [options]);
  final resultBlob = await js_util.promiseToFuture(promise);

  // Converte o Blob resultante de volta para Uint8List
  final reader = html.FileReader()..readAsArrayBuffer(resultBlob);
  await reader.onLoad.first;
  return reader.result as Uint8List;
}