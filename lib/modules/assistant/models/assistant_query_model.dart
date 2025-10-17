import 'package:cloud_firestore/cloud_firestore.dart';

enum AssistantMessageRole { user, assistant, system }

class AssistantMessage {
  const AssistantMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final AssistantMessageRole role;
  final String text;
  final DateTime timestamp;

  bool get isUser => role == AssistantMessageRole.user;
  bool get isAssistant => role == AssistantMessageRole.assistant;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'role': role.name,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AssistantMessage.fromJson(Map<String, dynamic> json) {
    return AssistantMessage(
      role: AssistantMessageRole.values.firstWhere(
        (value) => value.name == json['role'],
        orElse: () => AssistantMessageRole.system,
      ),
      text: json['text'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AssistantResponse {
  const AssistantResponse({
    required this.answer,
    this.intent = 'general',
    this.suggestions = const [],
    this.quickActions = const [],
  });

  final String answer;
  final String intent;
  final List<String> suggestions;
  final List<AssistantQuickAction> quickActions;
}

class AssistantQuickAction {
  const AssistantQuickAction({
    required this.label,
    required this.payload,
    this.type = AssistantQuickActionType.message,
  });

  final String label;
  final String payload;
  final AssistantQuickActionType type;
}

enum AssistantQuickActionType { message, navigation, command }

class AssistantInsight {
  const AssistantInsight({
    required this.title,
    required this.description,
    this.trendText,
    this.trendUp,
  });

  final String title;
  final String description;
  final String? trendText;
  final bool? trendUp;
}

class AssistantLogEntry {
  const AssistantLogEntry({
    required this.id,
    required this.question,
    required this.answer,
    required this.userId,
    required this.companyId,
    required this.timestamp,
  });

  final String id;
  final String question;
  final String answer;
  final String? userId;
  final String? companyId;
  final DateTime timestamp;

  factory AssistantLogEntry.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return AssistantLogEntry(
      id: snapshot.id,
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      userId: data['user_id'] as String?,
      companyId: data['company_id'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
