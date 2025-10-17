import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/auth_service.dart';
import '../models/assistant_query_model.dart';
import '../services/assistant_service.dart';
import '../widgets/chat_message_bubble.dart';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  static const routeName = '/assistant/chat';

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AssistantMessage> _messages = <AssistantMessage>[];

  SharedPreferences? _prefs;
  bool _isSending = false;
  List<String> _suggestions = const <String>[];
  List<AssistantQuickAction> _quickActions = const <AssistantQuickAction>[];

  static const List<String> _defaultPrompts = <String>[
    'Bu ay kaç yeni müşteri ekledik?',
    'Tahsilat oranı nasıl?',
    'En kritik stok kalemleri hangileri?',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    _prefs ??= await SharedPreferences.getInstance();
    final stored = _prefs?.getStringList(_historyKey()) ?? const <String>[];
    final restored = stored
        .map(
          (json) => AssistantMessage.fromJson(
            Map<String, dynamic>.from(jsonDecode(json) as Map),
          ),
        )
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _messages.clear();
      _messages.addAll(restored);
    });
    _scrollToEnd();
  }

  Future<void> _persistHistory() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final list = _messages
        .map((message) => jsonEncode(message.toJson()))
        .toList();
    await prefs.setStringList(_historyKey(), list);
  }

  String _historyKey() {
    final uid = AuthService.instance.currentUser?.uid ?? 'anonymous';
    return 'assistant.history.$uid';
  }

  Future<void> _handleSubmit([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _suggestions = const <String>[];
      _quickActions = const <AssistantQuickAction>[];
      _messages.add(
        AssistantMessage(
          role: AssistantMessageRole.user,
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    });
    _inputController.clear();
    _scrollToEnd();
    await _persistHistory();

    try {
      final response = await AssistantService.instance.processQuery(
        text,
        userId: AuthService.instance.currentUser?.uid,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          AssistantMessage(
            role: AssistantMessageRole.assistant,
            text: response.answer,
            timestamp: DateTime.now(),
          ),
        );
        _suggestions = response.suggestions;
        _quickActions = response.quickActions;
        _isSending = false;
      });
      await _persistHistory();
      _scrollToEnd();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          AssistantMessage(
            role: AssistantMessageRole.system,
            text:
                'Üzgünüm, bir hata oluştu: $error. Lütfen tekrar deneyin veya sistemi yöneticinize bildirin.',
            timestamp: DateTime.now(),
          ),
        );
        _isSending = false;
      });
      await _persistHistory();
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ERP Asistanı Sohbeti')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isSending && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ERP Asistanı yazıyor...',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                return ChatMessageBubble(message: message);
              },
            ),
          ),
          if (_quickActions.isNotEmpty)
            _QuickActionsBar(
              actions: _quickActions,
              onActionSelected: _handleQuickAction,
            ),
          if (_suggestions.isNotEmpty)
            _SuggestionChips(
              suggestions: _suggestions,
              onSelected: (value) => _handleSubmit(value),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSubmit(),
                    decoration: const InputDecoration(
                      hintText: 'ERP asistanına sorunuzu yazın...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSending ? null : _handleSubmit,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Gönder'),
                ),
              ],
            ),
          ),
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: _SuggestionChips(
                suggestions: _defaultPrompts,
                onSelected: (value) => _handleSubmit(value),
              ),
            ),
        ],
      ),
    );
  }

  void _handleQuickAction(AssistantQuickAction action) {
    switch (action.type) {
      case AssistantQuickActionType.message:
        _handleSubmit(action.payload);
        break;
      case AssistantQuickActionType.navigation:
        Navigator.of(context).pushNamed(action.payload);
        break;
      case AssistantQuickActionType.command:
        // For future extension; currently treat as message.
        _handleSubmit(action.payload);
        break;
    }
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map(
              (suggestion) => ActionChip(
                label: Text(suggestion),
                onPressed: () => onSelected(suggestion),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({
    required this.actions,
    required this.onActionSelected,
  });

  final List<AssistantQuickAction> actions;
  final ValueChanged<AssistantQuickAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions
            .map(
              (action) => OutlinedButton.icon(
                onPressed: () => onActionSelected(action),
                icon: Icon(_iconForAction(action.type)),
                label: Text(action.label),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  IconData _iconForAction(AssistantQuickActionType type) {
    switch (type) {
      case AssistantQuickActionType.navigation:
        return Icons.open_in_new;
      case AssistantQuickActionType.command:
        return Icons.auto_awesome;
      case AssistantQuickActionType.message:
        return Icons.chat_bubble_outline;
    }
  }
}
