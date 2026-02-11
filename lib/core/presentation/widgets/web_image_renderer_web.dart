// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget renderWebImage(String url, double? width, double? height, BoxFit fit) {
  // Cria um ID único baseado na URL para registrar a factory
  final String viewType = 'img-view-${url.hashCode}';

  // Registra a factory que cria o elemento HTML <img>
  // O platformViewRegistry permite injetar HTML nativo na árvore de widgets do Flutter
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final element = html.ImageElement();
    element.src = url;
    element.style.width = '100%';
    element.style.height = '100%';
    element.style.objectFit = _mapBoxFit(fit);
    element.style.border = 'none';
    return element;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}

String _mapBoxFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.cover:
      return 'cover';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
    default:
      return 'contain';
  }
}