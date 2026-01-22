import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:friendify/src/features/auth/presentation/pages/login_page.dart';
import 'package:friendify/src/features/auth/presentation/widgets/auth_gate.dart';
import 'package:friendify/src/features/profile/presentation/widgets/image_viewer_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // If null, assume current user (Viewer Mode vs Owner Mode)
  
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final targetId = widget.userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (targetId == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', targetId)
        .maybeSingle();

    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
       // AuthGate will handle the redirect
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()), 
        (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = widget.userId == null || widget.userId == currentUserId;

    final name = _profileData?['name'] ?? 'Firefly User';
    final age = _profileData?['age']?.toString() ?? '24';
    final bio = _profileData?['bio'] ?? 'Ready to glow.';
    final imageUrl = (_profileData?['image_urls'] as List?)?.firstOrNull as String?;
    
    // Placeholder Data for new UI elements
    final List<String> interests = ['Hiking', 'Coffee', 'Coding', 'Travel', 'Music', 'Photography'];
    final List<String> photos = [
       if (imageUrl != null) imageUrl,
       'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?auto=format&fit=crop&w=400&q=80', // Rainforest
       'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?auto=format&fit=crop&w=400&q=80', // Mountains
       'https://images.unsplash.com/photo-1511367461989-f85a21fda167?auto=format&fit=crop&w=400&q=80', // Friends
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient show through
      appBar: !isMe ? AppBar(backgroundColor: Colors.transparent, elevation: 0) : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. COVER PHOTO & AVATAR HEADER
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Cover Photo (Standard Friendify Banner)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/friendify-top-banner.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Gradient Overlay (White at bottom to blend with page)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                
                // The Glowing Avatar (Overlapping bottom)
                Positioned(
                  bottom: -60,
                  child: GestureDetector(
                    onTap: imageUrl != null ? () => openImageViewer(context, imageUrl, heroTag: 'profile_avatar') : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                         Container(
                           width: 140,
                           height: 140,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             boxShadow: [
                               BoxShadow(
                                 color: const Color(0xFFD4FF00).withOpacity(0.6),
                                 blurRadius: 40,
                                 spreadRadius: 2,
                               )
                             ],
                           ),
                         ),
                         Hero(
                           tag: 'profile_avatar',
                           child: Container(
                             width: 130,
                             height: 130,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               border: Border.all(color: Colors.white, width: 5),
                               image: imageUrl != null 
                                   ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                                   : null,
                               color: Colors.grey[200],
                             ),
                             child: imageUrl == null 
                                 ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                 : null,
                           ),
                         ),
                         Positioned(
                           bottom: 10,
                           right: 10,
                           child: Container(
                             padding: const EdgeInsets.all(4),
                             decoration: const BoxDecoration(
                               color: Colors.blueAccent,
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(Icons.check, size: 16, color: Colors.white),
                           ),
                         )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 70), // Spacing for Avatar overlap
            
            // 2. NAME & INFO
            Text(
              "$name, $age",
              style: const TextStyle(
                color: Colors.black, // Dark Text
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                const Text("5km away", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFD4FF00), shape: BoxShape.circle)), // Active Dot
                const SizedBox(width: 6),
                const Text("Active now", style: TextStyle(color: Color(0xFF7CB342), fontWeight: FontWeight.bold)), // Darker Green for readability
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.5, fontSize: 15),
              ),
            ),
            
            const SizedBox(height: 32),

            // 3. WIDE ACTION BUTTONS (Context Aware)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: isMe ? [
                  Expanded(child: _buildWideButton("SETTINGS", Icons.settings, Colors.white, _logout, textColor: Colors.black)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildWideButton("EDIT INFO", Icons.edit, Colors.black, () async {
                    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
                    if (result == true) _fetchProfile();
                  }, textColor: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildWideButton("SAFETY", Icons.shield, Colors.white, () {}, textColor: Colors.black)),
                ] : [
                  // VIEWER MODE BUTTONS
                  Expanded(child: _buildWideButton("REPORT", Icons.flag, Colors.white, () {}, textColor: Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildWideButton("START CHAT", Icons.chat_bubble, Colors.black, () {
                    Navigator.pop(context); // Go back to chat
                  }, textColor: Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildWideButton("BLOCK", Icons.block, Colors.white, () {}, textColor: Colors.black)),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // 4. CONTENT SECTIONS
            _buildSectionHeader("Interests"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: interests.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(color: Colors.black)),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black12,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  avatar: Icon(_getIconForInterest(tag), size: 16, color: Colors.black54),
                )).toList(),
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("Gallery"),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: photos.length + (isMe ? 1 : 0), // Hide Add Button if not me
              itemBuilder: (context, index) {
                if (index < photos.length) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: NetworkImage(photos[index]), fit: BoxFit.cover),
                    ),
                  );
                } else {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                    ),
                    child: const Icon(Icons.add_a_photo, color: Colors.white54),
                  );
                }
              },
            ),

            const SizedBox(height: 40),

            // 5. PROMO CARD (Only for Owner)
            if (isMe)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF1E293B),
                  border: Border.all(color: const Color(0xFFD4FF00).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     const Text("Firefly Gold", style: TextStyle(color: Color(0xFFD4FF00), fontSize: 20, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 8),
                     const Text("• See who likes you\n• Unlimited Swipes\n• Advanced Filters", style: TextStyle(color: Colors.white70, height: 1.6)),
                     const SizedBox(height: 20),
                     ElevatedButton(
                       onPressed: (){},
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFFD4FF00),
                         foregroundColor: Colors.black,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: const StadiumBorder()
                       ),
                       child: const Text("GET GOLD", style: TextStyle(fontWeight: FontWeight.bold)),
                     )
                  ],
                ),
              ),
              const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildWideButton(String label, IconData icon, Color color, VoidCallback onTap, {Color textColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  IconData _getIconForInterest(String interest) {
    switch (interest.toLowerCase()) {
      case 'hiking': return Icons.landscape;
      case 'coffee': return Icons.local_cafe;
      case 'coding': return Icons.code;
      case 'travel': return Icons.flight;
      case 'music': return Icons.music_note;
      case 'photography': return Icons.camera_alt;
      default: return Icons.star;
    }
  }
}

