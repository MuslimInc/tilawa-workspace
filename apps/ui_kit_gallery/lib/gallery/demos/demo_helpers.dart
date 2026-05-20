import 'package:flutter/material.dart';

/// Shared layout helpers for gallery demos.
class GalleryDemoFrame extends StatelessWidget {
  const GalleryDemoFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.alignment = Alignment.topCenter,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Alignment alignment;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: padding,
        child: Align(alignment: alignment, child: child),
      ),
    );
  }
}

Widget gallerySection(String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      ...children,
    ],
  );
}
