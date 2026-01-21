import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Screens
import 'package:friendify/src/features/swipe/presentation/pages/swipe_page.dart';
import 'package:friendify/src/features/game/presentation/pages/firefly_game_page.dart';
import 'package:friendify/src/features/matches/presentation/pages/recent_matches_page.dart';
import 'package:friendify/src/features/chat/presentation/pages/chat_list_page.dart';
import 'package:friendify/src/features/profile/presentation/pages/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // The 5 Main Tabs
  final List<Widget> _pages = const [
    SwipePage(),            // 0. Swipe (Left)
    FireflyGamePage(),      // 1. Game
    RecentMatchesPage(),    // 2. Matches
    ChatListPage(),         // 3. Chats
    ProfilePage(),          // 4. Profile (Right)
  ];

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
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white.withOpacity(0.8), 
          type: BottomNavigationBarType.fixed, 
          selectedItemColor: Colors.black, 
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false, 
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.style), // Cards/Swipe
              label: 'Swipe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bug_report), // Firefly Game
              label: 'Game',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu), // Recent Matches
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), // Chats
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), // Profile
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
