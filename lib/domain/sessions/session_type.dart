/// Represents all the possible types of sessions in the application.
enum SessionType {
  wordSession(0),
  sentenceSession(1);

  const SessionType(this.code);

  final int code;

  static SessionType fromCode(int code) =>
      SessionType.values.firstWhere((e) => e.code == code);
}
