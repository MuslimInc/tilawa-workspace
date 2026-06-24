export type SessionParticipantRole = "teacher" | "student";

export interface SessionParticipantDoc {
  userId: string;
  role: SessionParticipantRole;
}

export function buildIndividualParticipants(
  teacherId: string,
  studentId: string,
): SessionParticipantDoc[] {
  return [
    { userId: teacherId, role: "teacher" },
    { userId: studentId, role: "student" },
  ];
}
