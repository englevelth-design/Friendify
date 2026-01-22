import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'package:friendify/src/features/swipe/presentation/pages/swipe_page.dart';
import 'package:friendify/src/features/game/presentation/pages/firefly_game_page.dart';
import 'package:friendify/src/features/matches/presentation/pages/recent_matches_page.dart';
import 'package:friendify/src/features/chat/presentation/pages/chat_list_page.dart';
import 'package:friendify/src/features/profile/presentation/pages/profile_page.dart';
import 'package:friendify/src/features/chat/presentation/widgets/chat_notification_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _hasUnreadMessages = false;
  RealtimeChannel? _unreadChannel;

  // The 5 Main Tabs
  final List<Widget> _pages = const [
    SwipePage(),            // 0. Swipe (Left)
    FireflyGamePage(),      // 1. Game
    RecentMatchesPage(),    // 2. Matches
    ChatListPage(),         // 3. Chats
    ProfilePage(),          // 4. Profile (Right)
  ];

  @override
  void initState() {
    super.initState();
    ChatPageTracker.isChatListActive = (_currentIndex == 3);
    _checkUnreadMessages();
    _setupUnreadListener();
  }
  
  @override
  void dispose() {
    _unreadChannel?.unsubscribe();
    super.dispose();
  }
  
  Future<void> _checkUnreadMessages() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;
    
    try {
      final result = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('receiver_id', myId)
          .eq('is_read', false)
          .limit(1);
      
      if (mounted) {
        setState(() => _hasUnreadMessages = (result as List).isNotEmpty);
      }
    } catch (e) {
      // Silent error
    }
  }
  
  void _setupUnreadListener() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;
    
    _unreadChannel = Supabase.instance.client.channel('main_unread_indicator');
    _unreadChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        // Re-check unread status on any message change
        _checkUnreadMessages();
      },
    ).subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // We use IndexedStack so the state of each tab (like scroll position) is preserved.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
           canvasColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Update Notification Tracker (Index 3 is Chat List)
            ChatPageTracker.isChatListActive = (index == 3);
            // Clear unread indicator when viewing chats
            if (index == 3) {
              setState(() => _hasUnreadMessages = false);
            }
          },
          backgroundColor: Colors.white.withOpacity(0.8), 
          type: BottomNavigationBarType.fixed, 
          selectedItemColor: Colors.black, 
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.style), // Cards/Swipe
              label: 'Swipe',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bug_report), // Firefly Game
              label: 'Game',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history_edu), // Recent Matches
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  if (_hasUnreadMessages)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4FF00), // Neon bright green
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Chat',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), // Profile
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
