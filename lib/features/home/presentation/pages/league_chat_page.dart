import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/core/presentation/widgets/web_constrained_box.dart';
import 'package:football_predictions/features/auth/data/repositories/auth_repository.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class LeagueChatPage extends StatefulWidget {
  final String leagueId;

  const LeagueChatPage({super.key, required this.leagueId});

  @override
  State<LeagueChatPage> createState() => _LeagueChatPageState();
}

class _LeagueChatPageState extends State<LeagueChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingMessage = false;
  String? _currentUserId;

  // Estado para Paginação Híbrida (Stream + Lazy Loading)
  List<DocumentSnapshot> _historyMessages = [];
  List<DocumentSnapshot> _newMessages = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  StreamSubscription? _streamSubscription;
  static const int _limit = 20;
  bool _showScrollToBottom = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<AuthRepository>().getUser().then((u) {
      if (mounted) setState(() => _currentUserId = u.id);
    });
    _loadInitialMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Lógica de Paginação (Carregar mais antigos)
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }

    // Lógica do Botão "Voltar ao Final"
    // Mostra o botão se rolar mais de 300 pixels para cima
    final show = _scrollController.offset > 300;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('leagues')
          .doc(widget.leagueId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(_limit);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _historyMessages = snapshot.docs;
          _isInitialLoading = false;
          if (snapshot.docs.length < _limit) _hasMore = false;
        });
        _setupRealtimeListener();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  void _setupRealtimeListener() {
    var query = FirebaseFirestore.instance
        .collection('leagues')
        .doc(widget.leagueId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    if (_historyMessages.isNotEmpty) {
      // Escuta apenas mensagens mais novas que a mais recente do histórico
      query = query.endBeforeDocument(_historyMessages.first);
    }

    _streamSubscription = query.snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          // Se o usuário não está no final e a lista cresceu, incrementa contador
          if (_showScrollToBottom &&
              snapshot.docs.length > _newMessages.length) {
            _unreadCount += (snapshot.docs.length - _newMessages.length);
          }
          _newMessages = snapshot.docs;
        });
      }
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMore || _historyMessages.isEmpty) return;

    setState(() => _isLoadingMore = true);

    try {
      final query = FirebaseFirestore.instance
          .collection('leagues')
          .doc(widget.leagueId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_historyMessages.last)
          .limit(_limit);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _historyMessages.addAll(snapshot.docs);
          if (snapshot.docs.length < _limit) _hasMore = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      // Reseta o contador ao voltar para o final
      setState(() => _unreadCount = 0);
    }
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      await context.read<LeaguesRepository>().sendMessage(
        widget.leagueId,
        text,
      );

      if (mounted) {
        _chatController.clear();
        // Rola para o final (início da lista invertida)
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat da Liga'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpg',
              fit: BoxFit.fill,
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    ),
                  ),
                );
              },
            ),
          ),
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _isInitialLoading
                          ? const LoadingWidget()
                          : (_historyMessages.isEmpty && _newMessages.isEmpty)
                          ? Center(
                              child: WebConstrainedBox(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Seja o primeiro a falar!',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.all(16),
                              // +1 para o loader se tiver mais
                              itemCount:
                                  _newMessages.length +
                                  _historyMessages.length +
                                  (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index ==
                                    _newMessages.length +
                                        _historyMessages.length) {
                                  return const WebConstrainedBox(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: LoadingWidget(size: 20),
                                      ),
                                    ),
                                  );
                                }

                                final doc = index < _newMessages.length
                                    ? _newMessages[index]
                                    : _historyMessages[index -
                                          _newMessages.length];

                                final currentDate = _getDate(doc);
                                bool showHeader = false;
                                final nextIndex = index + 1;
                                final totalMessages =
                                    _newMessages.length +
                                    _historyMessages.length;

                                if (nextIndex >= totalMessages) {
                                  showHeader = true;
                                } else {
                                  final nextDoc =
                                      nextIndex < _newMessages.length
                                      ? _newMessages[nextIndex]
                                      : _historyMessages[nextIndex -
                                            _newMessages.length];
                                  final nextDate = _getDate(nextDoc);
                                  showHeader = !_isSameDay(
                                    currentDate,
                                    nextDate,
                                  );
                                }

                                final data = doc.data() as Map<String, dynamic>;
                                final type = data['type'] as String? ?? 'user';
                                final isMe = data['userId'] == _currentUserId;

                                final messageWidget = type == 'system'
                                    ? _buildSystemMessage(data)
                                    : _buildChatBubble(data, isMe);

                                if (showHeader) {
                                  return WebConstrainedBox(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildDateHeader(currentDate),
                                        messageWidget,
                                      ],
                                    ),
                                  );
                                }
                                return WebConstrainedBox(child: messageWidget);
                              },
                            ),
                    ),
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton.small(
                            backgroundColor: const Color(0xFF1B5E20),
                            foregroundColor: Colors.white,
                            onPressed: _scrollToBottom,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.keyboard_arrow_down),
                                if (_unreadCount > 0)
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _unreadCount > 99
                                            ? '99+'
                                            : '$_unreadCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              WebConstrainedBox(child: _buildChatInput()),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _getDate(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    return timestamp?.toDate() ?? DateTime.now();
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    String text;
    if (dateToCheck == today) {
      text = 'Hoje';
    } else if (dateToCheck == yesterday) {
      text = 'Ontem';
    } else {
      text =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemMessage(Map<String, dynamic> data) {
    final message = data['text'] ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> data, bool isMe) {
    final message = data['text'] ?? '';
    final userName = data['userName'] ?? 'Usuário';
    final userPhoto = data['userPhoto'];
    final timestamp = data['createdAt'] as Timestamp?;
    final timeString = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            SizedBox(
              width: 32,
              height: 32,
              child: ClipOval(
                child: userPhoto != null
                    ? AppNetworkImage(
                        url: userPhoto,
                        fit: BoxFit.cover,
                        errorWidget: CircleAvatar(
                          radius: 16,
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 16,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: !isMe
                    ? Border.all(color: Colors.white.withOpacity(0.1))
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMe) const SizedBox(width: 24),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                                    .withOpacity(0.7)
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                enabled: !_isSendingMessage,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSendingMessage ? null : _sendMessage,
              icon: _isSendingMessage
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
