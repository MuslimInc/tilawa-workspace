import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_sessions/quran_sessions.dart';
import 'package:tilawa_ui_kit/tilawa_ui_kit.dart';

class RescheduleSessionScreen extends StatefulWidget {
  const RescheduleSessionScreen({
    super.key,
    required this.bookingId,
    required this.teacherId,
    required this.actorId,
  });

  final String bookingId;
  final String teacherId;
  final String actorId;

  @override
  State<RescheduleSessionScreen> createState() =>
      _RescheduleSessionScreenState();
}

class _RescheduleSessionScreenState extends State<RescheduleSessionScreen> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    context.read<RescheduleBloc>().add(
      RescheduleLoadRequested(
        bookingId: widget.bookingId,
        teacherId: widget.teacherId,
        from: now,
        to: now.add(const Duration(days: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.quranSessionsL10n;

    return QuranSessionsScaffold(
      title: l10n.rescheduleSessionTitle,
      resizeToAvoidBottomInset: true,
      body: BlocConsumer<RescheduleBloc, RescheduleState>(
        listener: (context, state) {
          if (state is RescheduleSuccess) {
            TilawaFeedback.showToast(
              context,
              message: l10n.rescheduleRequestSubmitted,
              variant: TilawaFeedbackVariant.success,
            );
            Navigator.pop(context, true);
          }
        },
        builder: (context, state) => switch (state) {
          RescheduleInitial() ||
          RescheduleLoading() ||
          RescheduleSubmitting() => const Center(
            child: CircularProgressIndicator(),
          ),
          RescheduleFailure(:final failure) => Center(
            child: Text(failure.toLocalizedMessage(context)),
          ),
          RescheduleSelecting(:final availableSlots) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DateGroupedSlotPicker(
                  slots: availableSlots,
                  selectedSlotId: state.selectedSlot?.slotId,
                  onSlotSelected: (slot) => context.read<RescheduleBloc>().add(
                    RescheduleSlotSelected(slot),
                  ),
                ),
              ),
              TilawaBottomActionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Theme.of(context).tokens.spaceSmall,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.rescheduleReasonLabel,
                        hintText: l10n.rescheduleReasonHint,
                      ),
                      onChanged: (value) => context.read<RescheduleBloc>().add(
                        RescheduleReasonChanged(value),
                      ),
                    ),
                    TilawaFormSubmitFooter(
                      buttonText: l10n.rescheduleSubmitAction,
                      onPressed: state.canSubmit
                          ? () => context.read<RescheduleBloc>().add(
                              RescheduleSubmitted(
                                bookingId: widget.bookingId,
                                actorId: widget.actorId,
                              ),
                            )
                          : () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
