class Profile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> imageUrls;
  final List<String> interests;
  final String? gender;
  final String? interestedIn;
  final double distanceKm;

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrls,
    required this.interests,
    this.gender,
    this.interestedIn,
    this.distanceKm = 0.0,
  });

  // Factory for mock data
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      bio: json['bio'] as String? ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      gender: json['gender'] as String?,
      interestedIn: json['interested_in'] as String?,
      distanceKm: (json['distance_km'] ?? 0).toDouble(),
    );
  }
}
