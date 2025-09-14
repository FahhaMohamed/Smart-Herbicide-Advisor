import 'dart:io';
import 'dart:typed_data';

import 'package:leaf_det/core/constants/app_strings.dart';
import 'package:leaf_det/core/widgets/custom_snack.dart';
import 'package:leaf_det/models/detection_results.dart';
import 'package:leaf_det/services/recommendation_service.dart';
import 'package:leaf_det/core/utils/box_painter.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:leaf_det/views/herbicide_guide_page/herbicide_guide_page.dart';
import 'package:leaf_det/views/image_upload_screen/widgets/recommendation_card.dart';
import 'package:leaf_det/views/image_upload_screen/widgets/unselect_image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ImageClassificationPage extends StatefulWidget {
  // These parameters are passed in from the SplashScreen
  final Interpreter? interpreter;
  final List<String> labels;
  final bool isModelLoaded;

  const ImageClassificationPage({
    Key? key,
    required this.interpreter,
    required this.labels,
    required this.isModelLoaded,
  }) : super(key: key);

  @override
  State<ImageClassificationPage> createState() =>
      _ImageClassificationPageState();
}

class _ImageClassificationPageState extends State<ImageClassificationPage>
    with TickerProviderStateMixin {
  File? _image;
  List<DetectionResult> _results = [];
  bool _isClassifying = false;
  bool _isLoadingImage = false;
  Size _imageSize = Size.zero;
  final RecommendationService _recommendationService = RecommendationService();
  Recommendation? _recommendation;

  late final TransformationController _transformationController;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _shimmerController.dispose();
    widget.interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appTitle),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildStatusIndicator(),
          ),
          const SizedBox(height: 24),
          _buildImageDisplay(),
          if (_recommendation != null && !_isClassifying) ...[
            const SizedBox(height: 24),
            RecommendationCard(recommendation: _recommendation!),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSelectImageButton(),
                const SizedBox(height: 12),
                _buildHerbicideGuideButton(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_image != null && !_isClassifying && _results.isEmpty)
            const Center(
              child: Text(
                "No objects detected.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Container(
      height: 450,
      color: Colors.black.withOpacity(0.05),
      child: _buildImageContent(),
    );
  }

  Widget _buildImageContent() {
    if (_isLoadingImage) {
      return _buildImageLoadingShimmer();
    }

    if (_image == null) {
      return UnselectImage();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: _minScale,
          maxScale: _maxScale,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _imageSize.width,
              height: _imageSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    _image!,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;
                          return AnimatedOpacity(
                            opacity: frame == null ? 0 : 1,
                            duration: const Duration(milliseconds: 300),
                            child: child,
                          );
                        },
                  ),
                  if (_results.isNotEmpty)
                    CustomPaint(painter: CustomBoxPainter(results: _results)),
                ],
              ),
            ),
          ),
        ),
        if (_isClassifying)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing image...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_image != null && !_isLoadingImage && !_isClassifying)
          _buildZoomControls(),
      ],
    );
  }

  Widget _buildImageLoadingShimmer() {
    _shimmerController.repeat();

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1.0 + _shimmerAnimation.value * 2, -1.0),
                    end: Alignment(1.0 + _shimmerAnimation.value * 2, 1.0),
                    colors: [
                      Colors.grey.shade300,
                      Colors.grey.shade100,
                      Colors.white,
                      Colors.grey.shade100,
                      Colors.grey.shade300,
                    ],
                    stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment(
                            -1.0 + _shimmerAnimation.value * 2,
                            0,
                          ),
                          end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
                          colors: [
                            Colors.grey.shade200,
                            Colors.white,
                            Colors.grey.shade200,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Icon(
                        Icons.image,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment(
                            -1.0 + _shimmerAnimation.value * 2,
                            0,
                          ),
                          end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
                          colors: [
                            Colors.grey.shade200,
                            Colors.white,
                            Colors.grey.shade200,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment(
                            -1.0 + _shimmerAnimation.value * 2,
                            0,
                          ),
                          end: Alignment(1.0 + _shimmerAnimation.value * 2, 0),
                          colors: [
                            Colors.grey.shade200.withOpacity(0.8),
                            Colors.white.withOpacity(0.8),
                            Colors.grey.shade200.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      top: 10,
      right: 10,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.add,
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.zoom_out_map,
            onPressed: _resetZoom,
            tooltip: 'Reset Zoom',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isModelLoaded ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: widget.isModelLoaded ? Colors.green : Colors.red,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            widget.isModelLoaded ? Icons.check_circle : Icons.error,
            color: widget.isModelLoaded ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isModelLoaded
                ? 'Model loaded (${widget.labels.length} classes)'
                : 'Model not loaded',
            style: TextStyle(
              color: widget.isModelLoaded
                  ? Colors.green.shade800
                  : Colors.red.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHerbicideGuideButton() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.grass),
      label: const Text('View Weed Control Guide'),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HerbicideGuidePage()),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green.shade700,
        side: BorderSide(color: Colors.green.shade700),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSelectImageButton() {
    return ElevatedButton.icon(
      onPressed: (widget.isModelLoaded && !_isLoadingImage && !_isClassifying)
          ? _showImageSourceDialog
          : null,
      icon: _isLoadingImage
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.upload),
      label: Text(
        _isLoadingImage
            ? 'Loading...'
            : (_image != null ? 'Upload Another Image' : 'Upload Image'),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _zoomIn() {
    final double currentScale = _transformationController.value
        .getMaxScaleOnAxis();
    final double newScale = (currentScale * 1.5).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _zoomOut() {
    final double currentScale = _transformationController.value
        .getMaxScaleOnAxis();
    final double newScale = (currentScale / 1.5).clamp(_minScale, _maxScale);
    _transformationController.value = Matrix4.identity()..scale(newScale);
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoadingImage = true;
        _results = [];
        _recommendation = null;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        _resetZoom();

        await Future.delayed(const Duration(milliseconds: 500));

        setState(() {
          _image = File(pickedFile.path);
          _isLoadingImage = false;
        });

        _shimmerController.stop();

        await _classifyImage();
      } else {
        setState(() {
          _isLoadingImage = false;
        });
        _shimmerController.stop();
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _isLoadingImage = false;
      });
      _shimmerController.stop();

      if (mounted) {
        customSnack(
          context,
          msg: 'Error loading image: ${e.toString()}',
          bgColor: Colors.red,
        );
      }
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null || widget.interpreter == null || widget.labels.isEmpty)
      return;

    setState(() {
      _isClassifying = true;
      _recommendation = null; 
    });

    try {
      final imageBytes = await _image!.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Failed to decode image');

      setState(() {
        _imageSize = Size(
          originalImage.width.toDouble(),
          originalImage.height.toDouble(),
        );
      });

      List<int> inputShape = widget.interpreter!.getInputTensor(0).shape;
      Float32List input = _preprocessImage(originalImage, inputShape[1]);
      var inputTensor = input.reshape(inputShape);
      List<int> outputShape = widget.interpreter!.getOutputTensor(0).shape;
      var outputTensor = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );
      widget.interpreter!.run(inputTensor, outputTensor);

      List<DetectionResult> newResults = [];
      const double confidenceThreshold = 0.3;
      for (int detection = 0; detection < outputShape[2]; detection++) {
        double maxConfidence = 0.0;
        int bestClassIndex = -1;
        for (int classIdx = 4; classIdx < outputShape[1]; classIdx++) {
          double confidence = outputTensor[0][classIdx][detection];
          if (confidence > maxConfidence) {
            maxConfidence = confidence;
            bestClassIndex = classIdx - 4;
          }
        }
        if (maxConfidence > confidenceThreshold) {
          double xCenter = outputTensor[0][0][detection];
          double yCenter = outputTensor[0][1][detection];
          double width = outputTensor[0][2][detection];
          double height = outputTensor[0][3][detection];
          double left = (xCenter - width / 2) * _imageSize.width;
          double top = (yCenter - height / 2) * _imageSize.height;
          Rect boundingBox = Rect.fromLTWH(
            left,
            top,
            width * _imageSize.width,
            height * _imageSize.height,
          );
          newResults.add(
            DetectionResult(
              boundingBox: boundingBox,
              label: widget.labels[bestClassIndex],
              confidence: maxConfidence,
            ),
          );
        }
      }
      List<DetectionResult> finalResults = _applyNMS(newResults);

      final detectedLabels = finalResults
          .map((result) => result.label)
          .toList();
      final recommendation = _recommendationService.getRecommendation(
        detectedLabels,
      );

      setState(() {
        _results = finalResults;
        _recommendation = recommendation;
      });
    } catch (e) {
      print('Error during classification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  Float32List _preprocessImage(img.Image image, int inputSize) {
    img.Image resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );
    Float32List inputBytes = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);
        inputBytes[pixelIndex++] = pixel.r / 255.0;
        inputBytes[pixelIndex++] = pixel.g / 255.0;
        inputBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return inputBytes;
  }

  List<DetectionResult> _applyNMS(List<DetectionResult> results) {
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    List<DetectionResult> finalResults = [];

    for (var result in results) {
      bool isOverlapping = finalResults.any((existingResult) {
        final iou = _calculateIoU(
          result.boundingBox,
          existingResult.boundingBox,
        );
        return result.label == existingResult.label && iou > 0.4;
      });

      if (!isOverlapping) {
        finalResults.add(result);
      }
    }
    return finalResults;
  }

  double _calculateIoU(Rect rect1, Rect rect2) {
    final intersectionLeft = rect1.left > rect2.left ? rect1.left : rect2.left;
    final intersectionTop = rect1.top > rect2.top ? rect1.top : rect2.top;
    final intersectionRight = rect1.right < rect2.right
        ? rect1.right
        : rect2.right;
    final intersectionBottom = rect1.bottom < rect2.bottom
        ? rect1.bottom
        : rect2.bottom;

    if (intersectionRight > intersectionLeft &&
        intersectionBottom > intersectionTop) {
      final intersectionArea =
          (intersectionRight - intersectionLeft) *
          (intersectionBottom - intersectionTop);
      final unionArea =
          rect1.width * rect1.height +
          rect2.width * rect2.height -
          intersectionArea;
      return intersectionArea / unionArea;
    }
    return 0.0;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from photo library'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_camera,
                      color: Colors.green.shade700,
                    ),
                  ),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a new photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
