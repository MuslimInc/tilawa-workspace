import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quran_booking.dart';
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
    this.onBookingSuccess,
  });

  final String teacherId;
  final String? preSelectedSlotId;

  /// Called after a booking is confirmed. When provided, the host app handles
  /// navigation; otherwise the screen pops itself.
  final void Function(QuranBooking booking)? onBookingSuccess;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _autoSelectedSlot = false;

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
      appBar: AppBar(title: const Text('احجز جلسة')),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          // Auto-select the pre-selected slot the first time BookingSelecting loads.
          if (!_autoSelectedSlot &&
              widget.preSelectedSlotId != null &&
              state is BookingSelecting) {
            _autoSelectedSlot = true;
            final slot = state.availableSlots
                .where((s) => s.slotId == widget.preSelectedSlotId)
                .firstOrNull;
            if (slot != null) {
              context.read<BookingBloc>().add(SlotSelected(slot));
            }
          }

          if (state is BookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تأكيد الحجز!')),
            );
            if (widget.onBookingSuccess != null) {
              widget.onBookingSuccess!(state.booking);
            } else {
              Navigator.of(context).pop();
            }
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
                Text('جارٍ تأكيد الحجز…'),
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
                    'اختر موعداً',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AvailabilitySlotPicker(
                            slots: availableSlots,
                            selectedSlotId: selectedSlot?.slotId,
                            initialSlotId: widget.preSelectedSlotId,
                            onSlotSelected: (slot) =>
                                context.read<BookingBloc>().add(SlotSelected(slot)),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'نوع الجلسة',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _CallTypePicker(
                            selected: selectedCallType,
                            onChanged: (ct) =>
                                context.read<BookingBloc>().add(CallTypeSelected(ct)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: canSubmit ? _submit : null,
                    child: const Text('تأكيد الحجز'),
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
          label: Text('رابط خارجي'),
          icon: Icon(Icons.link),
        ),
        ButtonSegment(
          value: SessionCallType.voiceCall,
          label: Text('صوتي'),
          icon: Icon(Icons.mic),
        ),
        ButtonSegment(
          value: SessionCallType.videoCall,
          label: Text('مرئي'),
          icon: Icon(Icons.videocam),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
