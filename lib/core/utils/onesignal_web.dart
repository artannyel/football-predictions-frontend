import 'dart:js_interop';
import 'package:flutter/foundation.dart';

// Mapeia as funções globais que criamos no index.html
@JS('flutterOneSignalInit')
external void _jsOneSignalInit(JSString appId);

@JS('flutterOneSignalLogin')
external void _jsOneSignalLogin(JSString userId);

@JS('flutterOneSignalLogout')
external void _jsOneSignalLogout();

void oneSignalInitWeb(String appId) {
  try {
    _jsOneSignalInit(appId.toJS);
  } catch (e) {
    debugPrint('OneSignal Web: Erro ao chamar init JS: $e');
  }
}

void oneSignalLoginWeb(String userId) {
  try {
    _jsOneSignalLogin(userId.toJS);
  } catch (e) {
    debugPrint('OneSignal Web: Erro ao chamar login JS: $e');
  }
}

void oneSignalLogoutWeb() {
  try {
    _jsOneSignalLogout();
  } catch (e) {
    debugPrint('OneSignal Web: Erro ao chamar logout JS: $e');
  }
}