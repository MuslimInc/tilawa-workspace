import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../src/atoms/atoms.dart';
import '../src/previews/preview_wrapper.dart';

// --- TilawaCard Previews ---

@Preview(name: 'TilawaCard / Light', group: 'Atoms')
Widget previewTilawaCardLight() {
  return const TilawaPreviewWrapper(
    child: TilawaCard(child: Text('Light Theme Card')),
  );
}

@Preview(name: 'TilawaCard / Dark', group: 'Atoms')
Widget previewTilawaCardDark() {
  return const TilawaPreviewWrapper(
    isDark: true,
    child: TilawaCard(child: Text('Dark Theme Card')),
  );
}

@Preview(name: 'TilawaCard / RTL', group: 'Atoms')
Widget previewTilawaCardRTL() {
  return const TilawaPreviewWrapper(
    isRTL: true,
    child: TilawaCard(child: Text('بطاقة بنمط عربي')),
  );
}

// --- TilawaIconBox Previews ---

@Preview(name: 'TilawaIconBox / Default', group: 'Atoms')
Widget previewTilawaIconBox() {
  return const TilawaPreviewWrapper(
    child: TilawaIconBox(icon: Icons.bookmark_rounded),
  );
}

// --- TilawaLoadingIndicator Previews ---

@Preview(name: 'TilawaLoadingIndicator / Default', group: 'Atoms')
Widget previewTilawaLoadingIndicator() {
  return const TilawaPreviewWrapper(child: TilawaLoadingIndicator());
}

@Preview(name: 'TilawaLoadingIndicator / Compact', group: 'Atoms')
Widget previewTilawaLoadingIndicatorCompact() {
  return const TilawaPreviewWrapper(
    child: TilawaLoadingIndicator(strokeWidth: 2.0),
  );
}

// --- TilawaEmptyState Previews ---

@Preview(name: 'TilawaEmptyState / Default', group: 'Atoms')
Widget previewTilawaEmptyState() {
  return TilawaPreviewWrapper(
    child: TilawaEmptyState(
      icon: Icons.inbox_outlined,
      title: 'Nothing here yet',
      subtitle: 'New items will show up here once you add them.',
      action: FilledButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    ),
  );
}

@Preview(name: 'TilawaButton / All Variants', group: 'Atoms')
Widget previewTilawaButton() {
  return const TilawaPreviewWrapper(
    child: SingleChildScrollView(child: ButtonPreviews()),
  );
}

class ButtonPreviews extends StatelessWidget {
  const ButtonPreviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variants',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            TilawaButton(text: 'Primary', onPressed: () {}),
            TilawaButton(
              text: 'Secondary',
              variant: TilawaButtonVariant.secondary,
              onPressed: () {},
            ),
            TilawaButton(
              text: 'Outline',
              variant: TilawaButtonVariant.outline,
              onPressed: () {},
            ),
            TilawaButton(
              text: 'Ghost',
              variant: TilawaButtonVariant.ghost,
              onPressed: () {},
            ),
            TilawaButton(
              text: 'Danger',
              variant: TilawaButtonVariant.danger,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'States',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            const TilawaButton(text: 'Disabled', onPressed: null),
            TilawaButton(text: 'Loading', isLoading: true, onPressed: () {}),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Icons & Width',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            TilawaButton(
              text: 'Leading Icon',
              leadingIcon: const Icon(Icons.add),
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            TilawaButton(
              text: 'Trailing Icon',
              trailingIcon: const Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            TilawaButton(
              text: 'Full Width Button',
              isFullWidth: true,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Sizes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TilawaButton(
              text: 'Small',
              size: TilawaButtonSize.small,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            TilawaButton(
              text: 'Medium',
              size: TilawaButtonSize.medium,
              onPressed: () {},
            ),
            const SizedBox(width: 12),
            TilawaButton(
              text: 'Large',
              size: TilawaButtonSize.large,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

@Preview(name: 'TilawaEmptyState / Scale 1.5', group: 'Atoms')
Widget previewTilawaEmptyStateScale() {
  return TilawaPreviewWrapper(
    textScale: 1.5,
    child: TilawaEmptyState(
      icon: Icons.inbox_outlined,
      title: 'Nothing here yet',
      subtitle: 'Testing text scaling layout.',
    ),
  );
}

// --- TilawaDivider Previews ---

@Preview(name: 'TilawaDivider / Default', group: 'Atoms')
Widget previewTilawaDivider() {
  return const TilawaPreviewWrapper(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [Text('Above'), TilawaDivider(), Text('Below')],
    ),
  );
}

// --- TilawaTextField Previews ---

@Preview(name: 'TilawaTextField / Gallery', group: 'Atoms')
Widget previewTilawaTextFieldGallery() {
  return const TilawaPreviewWrapper(
    child: SingleChildScrollView(
      child: Padding(padding: EdgeInsets.all(16.0), child: TextFieldPreviews()),
    ),
  );
}

@Preview(name: 'TilawaTextField / RTL Arabic', group: 'Atoms')
Widget previewTilawaTextFieldRtl() {
  return const TilawaPreviewWrapper(
    isRTL: true,
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: TilawaTextField(
        label: 'الاسم الكامل',
        hintText: 'أدخل اسمك هنا',
        prefixIcon: Icon(Icons.person_outline),
      ),
    ),
  );
}

class TextFieldPreviews extends StatelessWidget {
  const TextFieldPreviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standard Variants',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'Default Field',
          hintText: 'Enter text here',
        ),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'With Helper',
          hintText: 'Enter text',
          helperText: 'This is a helper message',
        ),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'With Prefix Icon',
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search),
        ),
        const SizedBox(height: 16),
        TilawaTextField(
          label: 'With Clear Button',
          initialValue: 'Clear me',
          onClear: () {},
        ),
        const SizedBox(height: 32),
        const Text(
          'Special States',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const TilawaTextField(label: 'Password Field', isPassword: true),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'Error State',
          errorText: 'This input is invalid',
        ),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'Disabled Field',
          enabled: false,
          initialValue: 'Cannot edit this',
        ),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'Read Only Field',
          readOnly: true,
          initialValue: 'Read only text',
        ),
        const SizedBox(height: 32),
        const Text(
          'Multiline',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const TilawaTextField(
          label: 'Multiline Field',
          hintText: 'Type multiple lines...',
          maxLines: 3,
        ),
      ],
    );
  }
}
