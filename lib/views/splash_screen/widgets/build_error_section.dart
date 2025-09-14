import 'package:flutter/material.dart';
import 'package:leaf_det/core/theme/app_theme.dart';
import 'package:leaf_det/core/widgets/custom_icon_widget.dart';
import 'package:sizer/sizer.dart';

Widget buildErrorSection() {
    VoidCallback? retryInitialization;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          color: Colors.white.withValues(alpha: 0.9),
          size: 8.w,
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.w),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Text(
            'Retry',
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }