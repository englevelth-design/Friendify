import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  bool _isLoading = false;

  // Form Fields
  String? _imageUrl;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  // Date of Birth
  DateTime? _selectedDate;
  
  // Selections
  String? _selectedGender;
  String? _selectedInterestIn;
  String? _selectedEducation;
  String? _selectedFamily;
  String? _selectedPets;
  String? _selectedDrinking;
  String? _selectedSmoking;
  String? _selectedLookingFor;
  final Set<String> _selectedLanguages = {};
  final Set<String> _selectedInterests = {};

  // Options
  final List<String> _genders = ['Man', 'Woman', 'Other'];
  final List<String> _interestOptions = ['Men', 'Women', 'Everyone'];
  
  final List<String> _educationOptions = [
    'High School', 'Some College', 'Undergraduate', 'Graduate', 'PhD', 'Trade School'
  ];
  
  final List<String> _familyOptions = [
    'Want kids', 'Don\'t want kids', 'Have kids', 'Open to kids', 'Not sure yet'
  ];
  
  final List<String> _petOptions = [
    '🐶 Dog lover', '🐱 Cat lover', '🐾 All pets!', '🚫 No pets', '🤷 Allergic'
  ];
  
  final List<String> _drinkingOptions = [
    'Never', 'Socially', 'Regularly', 'Sober curious'
  ];
  
  final List<String> _smokingOptions = [
    'Never', 'Socially', 'Regularly', 'Trying to quit'
  ];
  
  final List<String> _languageOptions = [
    '🇬🇧 English', '🇹🇭 Thai', '🇨🇳 Chinese', '🇯🇵 Japanese', '🇰🇷 Korean', 
    '🇪🇸 Spanish', '🇫🇷 French', '🇩🇪 German', '🇷🇺 Russian', '🇮🇳 Hindi'
  ];
  
  final List<String> _lookingForOptions = [
    '💕 Long-term relationship',
    '🎉 Something casual',
    '👋 New friends',
    '🤔 Still figuring it out',
    '💬 Chat & see what happens',
  ];

  // Theme colors
  static const _primaryColor = Color(0xFFD4FF00);
  static const _darkText = Color(0xFF1E293B);
  static const _lightGrey = Color(0xFFF1F5F9);

  int get _calculatedAge {
    if (_selectedDate == null) return 18;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    if (now.month < _selectedDate!.month || 
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: _darkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _completeOnboarding() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Validation
    if (_nameController.text.isEmpty || 
        _selectedDate == null || 
        _selectedGender == null || 
        _selectedInterestIn == null ||
        _selectedLookingFor == null ||
        _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields (photo, name, birthday, identity, interests, and why you\'re here).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_calculatedAge < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be at least 18 years old.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = {
        'id': userId,
        'name': _nameController.text.trim(),
        'age': _calculatedAge,
        'bio': _bioController.text.trim(),
        'gender': _selectedGender,
        'interested_in': _selectedInterestIn,
        'education': _selectedEducation,
        'family_plans': _selectedFamily,
        'pets': _selectedPets,
        'drinking': _selectedDrinking,
        'smoking': _selectedSmoking,
        'languages': _selectedLanguages.toList(),
        'looking_for': _selectedLookingFor,
        'image_urls': [_imageUrl],
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
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/FF-Mini_Logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Tell us more about\nyourself.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _darkText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "We need a little information from you to help you connect with other Firefly Friends.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // --- Photo Upload ---
              Center(
                child: UserAvatar(
                  imageUrl: _imageUrl,
                  onUpload: (url) => setState(() => _imageUrl = url),
                  radius: 55,
                ),
              ),
              if (_imageUrl == null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Tap to upload photo *",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              const SizedBox(height: 28),

              // --- Name ---
              _buildSectionLabel("Name *"),
              const SizedBox(height: 8),
              NeonTextField(controller: _nameController, label: "Your name"),
              const SizedBox(height: 20),

              // --- Birthday ---
              _buildSectionLabel("Birthday *"),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: _lightGrey,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null 
                            ? "Select your birthday" 
                            : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                        style: GoogleFonts.outfit(
                          color: _selectedDate == null ? Colors.grey[500] : _darkText,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.calendar_today, color: Colors.grey[500], size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Identity (Gender) ---
              _buildSectionLabel("I identify as... *"),
              const SizedBox(height: 10),
              _buildChipRow(_genders, _selectedGender, (val) => setState(() => _selectedGender = val)),
              const SizedBox(height: 24),

              // --- Interested In ---
              _buildSectionLabel("I am interested in... *"),
              const SizedBox(height: 10),
              _buildChipRow(_interestOptions, _selectedInterestIn, (val) => setState(() => _selectedInterestIn = val)),
              const SizedBox(height: 24),

              // --- Why are you on Firefly? (MANDATORY) ---
              _buildSectionLabel("Why are you on Firefly Friends? *", icon: Icons.favorite),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _lookingForOptions.map((option) {
                  final isSelected = _selectedLookingFor == option;
                  return _buildSelectableChip(option, isSelected, () => setState(() => _selectedLookingFor = option));
                }).toList(),
              ),
              const SizedBox(height: 28),

              const Divider(height: 1),
              const SizedBox(height: 28),

              // --- Education ---
              _buildSectionLabel("Education", icon: Icons.school),
              const SizedBox(height: 10),
              _buildDropdown(_educationOptions, _selectedEducation, (val) => setState(() => _selectedEducation = val), "Select education level"),
              const SizedBox(height: 20),

              // --- Family Plans ---
              _buildSectionLabel("Family Plans", icon: Icons.family_restroom),
              const SizedBox(height: 10),
              _buildDropdown(_familyOptions, _selectedFamily, (val) => setState(() => _selectedFamily = val), "Select preference"),
              const SizedBox(height: 20),

              // --- Pets ---
              _buildSectionLabel("Pets", icon: Icons.pets),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _petOptions.map((opt) {
                  final isSelected = _selectedPets == opt;
                  return _buildSelectableChip(opt, isSelected, () => setState(() => _selectedPets = opt));
                }).toList(),
              ),
              const SizedBox(height: 20),

              // --- Drinking ---
              _buildSectionLabel("Drinking", icon: Icons.local_bar),
              const SizedBox(height: 10),
              _buildChipRow(_drinkingOptions, _selectedDrinking, (val) => setState(() => _selectedDrinking = val)),
              const SizedBox(height: 20),

              // --- Smoking ---
              _buildSectionLabel("Smoking", icon: Icons.smoking_rooms),
              const SizedBox(height: 10),
              _buildChipRow(_smokingOptions, _selectedSmoking, (val) => setState(() => _selectedSmoking = val)),
              const SizedBox(height: 20),

              // --- Languages ---
              _buildSectionLabel("Languages", icon: Icons.translate),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languageOptions.map((lang) {
                  final isSelected = _selectedLanguages.contains(lang);
                  return _buildSelectableChip(lang, isSelected, () {
                    setState(() {
                      if (isSelected) {
                        _selectedLanguages.remove(lang);
                      } else {
                        _selectedLanguages.add(lang);
                      }
                    });
                  });
                }).toList(),
              ),
              const SizedBox(height: 28),

              const Divider(height: 1),
              const SizedBox(height: 28),

              // --- Bio ---
              _buildSectionLabel("Bio (Optional)", icon: Icons.edit_note),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: _lightGrey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _bioController,
                  maxLines: 4,
                  style: GoogleFonts.outfit(color: _darkText),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Tell us a bit about yourself...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Passions ---
              _buildSectionLabel("Passions", icon: Icons.favorite_border),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableInterests.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.black : _darkText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                    backgroundColor: _lightGrey,
                    selectedColor: _primaryColor,
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? _primaryColor : Colors.grey.shade300),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // --- Submit Button ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: _primaryColor.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text(
                          "Create my profile ✨",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: GoogleFonts.outfit(
            color: _darkText,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildChipRow(List<String> options, String? selected, Function(String) onSelect) {
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onSelect(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : _lightGrey,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade300),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.black : _darkText,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectableChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : _lightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.black : _darkText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> options, String? selected, Function(String?) onChanged, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _lightGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(hint, style: GoogleFonts.outfit(color: Colors.grey[500])),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          dropdownColor: Colors.white,
          style: GoogleFonts.outfit(color: _darkText, fontSize: 16),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
