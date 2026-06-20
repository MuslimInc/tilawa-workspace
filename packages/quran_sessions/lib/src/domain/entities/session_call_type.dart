/// How a session is conducted.
///
/// [externalMeeting] — teacher shares an external link (Zoom, Meet, etc.).
/// [voiceCall]       — in-app voice (future: Agora).
/// [videoCall]       — in-app video (future: Agora / WebRTC).
enum SessionCallType {
  externalMeeting,
  voiceCall,
  videoCall,
}
