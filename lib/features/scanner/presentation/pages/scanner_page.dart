import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pantry/data/repositories/pantry_repository_impl.dart';
import '../../../pantry/data/models/pantry_item_model.dart';
import '../../../pantry/presentation/widgets/add_pantry_item_sheet.dart';
import '../../../grocery_list/presentation/widgets/add_item_sheet.dart';
import '../../../grocery_list/data/repositories/grocery_repository_impl.dart';

/// Premium barcode scanner page
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isProcessing = false;
  String? _lastScannedCode;
  final PantryRepositoryImpl _pantryRepository = PantryRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;

    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    // Check if barcode exists in pantry
    final existingItem = await _pantryRepository.checkDuplicate('', code);

    if (mounted) {
      _showScanResultSheet(code, existingItem);
    }
  }

  void _showScanResultSheet(String barcode, PantryItemModel? existingItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScanResultSheet(
        barcode: barcode,
        existingItem: existingItem,
        onDismiss: () {
          setState(() {
            _isProcessing = false;
            _lastScannedCode = null;
          });
        },
      ),
    ).then((_) {
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          
          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(180),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // App bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scan Barcode',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    // Controls
                    Row(
                      children: [
                        _ControlButton(
                          icon: ValueListenableBuilder<TorchState>(
                            valueListenable: _scannerController.torchState,
                            builder: (context, state, _) {
                              return Icon(
                                state == TorchState.on
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: state == TorchState.on
                                    ? AppColors.accentYellow
                                    : Colors.white,
                              );
                            },
                          ),
                          onTap: () => _scannerController.toggleTorch(),
                        ),
                        const SizedBox(width: 8),
                        _ControlButton(
                          icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                          onTap: () => _scannerController.switchCamera(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scan overlay with animation
          _buildScanOverlay(),

          // Instructions at bottom
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.black.withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withAlpha(20),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppGradients.sunsetGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withAlpha(80),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isProcessing
                                ? Icons.hourglass_top_rounded
                                : Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isProcessing ? 'Processing barcode...' : 'Point at barcode to scan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The barcode will be detected automatically',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: _ScanOverlayPainter(isProcessing: _isProcessing),
      child: const SizedBox.expand(),
    );
  }
}

/// Control button widget
class _ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withAlpha(30),
              width: 1,
            ),
          ),
          child: icon,
        ),
      ),
    );
  }
}

/// Custom painter for premium scan overlay
class _ScanOverlayPainter extends CustomPainter {
  final bool isProcessing;

  _ScanOverlayPainter({this.isProcessing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withAlpha(120)
      ..style = PaintingStyle.fill;

    // Calculate scan area
    final scanAreaSize = size.width * 0.75;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2.5;

    // Draw semi-transparent overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(24),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw scan area border with gradient effect
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: isProcessing
            ? [const Color(0xFFFF6B6B), const Color(0xFFFFA07A)]
            : [AppColors.primary, AppColors.primaryGradientEnd],
      ).createShader(Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(24),
      ),
      borderPaint,
    );

    // Draw corner accents
    final cornerLength = 40.0;
    final cornerPaint = Paint()
      ..shader = LinearGradient(
        colors: isProcessing
            ? [const Color(0xFFFF6B6B), const Color(0xFFFFA07A)]
            : [AppColors.primary, AppColors.primaryGradientEnd],
      ).createShader(Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top + 24),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + 24, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize - 24, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + 24),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize - 24),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + 24, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize - 24, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize - 24),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return isProcessing != oldDelegate.isProcessing;
  }
}

/// Premium bottom sheet showing scan result
class _ScanResultSheet extends StatelessWidget {
  final String barcode;
  final PantryItemModel? existingItem;
  final VoidCallback onDismiss;

  const _ScanResultSheet({
    required this.barcode,
    this.existingItem,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Success animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Barcode Scanned!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                barcode,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // If item exists in pantry
            if (existingItem != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(15),
                      AppColors.primaryGradientEnd.withAlpha(15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Found in Pantry',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${existingItem!.name} - ${existingItem!.quantity} ${existingItem!.unit}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Location: ${existingItem!.location}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddToListDialog(context, barcode);
                    },
                    icon: const Icon(Icons.shopping_cart_rounded),
                    label: const Text('Add to List'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.secondaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withAlpha(60),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddToPantrySheet(context, barcode, existingItem);
                      },
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('Add to Pantry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onDismiss();
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan Another'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToListDialog(BuildContext context, String barcode) async {
    final groceryRepo = GroceryRepositoryImpl();
    final lists = await groceryRepo.getAllLists();

    if (!context.mounted) return;

    if (lists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Create a shopping list first!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.list_alt_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Select List',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shopping_bag_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${list.totalCount} items'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: AddItemSheet(
                            listId: list.id,
                            initialBarcode: barcode,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAddToPantrySheet(
    BuildContext context,
    String barcode,
    PantryItemModel? existingItem,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddPantryItemSheet(
          existingItem: existingItem,
          initialBarcode: barcode,
        ),
      ),
    );
  }
}
