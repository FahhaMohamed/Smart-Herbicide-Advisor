import 'package:flutter/material.dart';

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> customSnack(
  BuildContext context, {
  required String msg,
  required Color bgColor,
}) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
