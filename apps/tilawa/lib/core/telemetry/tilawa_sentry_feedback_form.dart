import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tilawa/core/extensions.dart';
import 'package:tilawa/core/telemetry/tilawa_feedback_screenshot_session.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

/// Key used by Sentry replay to recognize widget-submitted feedback.
const String _kSentryWidgetFeedbackHint = 'isWidgetFeedback';

/// Tilawa-styled bug report form that submits via [Sentry.captureFeedback].
class TilawaSentryFeedbackForm extends StatefulWidget {
  const TilawaSentryFeedbackForm({
    super.key,
    this.associatedEventId,
    this.screenshot,
    this.initialName,
    this.initialEmail,
    this.initialMessage,
    this.hub,
    this.flutterOptions,
  }) : assert(associatedEventId != const SentryId.empty());

  final SentryId? associatedEventId;
  final SentryAttachment? screenshot;
  final String? initialName;
  final String? initialEmail;
  final String? initialMessage;
  final Hub? hub;
  final SentryFlutterOptions? flutterOptions;

  static void show(
    BuildContext context, {
    SentryId? associatedEventId,
    SentryAttachment? screenshot,
    String? initialName,
    String? initialEmail,
    String? initialMessage,
    RouteSettings? routeSettings,
    Hub? hub,
    SentryFlutterOptions? flutterOptions,
  }) {
    if (!context.mounted) {
      return;
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        settings: routeSettings,
        fullscreenDialog: true,
        builder: (BuildContext context) => TilawaSentryFeedbackForm(
          associatedEventId: associatedEventId,
          screenshot: screenshot,
          initialName: initialName,
          initialEmail: initialEmail,
          initialMessage: initialMessage,
          hub: hub,
          flutterOptions: flutterOptions,
        ),
      ),
    );
  }

  @override
  State<TilawaSentryFeedbackForm> createState() =>
      _TilawaSentryFeedbackFormState();
}

