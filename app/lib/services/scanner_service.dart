import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Wraps the device camera and ML Kit's barcode decoder (ADR 0003) to turn
/// a captured frame into a decoded barcode value.
///
/// **Design note:** this decodes via periodic still-capture
/// ([captureAndDecode], using [CameraController.takePicture] +
/// [decodeImageFile]) rather than processing the live raw camera frame
/// stream. Raw-frame decoding needs correct platform-specific pixel-format
/// conversion (YUV_420 on Android, BGRA on iOS) — a common source of
/// subtle bugs that, from a dev environment with no attached device, can't
/// be verified before shipping. Capture-then-decode is slightly slower per
/// attempt but reuses the exact same [decodeImageFile] path the on-device
/// fixture test (AT1.2) already validates, and still fully satisfies
/// SCAN-1/PLAT-3 (offline, camera-based scanning). A live-stream version
/// is a reasonable future enhancement once this can be tested on real
/// hardware.
///
/// UREQS: SCAN-1, SCAN-4, PLAT-3
class ScannerService {
  /// Creates the service. Call [initialize] before use.
  ///
  /// UREQS: SCAN-1
  ScannerService()
    : _barcodeScanner = BarcodeScanner(
        formats: [BarcodeFormat.upca, BarcodeFormat.ean13],
      );

  final BarcodeScanner _barcodeScanner;
  CameraController? _controller;

  /// The initialized camera controller, once [initialize] has completed;
  /// `null` beforehand or after [dispose].
  ///
  /// UREQS: PLAT-3
  CameraController? get controller => _controller;

  /// Initializes the back camera.
  ///
  /// Throws a [CameraException] if no camera is available or permission is
  /// denied — callers should surface a clear error rather than a blank
  /// preview.
  ///
  /// UREQS: PLAT-3
  Future<void> initialize() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
  }

  /// Captures a still frame from the live camera and attempts to decode a
  /// barcode from it. Returns `null` if none was found in that frame —
  /// callers are expected to let the user try again rather than treat a
  /// single miss as a hard failure (SCAN-4's offline requirement is
  /// satisfied by construction: this never makes a network call).
  ///
  /// UREQS: SCAN-1, SCAN-4
  Future<String?> captureAndDecode() => captureAndProcess(decodeImageFile);

  /// Captures a still frame and runs [process] on the resulting file path,
  /// cleaning the temporary file up afterward either way. Generalizes
  /// [captureAndDecode] (which passes [decodeImageFile]) so other capture
  /// steps — price-tag OCR via `PriceOcrService.scanImageFile` (PRICE-1)
  /// — can reuse the same camera/cleanup handling rather than duplicating
  /// it.
  ///
  /// UREQS: SCAN-1, PRICE-1
  Future<T?> captureAndProcess<T>(
    Future<T?> Function(String path) process,
  ) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }
    final file = await controller.takePicture();
    try {
      return await process(file.path);
    } finally {
      unawaited(_deleteQuietly(file.path));
    }
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {
      // Best-effort cleanup of the temporary capture file; a failure to
      // delete it isn't worth surfacing to the user.
    }
  }

  /// Decodes a barcode from a static image file rather than the live
  /// camera. Used by [captureAndDecode] above, and directly by the
  /// on-device integration test (AT1.2) against the generated fixture
  /// images in `test/fixtures/barcodes/` — the same code path either way.
  ///
  /// UREQS: SCAN-1
  Future<String?> decodeImageFile(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final barcodes = await _barcodeScanner.processImage(inputImage);
    if (barcodes.isEmpty) {
      return null;
    }
    return barcodes.first.rawValue;
  }

  /// Stops the camera and releases ML Kit resources.
  ///
  /// UREQS: SCAN-1
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    await _barcodeScanner.close();
  }
}
