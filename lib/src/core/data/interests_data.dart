/// Themed categories of interests/hobbies for user profile selection
const Map<String, List<String>> themedInterests = {
  '🎨 Creative': [
    'Art',
    'Photography',
    'Writing',
    'Music',
    'Dancing',
    'Theatre',
  ],
  '🏃 Active': [
    'Fitness',
    'Sports',
    'Yoga',
    'Outdoors',
    'Adventure',
    'Hiking',
  ],
  '🎉 Social': [
    'Nightlife',
    'Live Music',
    'Coffee Dates',
    'Foodie',
    'Travel',
    'Parties',
  ],
  '🎮 Entertainment': [
    'Gaming',
    'Movies',
    'Netflix',
    'Anime',
    'Reading',
    'Podcasts',
  ],
  '💼 Lifestyle': [
    'Fashion',
    'Technology',
    'Cooking',
    'Pets',
    'Nature',
    'Wellness',
  ],
};

/// Maximum number of interests a user can select
const int maxInterestsAllowed = 5;

/// Flat list of all interests (for backward compatibility)
List<String> get availableInterests => 
    themedInterests.values.expand((list) => list).toList();
