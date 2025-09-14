import 'package:flutter/material.dart';

class DetectionResult {
  final Rect boundingBox;
  final String label;
  final double confidence;

  DetectionResult({
    required this.boundingBox,
    required this.label,
    required this.confidence,
  });
}