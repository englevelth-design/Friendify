import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'image_viewer_page.dart';

class UserAvatar extends StatefulWidget {
  final String? imageUrl;
  final Function(String) onUpload;

  const UserAvatar({super.key, this.imageUrl, required this.onUpload});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _isLoading = false;

  Future<void> _pickAndCropImage() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;

    final bytes = await imageFile.readAsBytes();
    final String mimeType = imageFile.mimeType ?? 'image/jpeg';
    
    // Show crop preview dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CropPreviewDialog(
        imageBytes: bytes,
        onConfirm: () => Navigator.pop(ctx, true),
        onRetake: () => Navigator.pop(ctx, false),
      ),
    );
    
    if (confirmed != true) return;
    
    // Proceed with upload
    await _uploadImage(bytes, mimeType);
  }

  Future<void> _uploadImage(Uint8List bytes, String mimeType) async {
    setState(() => _isLoading = true);
    
    try {
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

  void _viewImage() {
    if (widget.imageUrl != null) {
      openImageViewer(context, widget.imageUrl!, heroTag: 'avatar_image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickAndCropImage,
      onLongPress: widget.imageUrl != null ? _viewImage : null,
      child: Stack(
        children: [
          Hero(
            tag: 'avatar_image',
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
          ),
          if (widget.imageUrl != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FF00),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }
}

// Crop Preview Dialog
class _CropPreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const _CropPreviewDialog({
    required this.imageBytes,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                imageBytes,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your photo will be cropped to a circle',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh, color: Colors.black54),
                  label: const Text('Retake', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check, color: Colors.black),
                  label: const Text('Use Photo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4FF00),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
