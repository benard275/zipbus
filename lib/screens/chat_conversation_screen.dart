import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/agent.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../widgets/theme_selector.dart';
import '../widgets/delivery_tick_widget.dart';

class ChatConversationScreen extends StatefulWidget {
  final Agent currentUser;
  final Conversation conversation;

  const ChatConversationScreen({
    super.key,
    required this.currentUser,
    required this.conversation,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _deliveryStatusTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    _startDeliveryStatusTimer();
  }

  void _startDeliveryStatusTimer() {
    // Check for delivery status updates every 3 seconds
    _deliveryStatusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshDeliveryStatus();
    });
  }

  Future<void> _refreshDeliveryStatus() async {
    if (_messages.isEmpty) return;

    try {
      final messageIds = _messages.map((m) => m.id).toList();
      final updatedMessages = await _databaseService.getUpdatedMessages(
        widget.conversation.id,
        messageIds,
      );

      // Update messages with new delivery status
      bool hasUpdates = false;
      for (int i = 0; i < _messages.length; i++) {
        final updatedMessage = updatedMessages.firstWhere(
          (m) => m.id == _messages[i].id,
          orElse: () => _messages[i],
        );

        if (_messages[i].deliveryStatus != updatedMessage.deliveryStatus) {
          _messages[i] = updatedMessage;
          hasUpdates = true;
        }
      }

      if (hasUpdates && mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle errors - not critical
      debugPrint('Error refreshing delivery status: $e');
    }
  }

  @override
  void dispose() {
    _deliveryStatusTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final messages = await _databaseService.getConversationMessages(
        widget.conversation.id,
        limit: 100,
      );
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _databaseService.markMessagesAsRead(
        widget.conversation.id,
        widget.currentUser.id,
      );
    } catch (e) {
      // Silently handle error - not critical
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final otherParticipantId = widget.conversation.getOtherParticipantId(widget.currentUser.id);
      final otherParticipantName = widget.conversation.getOtherParticipantName(widget.currentUser.id);

      final message = await _databaseService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.name,
        receiverId: otherParticipantId,
        receiverName: otherParticipantName,
        messageText: messageText,
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  String _formatMessageTime(String sentAt) {
    try {
      final messageTime = DateTime.parse(sentAt);
      final now = DateTime.now();
      final difference = now.difference(messageTime);
      
      if (difference.inDays > 0) {
        return '${messageTime.day}/${messageTime.month} ${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherParticipantName = widget.conversation.getOtherParticipantName(widget.currentUser.id);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(otherParticipantName),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMyMessage = message.senderId == widget.currentUser.id;
        
        return _buildMessageBubble(message, isMyMessage);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: Text(
                message.senderName.isNotEmpty 
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMyMessage 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: !isMyMessage
                    ? Border.all(color: Colors.grey.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.messageText,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : null,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.sentAt),
                        style: TextStyle(
                          color: isMyMessage
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isMyMessage) ...[
                        const SizedBox(width: 4),
                        AnimatedDeliveryTickWidget(
                          deliveryStatus: message.deliveryStatus,
                          size: 12,
                          sentColor: Colors.white.withValues(alpha: 0.7),
                          deliveredColor: Colors.white.withValues(alpha: 0.7),
                          readColor: Colors.lightBlue[200],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                message.senderName.isNotEmpty 
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
