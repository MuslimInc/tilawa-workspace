import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/features/downloads/presentation/bloc/downloads_bloc.dart';
import 'package:muzakri/l10n/generated/app_localizations.dart';

class DownloadButton extends StatefulWidget {
  const DownloadButton({
    super.key,
    required this.surahId,
    required this.surahTitle,
    required this.reciterName,
    required this.url,
  });

  final String surahId;
  final String surahTitle;
  final String reciterName;
  final String url;

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isDownloaded = false;
  bool _isChecking = true;

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
        }
      },
      child: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              icon: Icon(
                _isDownloaded ? Icons.download_done : Icons.download,
                color: _isDownloaded ? Colors.green : null,
              ),
              tooltip: _isDownloaded
                  ? AppLocalizations.of(context)!.downloaded
                  : AppLocalizations.of(context)!.download,
              onPressed: _isDownloaded ? null : _downloadSurah,
            ),
    );
  }

  void _downloadSurah() {
    context.read<DownloadsBloc>().add(
      DownloadSurahEvent(
        surahId: widget.surahId,
        surahTitle: widget.surahTitle,
        reciterName: widget.reciterName,
        url: widget.url,
      ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${widget.surahTitle}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
