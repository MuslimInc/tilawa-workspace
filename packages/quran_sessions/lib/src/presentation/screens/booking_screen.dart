import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/session_call_type.dart';
import '../failure_ui/quran_sessions_failure_ui.dart';
import '../blocs/booking/booking_bloc.dart';
import '../blocs/booking/booking_event.dart';
import '../blocs/booking/booking_state.dart';
import '../widgets/availability_slot_picker.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.teacherId,
    this.preSelectedSlotId,
  });

  final String teacherId;
  final String? preSelectedSlotId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    context.read<BookingBloc>().add(
      BookingScreenOpened(
        teacherId: widget.teacherId,
        from: now,
        to: now.add(const Duration(days: 14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Session')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking confirmed!')),
            );
            Navigator.of(context).pop();
          }
          if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure.toLocalizedMessage(context)),
              ),
            );
          }
        },
        builder: (context, state) => switch (state) {
          BookingInitial() || BookingSlotsLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          BookingSubmitting() => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Confirming your booking…'),
              ],
            ),
          ),
          BookingFailure(:final failure) => Center(
            child: Text(failure.toLocalizedMessage(context)),
          ),
          BookingSuccess() => const SizedBox.shrink(),
          BookingSelecting(
            :final availableSlots,
            :final selectedSlot,
            :final selectedCallType,
            :final canSubmit,
          ) =>
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pick a time slot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  AvailabilitySlotPicker(
                    slots: availableSlots,
                    selectedSlotId: selectedSlot?.slotId,
                    onSlotSelected: (slot) =>
                        context.read<BookingBloc>().add(SlotSelected(slot)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Session type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _CallTypePicker(
                    selected: selectedCallType,
                    onChanged: (ct) =>
                        context.read<BookingBloc>().add(CallTypeSelected(ct)),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    child: const Text('Confirm Booking'),
                  ),
                ],
              ),
            ),
        },
      ),
    );
  }

  void _submit() {
    final state = context.read<BookingBloc>().state;
    if (state is! BookingSelecting) return;
    final slot = state.selectedSlot;
    if (slot == null) return;

    context.read<BookingBloc>().add(
      BookingSubmitted(
        teacherId: widget.teacherId,
        slotId: slot.slotId,
        callType: state.selectedCallType,
      ),
    );
  }
}

class _CallTypePicker extends StatelessWidget {
  const _CallTypePicker({required this.selected, required this.onChanged});

  final SessionCallType selected;
  final ValueChanged<SessionCallType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SessionCallType>(
      segments: const [
        ButtonSegment(
          value: SessionCallType.externalMeeting,
          label: Text('External'),
          icon: Icon(Icons.link),
        ),
        ButtonSegment(
          value: SessionCallType.voiceCall,
          label: Text('Voice'),
          icon: Icon(Icons.mic),
        ),
        ButtonSegment(
          value: SessionCallType.videoCall,
          label: Text('Video'),
          icon: Icon(Icons.videocam),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
