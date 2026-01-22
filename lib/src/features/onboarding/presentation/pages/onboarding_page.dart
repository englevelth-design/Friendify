import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:friendify/src/features/auth/presentation/widgets/neon_text_field.dart';
import 'package:friendify/src/features/profile/presentation/widgets/user_avatar.dart';
import 'package:friendify/src/core/data/interests_data.dart';
import 'package:friendify/src/features/home/presentation/pages/main_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form Data
  String? _imageUrl;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final Set<String> _selectedInterests = {};

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (_nameController.text.isEmpty || _ageController.text.isEmpty || _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = {
        'id': userId,
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 18,
        'bio': _bioController.text.trim(),
        'image_urls': [_imageUrl], // Array of strings
        'interests': _selectedInterests.toList(),
        'profile_complete': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('profiles').upsert(updates);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine gradient progress based on page index
    double progress = (_currentPage + 1) / 5;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4FF00)),
                      minHeight: 6,
                    ),
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce validation
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildWelcomeStep(),
                      _buildPhotoStep(),
                      _buildInfoStep(),
                      _buildBioStep(),
                      _buildInterestsStep(),
                    ],
                  ),
                ),

                // Navigation Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        )
                      else
                        const SizedBox(width: 48), // Spacer

                      // Next / Finish Button
                      if (_currentPage < 4)
                         ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4FF00),
                            foregroundColor: Colors.black,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.arrow_forward),
                        )
                      else
                        ElevatedButton(
                          onPressed: _isLoading ? null : _completeOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4FF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                            shadowColor: const Color(0xFFD4FF00).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const Text(
                                  "Let's Go! 🚀",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Welcome Step
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.waving_hand, size: 80, color: Color(0xFFD4FF00)),
          const SizedBox(height: 32),
          Text(
            "Welcome to Friendify!",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Let's get your profile set up so you can start meeting new firefly friends.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Photo Step
  Widget _buildPhotoStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Show us your smile",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            "Upload your best photo to make a great first impression.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white60),
          ),
          const SizedBox(height: 48),
          UserAvatar(
            imageUrl: _imageUrl,
            onUpload: (url) => setState(() => _imageUrl = url),
          ),
          const SizedBox(height: 24),
          if (_imageUrl == null)
            Text(
              "Tap to upload",
              style: GoogleFonts.outfit(color: const Color(0xFFD4FF00), fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  // 3. Info Step
  Widget _buildInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Text(
            "The Basics",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 40),
          NeonTextField(
            controller: _nameController,
            label: "Your Name",
            icon: Icons.person,
            isDarkTheme: true,
          ),
          const SizedBox(height: 24),
          NeonTextField(
            controller: _ageController,
            label: "Your Age",
            icon: Icons.calendar_today,
            isNumber: true,
            isDarkTheme: true,
          ),
        ],
      ),
    );
  }

  // 4. Bio Step
  Widget _buildBioStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Text(
            "About You",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            "Write a short bio to tell others what you're all about.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.white60),
          ),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _bioController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "I love hiking, coffee, and...",
                hintStyle: TextStyle(color: Colors.white30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Interests Step
  Widget _buildInterestsStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, bottom: 20, left: 24, right: 24),
          child: Column(
            children: [
              Text(
                "Passions",
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "Select a few things you love.",
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white60),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: availableInterests.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  backgroundColor: Colors.white10,
                  selectedColor: const Color(0xFFD4FF00),
                  checkmarkColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFD4FF00) : Colors.white24,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
