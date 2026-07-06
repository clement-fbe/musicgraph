import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/router/app_routes.dart';
import 'scan_view_model.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  late final MobileScannerController _controller;
  bool _isHandlingCode = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isHandlingCode) return;

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .firstOrNull;

    if (rawValue == null) return;

    setState(() => _isHandlingCode = true);

    try {
      await _controller.stop();
      final artist = await ref
          .read(scanViewModelProvider.notifier)
          .resolve(rawValue);

      if (!mounted) return;

      context.goNamed(
        AppRoutes.artistDetailName,
        pathParameters: {'mbid': artist.mbid},
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isHandlingCode = false);
      await _controller.start();
    }
  }

  Future<void> _retry() async {
    ref.read(scanViewModelProvider.notifier).reset();
    setState(() => _isHandlingCode = false);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
        actions: [
          IconButton(
            tooltip: 'Lampe',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on),
          ),
          IconButton(
            tooltip: 'Camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error) => _ScannerError(
              message: _cameraErrorMessage(error),
              onRetry: _retry,
            ),
          ),
          const _ScannerOverlay(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _ScanStatusCard(
              state: scanState,
              isHandlingCode: _isHandlingCode,
              onRetry: _retry,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18)),
        child: Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({
    required this.state,
    required this.isHandlingCode,
    required this.onRetry,
  });

  final AsyncValue<Object?> state;
  final bool isHandlingCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black26,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: state.when(
          loading: () => const _StatusRow(
            icon: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: 'Recherche en cours',
            message: 'Analyse du QR code et recherche artiste.',
          ),
          error: (error, stackTrace) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(
                icon: Icon(Icons.error_outline, color: colorScheme.error),
                title: 'Scan impossible',
                message: error.toString(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Reessayer'),
                ),
              ),
            ],
          ),
          data: (_) => _StatusRow(
            icon: const Icon(Icons.qr_code_scanner),
            title: isHandlingCode ? 'QR code detecte' : 'Pret a scanner',
            message:
                'Scanne un QR Spotify ou un QR contenant un nom d\'artiste.',
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.message,
  });

  final Widget icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cameraErrorMessage(MobileScannerException error) {
  if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
    return 'Permission camera refusee.';
  }

  return 'Camera indisponible.';
}
