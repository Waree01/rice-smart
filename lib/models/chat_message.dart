/// Roles in a Pasadee chat turn.
enum ChatRole { user, assistant, system }

/// A single turn in a Pasadee conversation.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// LLM provider that generated this message, if any (e.g. 'typhoon').
  final String? provider;

  /// True while the assistant is still streaming / loading.
  final bool isLoading;

  /// True if the call errored — [content] holds a human-readable message.
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.provider,
    this.isLoading = false,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    bool? isError,
    String? provider,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      provider: provider ?? this.provider,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'provider': provider,
        'isError': isError,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: ChatRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => ChatRole.assistant,
        ),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        provider: json['provider'] as String?,
        isError: json['isError'] as bool? ?? false,
      );
}
