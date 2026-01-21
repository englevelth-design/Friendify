import 'package:friendify/src/core/models/profile.dart';

class MockProfileService {
  Future<List<Profile>> getProfiles() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      const Profile(
        id: '1',
        name: 'Sarah',
        age: 24,
        bio: 'Adventure seeker & coffee lover. ☕️ Lets go hiking!',
        imageUrls: ['https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800'],
        interests: ['Hiking', 'Photography', 'Coffee'],
        distanceKm: 2.5,
      ),
      const Profile(
        id: '2',
        name: 'Mike',
        age: 28,
        bio: 'Tech enthusiast building the future. 🚀',
        imageUrls: ['https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800'],
        interests: ['Coding', 'Startups', 'Gaming'],
        distanceKm: 5.1,
      ),
      const Profile(
        id: '3',
        name: 'Jessica',
        age: 22,
        bio: 'Art student. I love visiting galleries and sketching.',
        imageUrls: ['https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800'],
        interests: ['Art', 'Museums', 'Sketching'],
        distanceKm: 1.2,
      ),
    ];
  }
}
