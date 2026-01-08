import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ai_scanner_service.dart';

class AiScannerView extends StatefulWidget {
  final String mode; // 'plate' or 'odometer'
  
  const AiScannerView({super.key, required this.mode});

  @override
  State<AiScannerView> createState() => _AiScannerViewState();
}

class _AiScannerViewState extends State<AiScannerView> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isPermissionGranted = false;
  bool _isProcessing = false;
  String _detectedText = '';
  String? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _isPermissionGranted = status.isGranted;
      });
      if (_isPermissionGranted) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing || _result != null) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage != null) {
        final text = await AiScannerService.recognizeText(inputImage);
        if (text != null && mounted) {
          String? extracted;
          if (widget.mode == 'plate') {
            extracted = AiScannerService.extractLicensePlate(text);
          } else {
            extracted = AiScannerService.extractOdometer(text);
          }

          if (extracted != null) {
            setState(() {
              _result = extracted;
              _detectedText = extracted!;
            });
            // Give user a moment to see the result
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context, extracted);
            });
          } else {
             // Show raw detected snippets for debugging if needed
             // For now just keep scanning
          }
        }
      }
    } catch (e) {
      debugPrint('Processing Error: $e');
    } finally {
      // Throttle processing
      Future.delayed(const Duration(milliseconds: 200), () {
        _isProcessing = false;
      });
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    // This logic varies by platform and package version nuances
    // ML Kit requires metadata about the image format
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageRotation = InputImageRotationValue.fromRawValue(
      _cameraController!.description.sensorOrientation,
    ) ?? InputImageRotation.rotation0deg;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) 
        ?? InputImageFormat.yuv420;

    final inputImageData = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPermissionGranted) {
      return Scaffold(body: Center(child: Text('Camera Permission Required')));
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(child: CameraPreview(_cameraController!)),

          // Stealth Overlay
          _buildOverlayLayout(),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayLayout() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'STEALTH SCANNER',
              style: TextStyle(
                color: Color(0xFF4FC3F7),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.mode == 'plate' ? 'POSITION LICENSE PLATE' : 'POSITION ODOMETER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            // Scanning Box
            Container(
              width: 300,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _result != null ? const Color(0xFF4CAF50) : const Color(0xFF4FC3F7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                   if (_result != null)
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _result!,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              '100% OFFLINE BRAIN ACTIVE',
              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
