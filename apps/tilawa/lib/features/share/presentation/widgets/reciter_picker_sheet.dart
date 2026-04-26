import 'package:flutter/material.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';
import '../utils/share_reciter_options.dart';

class ReciterPickerSheet extends StatefulWidget {
  const ReciterPickerSheet({
    super.key,
    required this.options,
    required this.selectedReciterName,
    required this.selectedServerUrl,
  });

  final List<ShareReciterOption> options;
  final String selectedReciterName, selectedServerUrl;

  @override
  State<ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends State<ReciterPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) => o.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final tokens = Theme.of(context).tokens;

    return TilawaCard(
      borderRadius: tokens.radiusExtraLarge,
      padding: EdgeInsets.all(tokens.spaceLarge),
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderColor: Colors.transparent,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: context.l10n.searchReciters,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            SizedBox(height: tokens.spaceMedium),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _query.trim().isEmpty
                            ? context.l10n.noRecitersFound
                            : context.l10n.noRecitersMatchSearch,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final o = filtered[i];
                        final sel = matchesShareReciterOption(
                          o,
                          selectedReciterName: widget.selectedReciterName,
                          selectedServerUrl: widget.selectedServerUrl,
                        );
                        return ListTile(
                          title: Text(
                            o.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: sel ? FontWeight.w700 : null,
                                  color: sel
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                          ),
                          trailing: sel
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, o),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
