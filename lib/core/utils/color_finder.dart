import 'package:flutter/material.dart';
import 'package:leaf_det/core/constants/app_colors.dart';

Color colorFinder(String labelText) {
  switch (labelText.trim()) {
    case "Common-Purslane":
      return AppColors.label1Color;
    case "Early-Eggplant":
      return AppColors.label2Color;
    case "Mature-Eggplant":
      return AppColors.label3Color;
    case "Meadow-Grass":
      return AppColors.label4Color;
    default:
      return Colors.black;
  }
}
