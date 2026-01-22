import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/profile/presentation/pages/profile_page.dart';
import 'package:friendify/src/features/chat/presentation/widgets/chat_notification_service.dart';
import 'package:friendify/src/features/chat/presentation/widgets/chat_notification_service.dart';


class ChatPage extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String? targetUserImage; // New

  const ChatPage({
    super.key, 
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserImage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with RouteAware {
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final _myId = Supabase.instance.client.auth.currentUser!.id;
  
  // Reply state
  Map<String, dynamic>? _replyingToMessage;

  @override
  void didChangeDependencies() {
     super.didChangeDependencies();
     routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    // If we are leaving, clear the tracker IF it was us
    if (ChatPageTracker.activeChatUserId == widget.targetUserId) {
      ChatPageTracker.activeChatUserId = null;
    }
    super.dispose();
  }

  @override
  void didPush() {
    // When entered
    ChatPageTracker.activeChatUserId = widget.targetUserId;
    _markAsRead();
  }

  @override
  void didPopNext() {
    // When returning from another screen
    ChatPageTracker.activeChatUserId = widget.targetUserId;
    _markAsRead();
  }
  
  Future<void> _markAsRead() async {
    try {
      // Update all messages from THIS sender to ME as read
      await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .match({
            'sender_id': widget.targetUserId,
            'receiver_id': _myId,
            'is_read': false, // Optimization: only update unread ones
          });
    } catch (e) {
      // silent error
    }
  }

  @override
  void initState() {
    super.initState();
    // Also set active user here just in case, though didPush covers it
    // ChatPageTracker.activeChatUserId = widget.targetUserId; 
    
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((maps) {
           final filtered = maps.where((msg) {
              final sender = msg['sender_id'];
              final receiver = msg['receiver_id'];
              return (sender == _myId && receiver == widget.targetUserId) ||
                     (sender == widget.targetUserId && receiver == _myId);
            }).toList();
            
            filtered.sort((a, b) {
              final aTime = DateTime.parse(a['created_at']);
              final bTime = DateTime.parse(b['created_at']);
              return bTime.compareTo(aTime); 
            });
            
            // SIDE EFFECT: Mark as read if a new message comes in while we are here!
            // BUT: This stream fires for every change.
            // We should check if there are unread messages from them and mark them.
            // Better to do this carefully to avoid infinite loops if the "update" triggers the stream again.
            // .stream() listens to changes. If we update 'is_read', it triggers again.
            // Infinite loop risk? 
            // The Update changes 'is_read'. The Stream result contains 'is_read'.
            // Yes, risk.
            // Solution: 
            // 1. Only mark read if we find unread messages in the list.
            // 2. The update will trigger stream again, but this time 'is_read' will be true, so we won't update again.
            
            final unreads = filtered.where((m) => m['sender_id'] == widget.targetUserId && m['is_read'] == false).toList();
            if (unreads.isNotEmpty) {
               // Defer to next frame to avoid "setState during build" or similar issues if map is called during build
               Future.microtask(() => _markAsRead());
            }

            return filtered;
        });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    
    final replyToId = _replyingToMessage?['id'];
    
    // Clear reply state
    setState(() => _replyingToMessage = null);

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.targetUserId,
        'content': text,
        'is_read': false,
        if (replyToId != null) 'reply_to_id': replyToId,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }
  
  void _setReplyTo(Map<String, dynamic> message) {
    setState(() => _replyingToMessage = message);
  }
  
  void _cancelReply() {
    setState(() => _replyingToMessage = null);
  }
  
  String? _getReplyContent(String? replyToId, List<Map<String, dynamic>> messages) {
    if (replyToId == null) return null;
    final replyMsg = messages.where((m) => m['id'] == replyToId).firstOrNull;
    return replyMsg?['content'];
  }

  String _formatTime(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }
  
  bool _isSameDay(String t1, String t2) {
    final d1 = DateTime.parse(t1).toLocal();
    final d2 = DateTime.parse(t2).toLocal();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
  
  String _getDateHeader(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dt.year, dt.month, dt.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () {
            // Navigate to Profile Viewer - only when tapping avatar/name
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.targetUserId)),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  backgroundImage: widget.targetUserImage != null 
                    ? NetworkImage(widget.targetUserImage!) 
                    : null,
                  backgroundColor: Colors.grey[200],
                  radius: 16,
                  child: widget.targetUserImage == null 
                    ? const Icon(Icons.person, color: Colors.grey, size: 18) 
                    : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.targetUserName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 70,
        backgroundColor: const Color(0xFFD4E8B4), // Richer soft lime green
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text("Say Hello! 👋", style: TextStyle(color: Colors.black54)));
                }
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == _myId;
                    
                    // Date Header Logic
                    final nextMsg = index + 1 < messages.length ? messages[index + 1] : null;
                    bool showHeader = false;
                    
                    if (nextMsg == null) {
                      // Oldest message always gets a header
                      showHeader = true; 
                    } else {
                      // If the day changed compared to the older message
                      showHeader = !_isSameDay(msg['created_at'], nextMsg['created_at']);
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Because list is reversed, "Above" the message is visually "Before" it in the Column
                        // BUT in reverse list, item N is visually above item N-1 ?
                        // No. Item 0 is bottom. Item 1 is above it.
                        // We decided: Header of "Today" goes on the OLDEST message of Today.
                        // Wait. In reversed list:
                        // Msg A (14:00, Idx 0) -> Newest
                        // Msg B (13:00, Idx 1) -> Oldest (Last of Today group?)
                        // Msg C (Yesterday, Idx 2)
                        
                        // Logic: Compare Idx 1 (Msg B) with Idx 2 (Msg C). Different?
                        // Yes. So Msg B gets "Today" header.
                        // Where do we put it?
                        // Visually ABOVE Msg B.
                        // So in Column([Header, MsgB]).
                        if (showHeader) 
                          Padding(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             child: Center(
                               child: Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                 decoration: BoxDecoration(
                                   color: Colors.grey[200],
                                   borderRadius: BorderRadius.circular(12),
                                 ),
                                 child: Text(
                                   _getDateHeader(msg['created_at']),
                                   style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                                 ),
                               ),
                             ),
                          ),

                        // Swipe-to-reply wrapper
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            // Swipe right to reply
                            if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                              _setReplyTo(msg);
                            }
                          },
                          onLongPress: () {
                            // Long press to show reply menu
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.reply, color: Colors.black54),
                                      title: const Text('Reply'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _setReplyTo(msg);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.copy, color: Colors.black54),
                                      title: const Text('Copy'),
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        // TODO: Copy to clipboard
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Sender's avatar (only for their messages, not mine)
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: widget.targetUserImage != null
                                      ? NetworkImage(widget.targetUserImage!)
                                      : null,
                                  backgroundColor: Colors.grey[200],
                                  child: widget.targetUserImage == null
                                      ? const Icon(Icons.person, size: 16, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                              ],
                              
                              // Message bubble
                              Flexible(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? const Color(0xFFD4FF00) : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 20),
                                    ),
                                    boxShadow: isMe ? null : [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, spreadRadius: 1)
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Quoted reply message (if this is a reply)
                                      if (msg['reply_to_id'] != null)
                                        Builder(builder: (context) {
                                          final replyContent = _getReplyContent(msg['reply_to_id'], messages);
                                          if (replyContent == null) return const SizedBox.shrink();
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border(
                                                left: BorderSide(
                                                  color: isMe ? Colors.black54 : const Color(0xFFD4FF00),
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              replyContent,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.black.withOpacity(0.6),
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          );
                                        }),
                                      Text(
                                        msg['content'],
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(msg['created_at']),
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.5),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Reply preview bar (if replying)
          if (_replyingToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5C8),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4FF00),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _replyingToMessage!['sender_id'] == _myId ? 'Replying to yourself' : 'Replying to ${widget.targetUserName}',
                          style: const TextStyle(
                            color: Color(0xFF7CB342),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyingToMessage!['content'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // SAFE AREA for Input Field to avoid overlap with bottom nav
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: Colors.grey[600]),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
