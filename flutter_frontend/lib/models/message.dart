import 'package:intl/intl.dart';

class Message {
  final String id;
  final String content;
  final bool isBot;
  final String username;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.isBot,
    required this.username,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'].toString(),
        content: j['content'] ?? '',
        isBot: j['is_bot'] ?? false,
        username: j['username'] ?? 'Unknown',
        createdAt:
            DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
      );

  String get formattedTime {
    return DateFormat('HH:mm').format(createdAt);
  }
}
