import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/features/auth/presentation/widgets/neon_text_field.dart';
import 'package:friendify/src/features/profile/presentation/widgets/user_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          // Handling image_urls array for now getting the first one
           List<dynamic> urls = data['image_urls'] ?? [];
           if (urls.isNotEmpty) _imageUrl = urls.first as String;
        });
      }
    } catch (e) {
      // Profile might not exist yet
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final updates = {
        'id': userId,
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'bio': _bioController.text.trim(),
        'image_urls': _imageUrl != null ? [_imageUrl] : [],
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client.from('profiles').upsert(updates);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Saved!')));
         Navigator.of(context).pop(); // Go back to Swipe Page
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error saving profile')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: UserAvatar(
                  imageUrl: _imageUrl,
                  onUpload: (url) => setState(() => _imageUrl = url),
                ),
              ),
              const SizedBox(height: 32),
              NeonTextField(controller: _nameController, label: "Name"),
              const SizedBox(height: 16),
              NeonTextField(controller: _ageController, label: "Age"),
              const SizedBox(height: 16),
              NeonTextField(controller: _bioController, label: "Bio"),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4FF00),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("SAVE PROFILE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tip: Add more photos to get more matches!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              )
            ],
          ),
    );
  }
}
