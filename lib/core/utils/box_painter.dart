import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:leaf_det/models/detection_results.dart';
import 'package:leaf_det/core/utils/color_finder.dart';

class CustomBoxPainter extends CustomPainter {
  final List<DetectionResult> results;

  CustomBoxPainter({required this.results});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = Colors.primaries;

    for (var i = 0; i < results.length; i++) {
      final result = results[i];

      final rect = result.boundingBox;

      final color = colors[i % colors.length].withOpacity(0.85);

      final paint = Paint()
        ..color = colorFinder(result.label)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width * 0.005).clamp(1.5, 3.0);

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text:
              ' ${result.label} ${(result.confidence * 100).toStringAsFixed(1)}% ',
          style: TextStyle(
            backgroundColor: colorFinder(result.label),
            color: Colors.white,
            fontSize: (size.width * 0.03).clamp(10.0, 18.0),
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: size.width);

      double textX = rect.left;
      double textY = rect.top - textPainter.height;

      if (textY < 0) {
        textY = rect.top + (paint.strokeWidth / 2);
      }
      if (textX < 0) {
        textX = 0.0;
      }

      final labelOffset = Offset(textX, textY);

      textPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(CustomBoxPainter oldDelegate) {
    return oldDelegate.results != results;
  }
}
