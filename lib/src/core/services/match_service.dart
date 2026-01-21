import 'package:supabase_flutter/supabase_flutter.dart';

class MatchService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> recordLike(String targetUserId) async {
    final myId = _client.auth.currentUser!.id;

    // 1. Record the Like
    try {
      await _client.from('matches').insert({
        'user_id': myId,
        'match_user_id': targetUserId,
      });
    } catch (e) {
      // Ignore duplicate likes (unique constraint)
    }

    // 2. Check for Mutual Match
    // If they also liked me, we have a match!
    final response = await _client
        .from('matches')
        .select()
        .eq('user_id', targetUserId) // They are the liker
        .eq('match_user_id', myId)   // I am the target
        .maybeSingle();

    if (response != null) {
      // IT'S A MATCH!
      print("IT'S A MATCH! User $targetUserId also likes you.");
    }
  }

  Future<List<Map<String, dynamic>>> getMatches() async {
    final myId = _client.auth.currentUser!.id;

    // 1. Get everyone I liked
    final myLikesResponse = await _client
        .from('matches')
        .select('match_user_id')
        .eq('user_id', myId);
    
    final myLikes = (myLikesResponse as List).map((e) => e['match_user_id'] as String).toList();

    if (myLikes.isEmpty) return [];

    // 2. See which of them liked me back
    // Note: We use !matches_user_id_fkey to specify which Foreign Key to use 
    // (since matches has TWO links to profiles: user_id and match_user_id).
    final mutualMatchesResponse = await _client
        .from('matches')
        .select('user_id, profiles!matches_user_id_fkey(*)')
        .eq('match_user_id', myId)
        .filter('user_id', 'in', myLikes);

    // 3. Extract profile data
    return (mutualMatchesResponse as List).map((e) => e['profiles'] as Map<String, dynamic>).toList();
  }
}