class _TilawaSentryFeedbackFormState extends State<TilawaSentryFeedbackForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  late final Hub _hub;
  late final SentryFlutterOptions _flutterOptions;

  SentryAttachment? _screenshot;
  Future<Uint8List>? _screenshotFuture;
  bool _isSubmitting = false;
  bool _isCapturingScreenshot = false;
  bool _isCapturingFromAnotherScreen = false;

  @override
  void initState() {
    super.initState();
    _hub = widget.hub ?? HubAdapter();
    _flutterOptions =
        widget.flutterOptions ??
        // ignore: invalid_use_of_internal_member
        (_hub.options as SentryFlutterOptions);

    if (_flutterOptions.feedback.useSentryUser) {
      _prefillFromSentryUser();
    }

    _applyDraftValues();

    final SentryAttachment? screenshot = widget.screenshot;
    if (screenshot != null) {
      _screenshot = screenshot;
      _screenshotFuture = Future<Uint8List>.value(screenshot.bytes);
    }

    unawaited(_captureReplay());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;
    final feedback = _flutterOptions.feedback;

    return Scaffold(
      resizeToAvoidBottomInset: feedback.resizeToAvoidBottomInset,
      appBar: TilawaAppBar(
        title: feedback.title,
      ),
      body: TilawaFormScreenScaffold(
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.spaceMedium,
            children: <Widget>[
              if (feedback.showName)
                TilawaTextField(
                  key: const ValueKey('tilawa_sentry_feedback_name'),
                  label: _labeled(
                    feedback.nameLabel,
                    isRequired: feedback.isNameRequired,
                  ),
                  hintText: feedback.namePlaceholder,
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) => _validationError(
                    value,
                    isRequired: feedback.isNameRequired,
                  ),
                ),
              if (feedback.showEmail)
                TilawaTextField(
                  key: const ValueKey('tilawa_sentry_feedback_email'),
                  label: _labeled(
                    feedback.emailLabel,
                    isRequired: feedback.isEmailRequired,
                  ),
                  hintText: feedback.emailPlaceholder,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (String? value) => _validationError(
                    value,
                    isRequired: feedback.isEmailRequired,
                  ),
                ),
              TilawaTextField(
                key: const ValueKey('tilawa_sentry_feedback_message'),
                label: _labeled(feedback.messageLabel, isRequired: true),
                hintText: feedback.messagePlaceholder,
                controller: _messageController,
                minLines: 5,
                maxLines: null,
                maxLength: 4096,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                validator: (String? value) =>
                    _validationError(value, isRequired: true),
              ),
              if (_screenshotFuture != null) _buildScreenshotPreview(tokens),
              if (_screenshot == null &&
                  feedback.showCaptureScreenshot) ...<Widget>[
                TilawaButton(
                  key: const ValueKey(
                    'tilawa_sentry_feedback_capture_screenshot',
                  ),
                  text: feedback.captureScreenshotButtonLabel,
                  variant: TilawaButtonVariant.outline,
                  isFullWidth: true,
                  isLoading: _isCapturingScreenshot,
                  onPressed:
                      _isCapturingScreenshot || _isCapturingFromAnotherScreen
                      ? null
                      : _attachScreenshot,
                ),
                TilawaButton(
                  key: const ValueKey(
                    'tilawa_sentry_feedback_capture_screenshot_other_screen',
                  ),
                  text:
                      context.l10n.reportBugCaptureScreenshotFromAnotherScreen,
                  variant: TilawaButtonVariant.ghost,
                  isFullWidth: true,
                  isLoading: _isCapturingFromAnotherScreen,
                  onPressed:
                      _isCapturingScreenshot || _isCapturingFromAnotherScreen
                      ? null
                      : _attachScreenshotFromAnotherScreen,
                ),
              ],
            ],
          ),
        ),
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.spaceSmall,
          children: <Widget>[
            TilawaButton(
              key: const ValueKey('tilawa_sentry_feedback_submit'),
              text: feedback.submitButtonLabel,
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            TilawaButton(
              key: const ValueKey('tilawa_sentry_feedback_cancel'),
              text: feedback.cancelButtonLabel,
              variant: TilawaButtonVariant.ghost,
              isFullWidth: true,
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.maybePop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotPreview(MeMuslimDesignTokens tokens) {
    final feedback = _flutterOptions.feedback;
    final BorderRadius borderRadius = BorderRadius.circular(
      tokens.resolveRadius(family: TilawaRadiusFamily.chrome),
    );

    return Row(
      spacing: tokens.spaceSmall,
      children: <Widget>[
        SizedBox(
          width: tokens.minInteractiveDimension,
          height: tokens.minInteractiveDimension,
          child: FutureBuilder<Uint8List>(
            future: _screenshotFuture,
            builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Icon(
                  Icons.broken_image_outlined,
                  color: Theme.of(context).colorScheme.error,
                );
              }

              final Uint8List bytes = snapshot.data!;
              return TilawaInteractiveSurface(
                key: const ValueKey(
                  'tilawa_sentry_feedback_screenshot_thumbnail',
                ),
                onTap: () => TilawaSentryScreenshotPreview.show(
                  context,
                  bytes,
                ),
                borderRadius: borderRadius,
                semanticLabel: context.l10n.reportBugPreviewScreenshot,
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: TilawaButton(
            key: const ValueKey('tilawa_sentry_feedback_remove_screenshot'),
            text: feedback.removeScreenshotButtonLabel,
            variant: TilawaButtonVariant.outline,
            isFullWidth: true,
            onPressed: () {
              setState(() {
                _screenshot = null;
                _screenshotFuture = null;
              });
            },
          ),
        ),
      ],
    );
  }

  String _labeled(String label, {required bool isRequired}) {
    final feedback = _flutterOptions.feedback;
    return isRequired ? '$label${feedback.isRequiredLabel}' : label;
  }

  String? _validationError(String? value, {required bool isRequired}) {
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return _flutterOptions.feedback.validationErrorLabel;
    }
    return null;
  }

  TilawaFeedbackScreenshotDraft _draftFields() {
    return TilawaFeedbackScreenshotDraft(
      name: _nameController.text,
      email: _emailController.text,
      message: _messageController.text,
      associatedEventId: widget.associatedEventId,
    );
  }

  TilawaFeedbackScreenshotCaptureCopy _captureCopy(BuildContext context) {
    final l10n = context.l10n;
    return TilawaFeedbackScreenshotCaptureCopy(
      hint: l10n.reportBugScreenshotCaptureHint,
      capture: l10n.reportBugScreenshotCaptureNow,
      cancel: l10n.reportBugScreenshotCaptureCancel,
      captureFailed: l10n.reportBugScreenshotCaptureFailed,
    );
  }

  Future<void> _attachScreenshot() async {
    setState(() => _isCapturingScreenshot = true);

    try {
      if (!context.mounted) {
        return;
      }

      await TilawaFeedbackScreenshotSession.attachFromCurrentScreen(
        formContext: context,
        draft: _draftFields(),
        hub: _hub,
        flutterOptions: _flutterOptions,
        captureFailedCopy: _captureCopy(context),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingScreenshot = false);
      }
    }
  }

  Future<void> _attachScreenshotFromAnotherScreen() async {
    setState(() => _isCapturingFromAnotherScreen = true);

    try {
      if (!context.mounted) {
        return;
      }

      await TilawaFeedbackScreenshotSession.attachFromAnotherScreen(
        formContext: context,
        draft: _draftFields(),
        hub: _hub,
        flutterOptions: _flutterOptions,
        overlayCopy: _captureCopy(context),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturingFromAnotherScreen = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final SentryFeedback feedback = SentryFeedback(
        message: _messageController.text,
        contactEmail: _emailController.text,
        name: _nameController.text,
        associatedEventId: widget.associatedEventId,
      );

      Hint hint = Hint()..set(_kSentryWidgetFeedbackHint, true);
      if (_screenshot != null) {
        hint = Hint.withScreenshot(_screenshot!)
          ..set(_kSentryWidgetFeedbackHint, true);
      }

      final SentryId sentryId = await _hub.captureFeedback(
        feedback,
        hint: hint,
      );

      if (!mounted) {
        return;
      }

      final options = _flutterOptions.feedback;
      try {
        options.onSubmitSuccess?.call(feedback, sentryId);
      } catch (_) {
        // Mirrors Sentry SDK: callback failures must not block dismissal.
      }

      if (options.showSuccessMessage) {
        _showSuccessSnackBar();
      }

      Navigator.maybePop(context);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessSnackBar() {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) {
      return;
    }

    final options = _flutterOptions.feedback;
    final Color successColor = options.successColor;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color foregroundColor =
        ThemeData.estimateBrightnessForColor(successColor) == Brightness.dark
        ? colorScheme.onInverseSurface
        : colorScheme.inverseSurface;

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: successColor,
        content: Text(
          options.successMessageText,
          style: TextStyle(color: foregroundColor),
        ),
      ),
    );
  }

  void _prefillFromSentryUser() {
    SentryUser? user;
    _hub.configureScope((Scope scope) {
      user = scope.user;
    });
    if (user == null) {
      return;
    }

    final String? userName = user!.name;
    if (userName != null && _nameController.text.isEmpty) {
      _nameController.text = userName;
    }
    final String? userEmail = user!.email;
    if (userEmail != null && _emailController.text.isEmpty) {
      _emailController.text = userEmail;
    }
  }

  void _applyDraftValues() {
    final String? initialName = widget.initialName;
    if (initialName != null && initialName.isNotEmpty) {
      _nameController.text = initialName;
    }

    final String? initialEmail = widget.initialEmail;
    if (initialEmail != null && initialEmail.isNotEmpty) {
      _emailController.text = initialEmail;
    }

    final String? initialMessage = widget.initialMessage;
    if (initialMessage != null && initialMessage.isNotEmpty) {
      _messageController.text = initialMessage;
    }
  }

  // coverage:ignore-start
  Future<void> _captureReplay() async {
    for (final Integration<dynamic> integration
        in _flutterOptions.integrations) {
      if (integration.runtimeType.toString() != 'ReplayIntegration') {
        continue;
      }
      await (integration as dynamic).captureReplay();
      return;
    }
  }

  // coverage:ignore-end
}

/// Full-screen preview for a Sentry feedback screenshot attachment.
class TilawaSentryScreenshotPreview extends StatelessWidget {
  const TilawaSentryScreenshotPreview({super.key, required this.bytes});

  final Uint8List bytes;

  static Future<void> show(BuildContext context, Uint8List bytes) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) =>
            TilawaSentryScreenshotPreview(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MeMuslimDesignTokens tokens = Theme.of(context).tokens;

    return Scaffold(
      appBar: TilawaAppBar(
        title: context.l10n.reportBugScreenshotPreviewTitle,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: InteractiveViewer(
            key: const ValueKey(
              'tilawa_sentry_feedback_screenshot_preview_image',
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
