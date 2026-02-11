import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart';

@JS('heic2any')
external JSPromise heic2any(JSObject options);

Future<Uint8List> convertHeicToJpgWeb(Uint8List bytes) async {
  final blob = Blob([bytes.toJS].toJS);
  
  // Configura as opções: { blob: blob, toType: "image/jpeg", quality: 0.9 }
  final options = JSObject();
  options['blob'] = blob;
  options['toType'] = 'image/jpeg'.toJS;
  options['quality'] = 0.9.toJS;

  // Chama a função global heic2any(options)
  final promise = heic2any(options);
  final result = await promise.toDart;
  final resultBlob = result as Blob;

  // Converte o Blob resultante de volta para Uint8List
  final arrayBuffer = await resultBlob.arrayBuffer().toDart;
  return arrayBuffer.toDart.asUint8List();
}