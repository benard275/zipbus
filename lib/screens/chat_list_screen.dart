import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../models/conversation.dart';
import '../services/database_service.dart';
import '../widgets/theme_selector.dart';
import 'chat_conversation_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final Agent currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Conversation> _conversations = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    
    try {
      final conversations = await _databaseService.getUserConversations(widget.currentUser.id);
      final Map<String, int> unreadCounts = {};
      
      // Get unread count for each conversation
      for (final conversation in conversations) {
        final count = await _databaseService.getConversationUnreadCount(
          conversation.id, 
          widget.currentUser.id
        );
        unreadCounts[conversation.id] = count;
      }
      
      setState(() {
        _conversations = conversations;
        _unreadCounts = unreadCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversations: $e')),
        );
      }
    }
  }

  Future<void> _startNewChat() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewChatScreen(currentUser: widget.currentUser),
      ),
    );
    
    if (result == true) {
      _loadConversations(); // Refresh the list
    }
  }

  String _formatLastMessageTime(String? lastMessageTime) {
    if (lastMessageTime == null) return '';
    
    try {
      final messageTime = DateTime.parse(lastMessageTime);
      final now = DateTime.now();
      final difference = now.difference(messageTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: const Icon(Icons.add),
        tooltip: 'New Message',
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
            'No conversations yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new conversation by tapping the + button',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          final otherParticipantName = conversation.getOtherParticipantName(widget.currentUser.id);
          final unreadCount = _unreadCounts[conversation.id] ?? 0;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  otherParticipantName.isNotEmpty 
                      ? otherParticipantName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                otherParticipantName,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                conversation.lastMessageText ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  color: unreadCount > 0 ? null : Colors.grey[600],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatLastMessageTime(conversation.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
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
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatConversationScreen(
                      currentUser: widget.currentUser,
                      conversation: conversation,
                    ),
                  ),
                );
                
                if (result == true) {
                  _loadConversations(); // Refresh to update unread counts
                }
              },
            ),
          );
        },
      ),
    );
  }
}
