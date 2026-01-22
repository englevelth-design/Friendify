import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/auth/presentation/widgets/neon_text_field.dart';
import 'package:friendify/src/features/profile/presentation/pages/profile_page.dart';
import 'package:friendify/src/features/chat/presentation/widgets/chat_notification_service.dart';
import 'package:friendify/main.dart'; // import for routeObserver access if public, or move routeObserver to separate file?
// Actually routeObserver is in ChatNotificationService file or main? 
// In previous step I put it in ChatNotificationService file as global val. Let's import that file.

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

class _ChatPageState extends State<ChatPage> with RouteAware { // Add RouteAware
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final _myId = Supabase.instance.client.auth.currentUser!.id;

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

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.targetUserId,
        'content': text,
        'is_read': false, // Default, but good to be explicit
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }

  String _formatTime(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            // Navigate to Profile Viewer
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.targetUserId)),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.targetUserImage != null 
                  ? NetworkImage(widget.targetUserImage!) 
                  : null,
                backgroundColor: Colors.grey[200],
                radius: 20,
                child: widget.targetUserImage == null 
                  ? const Icon(Icons.person, color: Colors.grey) 
                  : null,
              ),
              const SizedBox(width: 12),
              Text(widget.targetUserName),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          // Me: Neon, Other: White (requested)
                          color: isMe ? const Color(0xFFD4FF00) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isMe ? null : [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, spreadRadius: 1)
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
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
                    );
                  },
                );
              },
            ),
          ),
          // SAFE AREA for Input Field to avoid overlap with bottom nav
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: NeonTextField(
                      controller: _messageController,
                      label: "Type a message...",
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.black), 
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
