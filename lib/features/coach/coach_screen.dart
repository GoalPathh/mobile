import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../shared/app_widgets.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _message = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _messages = [];
  String? _sessionId;
  String? _error;
  var _loading = true;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _message.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.get('/coach/sessions');
      final sessions = (result as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final selected = sessions.isEmpty
          ? null
          : sessions.first['id']?.toString();
      final messages = selected == null
          ? <Map<String, dynamic>>[]
          : await _fetchMessages(selected);
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _sessionId = selected;
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMessages(String sessionId) async {
    final result = await widget.api.get('/coach/sessions/$sessionId/messages');
    return (result as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _selectSession(String? id) async {
    if (id == null) return;
    setState(() {
      _sessionId = id;
      _loading = true;
      _error = null;
    });
    try {
      final messages = await _fetchMessages(id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _createSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.request(
        '/coach/sessions',
        method: 'POST',
        body: {'title': 'GoalPath Coach'},
      );
      if (result is! Map || result['id'] == null) {
        throw const ApiException('Sesi Coach tidak dapat dibuat.');
      }
      final session = Map<String, dynamic>.from(result);
      if (!mounted) return;
      setState(() {
        _sessions = [session, ..._sessions];
        _sessionId = session['id'].toString();
        _messages = [];
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final content = _message.text.trim();
    final sessionId = _sessionId;
    if (content.isEmpty || sessionId == null || _sending) return;

    _message.clear();
    setState(() => _sending = true);
    try {
      await widget.api.request(
        '/coach/sessions/$sessionId/messages',
        method: 'POST',
        body: {'role': 'user', 'content': content},
      );
      final messages = await _fetchMessages(sessionId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _error = null;
      });
      _scrollToBottom();
    } on Object catch (error) {
      if (!mounted) return;
      _message.text = content;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPanel(label: 'Memuat sesi Coach…');
    if (_error != null && _sessions.isEmpty) {
      return ErrorPanel(message: _error!, onRetry: _loadSessions);
    }
    if (_sessions.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const EmptyPanel(
            title: 'Mulai percakapan',
            message: 'Tanyakan tentang kebiasaan atau tujuan yang sedang kamu bangun.',
            icon: Icons.chat_bubble_outline,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _createSession,
            icon: const Icon(Icons.add),
            label: const Text('Buat sesi Coach'),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_sessions.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _sessionId,
              decoration: const InputDecoration(
                labelText: 'Sesi percakapan',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              items: _sessions.map((session) {
                final id = session['id']?.toString() ?? '';
                return DropdownMenuItem(
                  value: id,
                  child: Text(
                    session['title']?.toString() ?? 'Coach',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _selectSession,
            ),
          ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Ceritakan tujuan atau kebiasaan yang ingin kamu bangun.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';
                    final alignment = isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft;
                    final color = isUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface;
                    final textColor = isUser
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface;
                    return Align(
                      alignment: alignment,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          border: isUser
                              ? null
                              : Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message['content']?.toString() ?? '',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _message,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan…',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Kirim pesan',
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
