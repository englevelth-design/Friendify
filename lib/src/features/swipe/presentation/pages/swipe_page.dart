import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:friendify/src/core/models/profile.dart';
import 'package:friendify/src/features/swipe/presentation/widgets/profile_card.dart';
import 'package:friendify/src/features/profile/presentation/pages/profile_page.dart';
import 'package:friendify/src/features/chat/presentation/pages/chat_list_page.dart';

import 'package:friendify/src/core/services/supabase_profile_service.dart';
import 'package:friendify/src/core/services/match_service.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  final CardSwiperController controller = CardSwiperController();
  final SupabaseProfileService _service = SupabaseProfileService();
  final MatchService _matchService = MatchService();
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _service.getProfiles();
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint('The card $previousIndex was swiped to the ${direction.name}. Now $currentIndex');
    
    if (direction == CardSwiperDirection.right) {
       final likedProfile = _profiles[previousIndex];
       _matchService.recordLike(likedProfile.id);
       
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text("You liked ${likedProfile.name}!"), 
           duration: const Duration(milliseconds: 500),
           backgroundColor: const Color(0xFFD4FF00),
           behavior: SnackBarBehavior.floating,
         )
       );
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profiles.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No more profiles!")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Friendify"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF38BDF8)), // Moonlight Blue
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatListPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFD4FF00)),
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: CardSwiper(
                controller: controller,
                cardsCount: _profiles.length,
                onSwipe: _onSwipe,
                numberOfCardsDisplayed: 3,
                backCardOffset: const Offset(40, 40),
                padding: const EdgeInsets.all(24.0),
                cardBuilder: (context, index, horizontalOffset, verticalOffset) {
                  return ProfileCard(profile: _profiles[index]);
                },
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "dislike",
                    onPressed: () => controller.swipe(CardSwiperDirection.left),
                    backgroundColor: const Color(0xFF1E293B), // Dark Slate
                    foregroundColor: Colors.white54,
                    child: const Icon(Icons.close),
                  ),
                  FloatingActionButton(
                    heroTag: "like",
                    onPressed: () => controller.swipe(CardSwiperDirection.right),
                    backgroundColor: const Color(0xFFD4FF00), // Firefly Glow
                    foregroundColor: Colors.black, // High contrast on neon
                    child: const Icon(Icons.favorite),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
