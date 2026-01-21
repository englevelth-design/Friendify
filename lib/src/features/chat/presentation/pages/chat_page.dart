import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/auth/presentation/widgets/neon_text_field.dart';

class ChatPage extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ChatPage({
    super.key, 
    required this.targetUserId,
    required this.targetUserName
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

        // Removed .order() from stream definition to avoid potential SDK bugs. 
        // We will sort client-side in the map function.
        .map((maps) {
           debugPrint("STREAM RECEIVED: ${maps.length} messages");
           
           final filtered = maps.where((msg) {
              final sender = msg['sender_id'];
              final receiver = msg['receiver_id'];
              return (sender == _myId && receiver == widget.targetUserId) ||
                     (sender == widget.targetUserId && receiver == _myId);
            }).toList();
            
            // Sort by Created At (Descending / Newest First)
            filtered.sort((a, b) {
              final aTime = DateTime.parse(a['created_at']);
              final bTime = DateTime.parse(b['created_at']);
              return bTime.compareTo(aTime); // b - a = Descending
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

      // Production Mode: No auto-replies.
      // Messages are only sent by real humans now.

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.targetUserName),
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
                  return const Center(child: Text("Say Hello! 👋", style: TextStyle(color: Colors.white54)));
                }
                
                return ListView.builder(
                  reverse: true, // Newest at bottom visually
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
                          // Me: Neon, Other: Light Grey
                          color: isMe ? const Color(0xFFD4FF00) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          msg['content'],
                          style: TextStyle(
                            color: Colors.black, // Always black text for readability
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
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
                  icon: const Icon(Icons.send, color: Colors.black), // Black send icon
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
