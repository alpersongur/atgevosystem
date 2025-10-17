import 'package:flutter/material.dart';

import '../models/assistant_query_model.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final background = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: Radius.circular(isUser ? 0 : 16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: foreground.a * 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
