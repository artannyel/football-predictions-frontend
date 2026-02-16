import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarChart extends StatelessWidget {
  final List<double> values1;
  final List<double>? values2;
  final List<String> labels;
  final double maxValue;
  final Color color1;
  final Color? color2;
  final double animationValue;

  const RadarChart({
    super.key,
    required this.values1,
    this.values2,
    required this.labels,
    required this.maxValue,
    required this.color1,
    this.color2,
    this.animationValue = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarChartPainter(
        values1: values1,
        values2: values2,
        labels: labels,
        maxValue: maxValue,
        color1: color1,
        color2: color2,
        animationValue: animationValue,
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<double> values1;
  final List<double>? values2;
  final List<String> labels;
  final double maxValue;
  final Color color1;
  final Color? color2;
  final double animationValue;

  _RadarChartPainter({
    required this.values1,
    this.values2,
    required this.labels,
    required this.maxValue,
    required this.color1,
    this.color2,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 * 0.8;
    final radius = maxRadius * animationValue;
    final angleStep = (2 * math.pi) / labels.length;

    final paintWeb = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Desenha a teia (background)
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      final path = Path();
      for (int j = 0; j < labels.length; j++) {
        final angle = j * angleStep - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paintWeb);
    }

    // Desenha as linhas dos eixos e labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (int i = 0; i < labels.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), paintWeb);

      // Labels
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      );
      textPainter.layout();

      // Ajuste fino da posição do texto
      final textOffset = Offset(
        x + (math.cos(angle) * 15) - textPainter.width / 2,
        y + (math.sin(angle) * 15) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    // Função auxiliar para desenhar os dados
    void drawData(List<double> values, Color color) {
      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final r = (values[i] / maxValue) * radius;
        final angle = i * angleStep - math.pi / 2;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    drawData(values1, color1);
    if (values2 != null && color2 != null) {
      drawData(values2!, color2!);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}