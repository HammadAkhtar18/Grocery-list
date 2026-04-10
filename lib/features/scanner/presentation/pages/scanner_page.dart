import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../pantry/data/models/pantry_item_model.dart';
import '../../../pantry/data/repositories/pantry_repository_impl.dart';
import '../../../pantry/domain/repositories/pantry_repository.dart';
import '../../../pantry/presentation/widgets/add_pantry_item_sheet.dart';
import '../../../grocery_list/data/models/grocery_list_model.dart';
import '../../../grocery_list/data/repositories/grocery_repository_impl.dart';
import '../../../grocery_list/domain/repositories/grocery_repository.dart';
import '../../../grocery_list/presentation/bloc/grocery_lists_bloc.dart';
import '../../../grocery_list/presentation/widgets/add_item_sheet.dart';

typedef ScannerViewBuilder = Widget Function({
  required MobileScannerController controller,
  required void Function(BarcodeCapture capture) onDetect,
});

void _showAddItemFailureSnackBar(BuildContext context) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Could not add item'),
    ),
  );
}

/// Premium barcode scanner page
class ScannerPage extends StatefulWidget {
  final PantryRepository pantryRepository;
  final GroceryRepository groceryRepository;
  final ScannerViewBuilder? scannerViewBuilder;
  final bool enablePulseAnimation;

  ScannerPage({
    super.key,
    PantryRepository? pantryRepository,
    GroceryRepository? groceryRepository,
    this.scannerViewBuilder,
    this.enablePulseAnimation = true,
  })  : pantryRepository = pantryRepository ?? PantryRepositoryImpl(),
        groceryRepository = groceryRepository ?? GroceryRepositoryImpl();

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isProcessing = false;
  bool _isAddingItem = false;
  bool _isScannerRunning = false;
  bool _isStartingScanner = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.enablePulseAnimation) {
      _pulseController.repeat(reverse: true);
    }
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScannerIfVisible();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startScannerIfVisible();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopScanner();
        break;
    }
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

    PantryItemModel? existingItem;
    try {
      setState(() => _isAddingItem = true);

      // Check if barcode exists in pantry
      existingItem = await widget.pantryRepository.checkDuplicate('', code);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastScannedCode = null;
        });
      }
      if (!mounted) return;
      _showAddItemFailureSnackBar(context);
      return;
    } finally {
      if (mounted) {
        setState(() => _isAddingItem = false);
      }
    }

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
        parentContext: this.context,
        groceryRepository: widget.groceryRepository,
        pantryRepository: widget.pantryRepository,
        onDismiss: () {
          if (!mounted) return;
          setState(() {
            _isProcessing = false;
            _lastScannedCode = null;
          });
        },
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _lastScannedCode = null;
      });
    });
  }

  Future<void> _startScannerIfVisible() async {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    final isResumed =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;

    if (!mounted || !isResumed || _isScannerRunning || _isStartingScanner) {
      return;
    }

    _isStartingScanner = true;

    try {
      await _scannerController.start();
      _isScannerRunning = true;
    } catch (_) {
      _isScannerRunning = false;
    } finally {
      _isStartingScanner = false;
    }
  }

  Future<void> _stopScanner() async {
    if (!_isScannerRunning) return;

    try {
      await _scannerController.stop();
    } catch (_) {
      // Ignore stop errors during lifecycle changes.
    } finally {
      _isScannerRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scanner view
          widget.scannerViewBuilder?.call(
                controller: _scannerController,
                onDetect: _onDetect,
              ) ??
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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          onTap: _isAddingItem
                              ? null
                              : () => _scannerController.toggleTorch(),
                        ),
                        const SizedBox(width: 8),
                        _ControlButton(
                          icon: const Icon(Icons.cameraswitch_rounded,
                              color: Colors.white),
                          onTap: _isAddingItem
                              ? null
                              : () => _scannerController.switchCamera(),
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

          if (_isAddingItem)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withAlpha(120),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Preparing item...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

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
                    _isProcessing
                        ? 'Processing barcode...'
                        : 'Point at barcode to scan',
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
      painter: _ScanOverlayPainter(
        isProcessing: _isProcessing || _isAddingItem,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Control button widget
class _ControlButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;

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
            color: onTap == null
                ? Colors.white.withAlpha(15)
                : Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: onTap == null
                  ? Colors.white.withAlpha(15)
                  : Colors.white.withAlpha(30),
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
  final BuildContext parentContext;
  final GroceryRepository groceryRepository;
  final PantryRepository pantryRepository;
  final VoidCallback onDismiss;

  const _ScanResultSheet({
    required this.barcode,
    this.existingItem,
    required this.parentContext,
    required this.groceryRepository,
    required this.pantryRepository,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
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
                      child: Icon(Icons.inventory_2_rounded,
                          color: AppColors.primary),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                      _showAddToListDialog(parentContext, barcode);
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
                        _showAddToPantrySheet(
                          parentContext,
                          barcode,
                          existingItem,
                        );
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddToListSheet(
        parentContext: context,
        barcode: barcode,
        groceryRepository: groceryRepository,
        pantryRepository: pantryRepository,
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
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(context),
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

class _AddToListSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String barcode;
  final GroceryRepository groceryRepository;
  final PantryRepository pantryRepository;

  const _AddToListSheet({
    required this.parentContext,
    required this.barcode,
    required this.groceryRepository,
    required this.pantryRepository,
  });

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  List<GroceryListModel> _lists = const [];
  String? _selectedListId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    try {
      final lists = await widget.groceryRepository.getAllLists();
      if (!mounted) return;

      if (lists.isEmpty) {
        Navigator.of(context).pop();
        if (!widget.parentContext.mounted) return;
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: const Text('Create a shopping list first!'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      setState(() {
        _lists = lists;
        _selectedListId = lists.first.id;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      if (!widget.parentContext.mounted) return;
      _showAddItemFailureSnackBar(widget.parentContext);
    }
  }

  void _openAddItemSheet() {
    final selectedListId = _selectedListId;
    if (selectedListId == null) return;
    final groceryListsBloc = widget.parentContext.read<GroceryListsBloc>();

    Navigator.of(context).pop();
    if (!widget.parentContext.mounted) return;

    showModalBottomSheet(
      context: widget.parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(widget.parentContext),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BlocProvider.value(
          value: groceryListsBloc,
          child: AddItemSheet(
            groceryListId: selectedListId,
            initialBarcode: widget.barcode,
            pantryRepository: widget.pantryRepository,
            failureMessage: 'Could not add item',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.list_alt_rounded, color: Colors.white),
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
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              DropdownButtonFormField<String>(
                key: const Key('scanner_list_dropdown'),
                initialValue: _selectedListId,
                decoration: const InputDecoration(
                  labelText: 'Shopping List',
                  prefixIcon: Icon(Icons.shopping_bag_rounded),
                ),
                items: _lists
                    .map(
                      (list) => DropdownMenuItem<String>(
                        value: list.id,
                        child: Text(list.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedListId = value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('scanner_continue_button'),
                onPressed: _openAddItemSheet,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
