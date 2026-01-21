import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/auth/presentation/widgets/neon_text_field.dart';
import 'package:friendify/src/features/profile/presentation/pages/profile_page.dart';

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

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  final _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
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
