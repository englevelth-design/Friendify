import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UserAvatar extends StatefulWidget {
  final String? imageUrl;
  final Function(String) onUpload;

  const UserAvatar({super.key, this.imageUrl, required this.onUpload});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _isLoading = false;

  Future<void> _upload() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    setState(() => _isLoading = true);
    
    try {
      final bytes = await imageFile.readAsBytes();
      // On web, path is a blob URL, so we rely on mimeType. 
      // Fallback to jpeg/jpg if unknown.
      final String mimeType = imageFile.mimeType ?? 'image/jpeg';
      final String fileExt = mimeType.split('/').last;
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath, 
            bytes, 
            fileOptions: FileOptions(contentType: mimeType, upsert: true)
          );

      final imageUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      widget.onUpload(imageUrl);
    } catch (error) {
       print("UPLOAD ERROR: $error");
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _upload,
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[800],
        backgroundImage: widget.imageUrl != null ? NetworkImage(widget.imageUrl!) : null,
        child: _isLoading 
            ? const CircularProgressIndicator(color: Color(0xFFD4FF00))
            : widget.imageUrl == null 
                ? const Icon(Icons.camera_alt, size: 40, color: Colors.white70)
                : null,
      ),
    );
  }
}
