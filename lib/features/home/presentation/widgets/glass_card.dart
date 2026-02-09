import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      margin: margin,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}