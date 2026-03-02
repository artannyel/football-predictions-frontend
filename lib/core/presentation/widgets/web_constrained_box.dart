import 'package:flutter/material.dart';

class WebConstrainedBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = 800, // Largura máxima para simular uma experiência mobile/tablet
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}