import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class SupabaseProfileService {
  Future<List<Profile>> getProfiles() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return [];

    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .neq('id', currentUser.id) // Don't show myself
        .limit(20); // Initial batch

    final List<dynamic> data = response;
    return data.map((json) => Profile(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      age: json['age'] ?? 0,
      bio: json['bio'] ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      distanceKm: 0, // Todo: Calculate real distance with PostGIS
    )).toList();
  }
}
