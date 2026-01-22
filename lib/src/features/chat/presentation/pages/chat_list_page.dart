import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/core/services/match_service.dart';
import 'package:friendify/src/features/chat/presentation/widgets/chat_notification_service.dart'; // Import Tracker
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final MatchService _matchService = MatchService();
  List<Map<String, dynamic>> _newMatches = [];
  List<Map<String, dynamic>> _activeChats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
    _setupRealtimeSubscription();
  }
  
  // Dispose removed because we don't manage tracker here anymore (IndexStack keeps it alive)


  void _setupRealtimeSubscription() {
    // Listen for ANY new messages to refresh the list orders/unread counts
    Supabase.instance.client.channel('public:messages').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        if (mounted) _loadMatches();
      },
    ).subscribe();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _matchService.getMatches();
      final myId = Supabase.instance.client.auth.currentUser!.id;
      
      final List<Map<String, dynamic>> newMatches = [];
      final List<Map<String, dynamic>> activeChats = [];

      // Fetch last message for each match to sort them
      await Future.wait(matches.map((match) async {
        final matchId = match['id'];
        
        final res = await Supabase.instance.client
            .from('messages')
            .select()
            .or('and(sender_id.eq.$myId,receiver_id.eq.$matchId),and(sender_id.eq.$matchId,receiver_id.eq.$myId)')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
            
        if (res == null) {
          newMatches.add(match);
        } else {
          // It's an active chat, inject last message info
          final updatedMatch = Map<String, dynamic>.from(match);
          updatedMatch['last_message'] = res['content'];
          updatedMatch['last_time'] = res['created_at'];
          updatedMatch['last_msg_is_read'] = res['is_read'] ?? true; 
          updatedMatch['last_msg_sender'] = res['sender_id'];
          activeChats.add(updatedMatch);
        }
      }));

      // Sort chats by time
      activeChats.sort((a, b) {
        final tA = DateTime.tryParse(a['last_time'] ?? '') ?? DateTime(0);
        final tB = DateTime.tryParse(b['last_time'] ?? '') ?? DateTime(0);
        return tB.compareTo(tA); 
      });

      if (mounted) {
        setState(() {
          _newMatches = newMatches;
          _activeChats = activeChats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading chats: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GLOWING HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chats",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD4FF00), 
                      shadows: [
                        BoxShadow(
                          color: const Color(0xFFD4FF00).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.black54, size: 28),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. NEW FIREFLY FRIENDS (Horizontal Scroll)
                      // Only show if there ARE new matches
                      if (_newMatches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              const Text(
                                "New Firefly Friends",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4FF00),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4FF00).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${_newMatches.length}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _newMatches.length,
                            itemBuilder: (context, index) {
                              return _buildNewMatchItem(_newMatches[index], false);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 3. MESSAGES LIST
                      if (_activeChats.isNotEmpty)
                      if (_activeChats.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              ..._activeChats.asMap().entries.map((entry) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      // UNREAD LOGIC: If I am receiver AND it is NOT read -> Darker Neon Green
                                      color: _isUnread(entry.value)
                                         ? const Color(0xFFB2FF00) // Darker Neon Green for Unread
                                         : const Color(0xFFF1FFAB).withOpacity(0.6), // Standard Lime Glass
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _isUnread(entry.value) ? Colors.black26 : Colors.white, 
                                        width: _isUnread(entry.value) ? 0 : 1
                                      ),
                                    ),
                                    child: _buildMessageTile(entry.value, entry.key),
                                  );
                              }), 
                               const SizedBox(height: 100), 
                            ],
                          ),
                        )
                      else if (_newMatches.isEmpty) // Truly empty state
                         _buildEmptyState()
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      heightFactor: 4, // Center vertically roughly
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 60, color: Colors.black12),
          const SizedBox(height: 16),
          const Text("No Matches Yet", style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildNewMatchItem(Map<String, dynamic>? profile, bool isAdd) {
    if (isAdd) {
      return Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.favorite, color: Color(0xFFD4FF00)),
            ),
            const SizedBox(height: 8),
            const Text("Likes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final imageUrl = (profile!['image_urls'] as List?)?.firstOrNull;
    return GestureDetector(
      onTap: () => _openChat(profile),
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4FF00), width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4FF00).withOpacity(0.3), blurRadius: 10)
                ]
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                backgroundColor: Colors.grey[200],
                child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile['name'] ?? 'User',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(Map<String, dynamic> profile, int index) {
    final imageUrl = (profile['image_urls'] as List?)?.firstOrNull;
    final lastMessage = profile['last_message'] ?? "Start a conversation...";
    final lastTimeStr = profile['last_time'];
    String timeDisplay = "Now";
    
    if (lastTimeStr != null) {
      final t = DateTime.parse(lastTimeStr);
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 60) {
        timeDisplay = "${diff.inMinutes}m";
      } else if (diff.inHours < 24) {
        timeDisplay = "${diff.inHours}h";
      } else {
        timeDisplay = "${diff.inDays}d";
      }
    }

    final isUnread = _isUnread(profile);

    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onTap: () => _openChat(profile),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            backgroundColor: Colors.grey[200],
            child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
        ],
      ),
      title: Text(
        profile['name'] ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
      ),
      subtitle: Text(
        isUnread ? "New Message" : lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: lastMessage == "Start a conversation..." 
              ? Colors.black54 
              : Colors.black87,
          fontWeight: (isUnread || lastMessage != "Start a conversation...") 
              ? FontWeight.bold // Bold if unread or active
              : FontWeight.normal 
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min, // Fix Overflow
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeDisplay, style: const TextStyle(color: Colors.black45, fontSize: 12)),
          // Removing the unread dot for now until we track read status
        ],
      ),
    );
  }

  bool _isUnread(Map<String, dynamic> profile) {
    // It is unread IF: 
    // 1. The last message sender is NOT me (i.e. it's them)
    // 2. The is_read flag is false
    final myId = Supabase.instance.client.auth.currentUser!.id;
    final lastMsgSender = profile['last_msg_sender'];
    final isRead = profile['last_msg_is_read'] as bool? ?? true;
    
    return (lastMsgSender != myId && !isRead);
  }

  void _openChat(Map<String, dynamic> profile) {
     final imageUrl = (profile['image_urls'] as List?)?.firstOrNull;
     Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          targetUserId: profile['id'],
          targetUserName: profile['name'] ?? 'Firefly',
          targetUserImage: imageUrl,
        ),
      ),
    ).then((_) {
      // Refresh list when returning from chat (to clear unread status)
      _loadMatches();
    });
  }
}
