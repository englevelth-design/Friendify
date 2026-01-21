import 'package:flutter/material.dart';
import 'package:friendify/src/core/services/match_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final MatchService _matchService = MatchService();
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await _matchService.getMatches();
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading matches: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Firefly Chat"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 60, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text("No Matches Yet", style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadMatches, 
                        child: const Text("Refresh", style: TextStyle(color: Color(0xFFD4FF00)))
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final profile = _matches[index];
                    final imageUrl = (profile['image_urls'] as List?)?.isNotEmpty == true 
                        ? profile['image_urls'][0] 
                        : null;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        backgroundColor: Colors.grey[800],
                        child: imageUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(profile['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                      subtitle: const Text("Start a conversation...", style: TextStyle(color: Colors.white54)),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              targetUserId: profile['id'],
                              targetUserName: profile['name'] ?? 'Firefly',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
