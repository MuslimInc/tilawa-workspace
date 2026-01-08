import 'package:flutter/material.dart';

class QuranReaderBottomBar extends StatelessWidget {
  const QuranReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const primaryColor = Color(0xFF1B5E20); // Dark Green from image
    const backgroundColor = Color(0xFFF9F5EF); // Beige/Paper color

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Left: List Menu
              IconButton(
                onPressed: () {
                  // TODO: Show Juz/Surah list
                },
                icon: const Icon(
                  Icons.grid_view_rounded,
                  size: 28,
                  color: primaryColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
              ),

              const SizedBox(width: 16),

              // Center: Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 16, // Thicker track to match screenshot
                    trackShape: const RoundedRectSliderTrackShape(),
                    activeTrackColor: const Color(
                      0xFFE6Dfc8,
                    ), // Match inactive track for uniform bar look
                    inactiveTrackColor: const Color(
                      0xFFE6Dfc8,
                    ), // Beige track color from image
                    thumbShape: const _CapsuleSliderThumbShape(
                      thumbWidth: 48,
                      thumbHeight: 16,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                    thumbColor: primaryColor,
                  ),
                  child: Slider(
                    value: currentPage.toDouble().clamp(
                      1.0,
                      totalPages.toDouble(),
                    ),
                    min: 1,
                    max: totalPages.toDouble(),
                    onChanged: (value) => onPageChanged(value.round()),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Right: Page Indicator & Return
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_rounded, size: 24, color: primaryColor),
                  Text(
                    '$currentPage',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CapsuleSliderThumbShape extends SliderComponentShape {
  const _CapsuleSliderThumbShape({
    required this.thumbWidth,
    required this.thumbHeight,
  });
  final double thumbWidth;
  final double thumbHeight;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbWidth, thumbHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Color color = sliderTheme.thumbColor ?? Colors.green;
    final double radius = thumbHeight / 2;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: thumbWidth, height: thumbHeight),
      Radius.circular(radius),
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rRect, paint);
  }
}
