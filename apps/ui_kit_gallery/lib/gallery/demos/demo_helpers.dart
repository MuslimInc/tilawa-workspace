import 'package:flutter/material.dart';

/// Shared layout helpers for gallery demos.
class GalleryDemoFrame extends StatelessWidget {
  const GalleryDemoFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.alignment = Alignment.topCenter,
    this.backgroundColor,
    this.scrollable = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final Alignment alignment;
  final Color? backgroundColor;

  /// When false, the child is given the scaffold body's bounded height.
  ///
  /// Use for demos that manage their own scrolling (e.g. [GridView]).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Theme.of(context).colorScheme.surface;
    final content = Align(alignment: alignment, child: child);

    if (!scrollable) {
      return ColoredBox(
        color: color,
        child: Padding(padding: padding, child: content),
      );
    }

    return ColoredBox(
      color: color,
      child: SingleChildScrollView(
        padding: padding,
        child: content,
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
