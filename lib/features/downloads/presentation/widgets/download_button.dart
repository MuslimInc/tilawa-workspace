import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/features/premium/presentation/widgets/premium_upgrade_dialog.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';
import 'package:muzakri/router/app_router.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    super.key,
    required this.surahId,
    required this.surahTitle,
    required this.reciterName,
  });

  final String surahId;
  final String surahTitle;
  final String reciterName;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isDownloaded = false;
  bool _isChecking = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    context.read<DownloadsBloc>().add(
      DownloadsEvent.checkSurahDownloaded(
        surahId: widget.surahId,
        reciterName: widget.reciterName,
      ),
    );
  }

  bool get _canDownload => !_isDownloaded && !_isDownloading && !_isChecking;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DownloadsBloc, DownloadsState>(
      listener: (context, state) {
        if (state is SurahDownloadStatus &&
            state.surahId == widget.surahId &&
            state.reciterName == widget.reciterName) {
          setState(() {
            _isDownloaded = state.isDownloaded;
            _isChecking = false;
          });
        } else if (state is DownloadStarted &&
            state.surahId == widget.surahId &&
            state.reciterName == widget.reciterName) {
          setState(() {
            _isDownloading = true;
          });
        } else if (state is DownloadsLoaded) {
          // Refresh download status when downloads are loaded
          _checkIfDownloaded();
        } else if (state is DownloadsError) {
          // Check if this error is related to our download
          if (state.message.contains(widget.surahTitle) &&
              state.message.contains(widget.reciterName)) {
            setState(() {
              _isDownloading = false;
            });
            // Refresh download status to check if it was actually completed
            _checkIfDownloaded();
          }
        } else if (state is PremiumRequired) {
          // Show premium upgrade dialog
          _showPremiumUpgradeDialog(context, state.message);
        }
      },
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    if (_isChecking) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Hide the button completely if already downloaded or currently downloading
    if (_isDownloaded || _isDownloading) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: AppLocalizations.of(context)!.download,
      onPressed: _canDownload ? _downloadSurah : null,
    );
  }

  void _downloadSurah() {
    if (!_canDownload) return;

    context.read<DownloadsBloc>().add(
      DownloadSurahEvent(
        surahId: widget.surahId,
        surahTitle: widget.surahTitle,
        reciterName: widget.reciterName,
      ),
    );

    // Show success message with View Downloads action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${widget.surahTitle}...'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.viewDownloads,
          onPressed: () {
            context.push(AppRouter.downloads);
          },
        ),
      ),
    );
  }

  void _showPremiumUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => PremiumUpgradeDialog(
        title: 'Premium Required',
        message: message,
        onUpgrade: () {
          context.push(AppRouter.premium);
        },
      ),
    );
  }
}
