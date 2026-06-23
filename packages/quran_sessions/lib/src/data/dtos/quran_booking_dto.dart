class QuranBookingDto {
  const QuranBookingDto({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.slotId,
    required this.requestedCallType,
    required this.pricingType,
    required this.status,
    required this.createdAt,
    this.amountPaidUsd,
    this.paymentReference,
    this.sessionId,
    this.studentNote,
  });

  final String id;
  final String teacherId;
  final String studentId;
  final String slotId;
  final String requestedCallType;
  final String pricingType;
  final String status;
  final String createdAt;
  final double? amountPaidUsd;
  final String? paymentReference;
  final String? sessionId;
  final String? studentNote;

  factory QuranBookingDto.fromJson(Map<String, dynamic> json) =>
      QuranBookingDto(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        studentId: json['student_id'] as String,
        slotId: json['slot_id'] as String,
        requestedCallType: json['requested_call_type'] as String,
        pricingType: json['pricing_type'] as String,
        status: json['status'] as String,
        createdAt: json['created_at'] as String,
        amountPaidUsd: (json['amount_paid_usd'] as num?)?.toDouble(),
        paymentReference: json['payment_reference'] as String?,
        sessionId: json['session_id'] as String?,
        studentNote: json['student_note'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacher_id': teacherId,
    'student_id': studentId,
    'slot_id': slotId,
    'requested_call_type': requestedCallType,
    'pricing_type': pricingType,
    'status': status,
    'created_at': createdAt,
    'amount_paid_usd': amountPaidUsd,
    'payment_reference': paymentReference,
    'session_id': sessionId,
    'student_note': studentNote,
  };
}
