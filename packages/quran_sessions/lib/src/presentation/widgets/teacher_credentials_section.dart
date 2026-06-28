import 'package:flutter/material.dart';
import 'package:quran_sessions/core/l10n_extensions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

import '../../domain/entities/teacher_credential.dart';
import 'quran_sessions_section_header.dart';

/// Collapsible teacher credentials supplied by the tutor (ijazah, certs).
class TeacherCredentialsSection extends StatefulWidget {
  const TeacherCredentialsSection({super.key, required this.credentials});

  final List<TeacherCredential> credentials;

  @override
  State<TeacherCredentialsSection> createState() =>
      _TeacherCredentialsSectionState();
}

class _TeacherCredentialsSectionState extends State<TeacherCredentialsSection> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.credentials.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranSessionsSectionHeader(title: l10n.teacherCredentialsSectionTitle),
        SizedBox(height: tokens.spaceExtraSmall),
        TilawaCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSmall,
                    vertical: tokens.spaceSmall,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.teacherCredentialsSummary(
                            widget.credentials.length,
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                Divider(height: 1, color: scheme.outlineVariant),
                Padding(
                  padding: EdgeInsets.all(tokens.spaceSmall),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final credential in widget.credentials)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: tokens.spaceSmall,
                          ),
                          child: _CredentialRow(credential: credential),
                        ),
                      Text(
                        l10n.teacherCredentialsDisclaimer,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.credential});

  final TeacherCredential credential;

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = theme.tokens;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          credential.isVerified
              ? Icons.verified_outlined
              : Icons.workspace_premium_outlined,
          size: tokens.iconSizeSmall,
          color: credential.isVerified
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
        SizedBox(width: tokens.spaceSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                credential.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (credential.issuer != null &&
                  credential.issuer!.trim().isNotEmpty) ...[
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  credential.issuer!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (credential.isVerified) ...[
                SizedBox(height: tokens.spaceExtraSmall),
                Text(
                  l10n.teacherCredentialVerifiedBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
