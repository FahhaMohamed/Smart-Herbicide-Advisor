import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leaf_det/core/constants/app_strings.dart';
import 'package:leaf_det/core/theme/app_theme.dart';
import 'package:leaf_det/views/image_upload_screen/image_upload_screen.dart';
import 'package:leaf_det/views/splash_screen/widgets/build_error_section.dart';
import 'package:leaf_det/views/splash_screen/widgets/build_loading_indicator.dart';
import 'package:leaf_det/views/splash_screen/widgets/build_logo.dart';
import 'package:sizer/sizer.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _loadingOpacityAnimation;

  String _loadingText = 'Initializing LeafDetect AI...';
  bool _modelLoaded = false;
  bool _permissionsChecked = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<String> _labels = [];
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _loadingOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _logoAnimationController.forward();
  }

  Future<void> _startSplashSequence() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _loadingAnimationController.forward();

      // Initialize AI model
      await _initializeAIModel();
      await _navigateToNextScreen();
    } catch (e) {
      _handleError('Failed to initialize app: ${e.toString()}');
    }
  }

  Future<void> _initializeAIModel() async {
    setState(() {
      _loadingText = 'Loading AI Model...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1200));

      // Check if model files exist in assets
      await _loadModelAssets();

      setState(() {
        _modelLoaded = true;
        _loadingText = 'AI Model Ready';
      });

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      throw Exception('Model initialization failed');
    }
  }

  Future<void> _loadModelAssets() async {
    try {
      _interpreter = await Interpreter.fromAsset(AppStrings.modelPath);
      final labelsData = await rootBundle.loadString(AppStrings.labelsPath);
      setState(() {
        _labels = labelsData
            .split('\n')
            .where((label) => label.isNotEmpty)
            .toList();
      });
      setState(() {
        _modelLoaded = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      throw Exception('Failed to load model assets: ${e.toString()}');
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasError) return;

    if (!kIsWeb) {
      HapticFeedback.lightImpact();
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ImageClassificationPage(
            interpreter: _interpreter,
            labels: _labels,
            isModelLoaded: _modelLoaded,
          ),
        ),
      );
    }
  }

  void _handleError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _loadingText = 'Initialization Failed';
    });
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _modelLoaded = false;
      _permissionsChecked = false;
      _loadingText = 'Retrying...';
    });

    _startSplashSequence();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightTheme.colorScheme.primary,
              AppTheme.lightTheme.colorScheme.primaryContainer,
              AppTheme.lightTheme.colorScheme.secondary,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacityAnimation.value,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: buildLogo(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Loading Section
              Expanded(
                flex: 1,
                child: AnimatedBuilder(
                  animation: _loadingAnimationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loadingOpacityAnimation.value,
                      child: _buildLoadingSection(),
                    );
                  },
                ),
              ),

              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading Indicator or Error
        _hasError ? buildErrorSection() : buildLoadingIndicator(),

        SizedBox(height: 3.h),

        // Loading Text
        Text(
          _loadingText,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        if (_hasError) ...[
          SizedBox(height: 2.h),
          Text(
            _errorMessage,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
