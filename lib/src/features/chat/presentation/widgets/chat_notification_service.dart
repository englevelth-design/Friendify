import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/src/core/utils/globals.dart'; // Import to access navigatorKey
import 'package:friendify/src/features/chat/presentation/pages/chat_page.dart'; // Import for navigation


// Global Route Observer
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final supabase = Supabase.instance.client;
  
  bool _isInitialized = false;
  
  // Keep track of auth subscription to cancel if needed
  RealtimeChannel? _channel;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // 1. Listen to Auth Changes
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _listenForMessages();
      } else if (event == AuthChangeEvent.signedOut) {
        _channel?.unsubscribe();
        _channel = null;
      }
    });

    _listenForMessages();
  }

  void _listenForMessages() {
    final myId = supabase.auth.currentUser?.id;
    
    if (myId == null) return;

    if (_channel != null) return;

    // Use channel for INSERT events with a UNIQUE name to avoid conflicts with ChatListPage
    _channel = supabase.channel('notifications_service');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        _handleNewMessage(payload.newRecord);
      },
    ).subscribe((status, error) {
      if (error != null) {
        debugPrint("ChatNotificationService: Subscription Error: $error");
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> message) async {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    final receiverId = message['receiver_id'];
    final senderId = message['sender_id'];
    
    debugPrint("🔔 Check: receiver=$receiverId (Me=$myId), sender=$senderId");

    if (receiverId != myId) {
      debugPrint("🔔 Ignoring: Not for me.");
      return;
    }

    // Check if Chat List is Active
    if (ChatPageTracker.isChatListActive) return;
    
    // Check if Chat Page with THIS sender is active
    if (_isChatPageActive(senderId)) return;

    _showNotification(message, senderId);
  }
  
  bool _isChatPageActive(String senderId) {
    return ChatPageTracker.activeChatUserId == senderId;
  }
  
  String? _getCurrentRouteName() {
     return null;
  }

  void _showNotification(Map<String, dynamic> message, String senderId) async {
     // ACCESS GLOBAL OVERLAY DIRECTLY
      final overlayState = navigatorKey.currentState?.overlay; // GET OVERLAY STATE
      
      // Define Navigation Logic Reuse
      final VoidCallback onNotificationTap = () {
        debugPrint("🔔 Notification Tapped! Navigating to ChatPage...");
        final nav = navigatorKey.currentState;
        if (nav == null) {
          debugPrint("🔔 ERROR: NavigatorState is NULL!");
          return;
        }
        
        // Navigate
        nav.push(
          MaterialPageRoute(
            builder: (_) => ChatPage(
              targetUserId: senderId, 
              // We might not have name/image in fallback, but that's okay, ChatPage handles it
              targetUserName: 'New Message', 
              targetUserImage: null,
            ),
          ),
        );
      };

    try {
      // FIX: Use 'image_urls' instead of 'avatar_url' which doesn't exist
      final senderProfile = await supabase.from('profiles').select('name, image_urls').eq('id', senderId).single();
      final senderName = senderProfile['name'] ?? 'someone';
      
      // Handle list of images safely
      final images = List<dynamic>.from(senderProfile['image_urls'] ?? []);
      final senderImage = images.isNotEmpty ? images.first as String : null;

      final text = message['content'];
      
      if (overlayState != null) {
        showOverlayNotification(
          overlayState, 
          senderName, 
          text,
          imageUrl: senderImage, // Pass the image
          onTap: () {
             // Use specific name/image if available
              debugPrint("🔔 Notification Tapped! Navigating to ChatPage...");
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    targetUserId: senderId, 
                    targetUserName: senderName,
                    targetUserImage: senderImage,
                  ),
                ),
              );
          }
        );
      }
    } catch (e) {
      debugPrint("🔔 Error fetching profile: $e. Using Fallback.");
      // Fallback
      if (overlayState != null) {
        showOverlayNotification(
          overlayState, 
          "New Message", 
          message['content'],
          onTap: onNotificationTap // Pass the generic callback!
        );
      }
    }
  }
}

// Simple Tracker class
class ChatPageTracker {
  static String? activeChatUserId;
  static bool isChatListActive = false;
}

// THE OVERLAY WIDGET
// THE OVERLAY WIDGET
void showOverlayNotification(
  OverlayState overlay, 
  String title, 
  String message, 
  {
    String? imageUrl,
    VoidCallback? onTap
  }
) {
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50, // Slightly higher for a floating feel
      left: 16,
      right: 16,
      child: SafelyDismissible(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8), // Extra side spacing for floating look
            decoration: BoxDecoration(
              // Gradient: Sky Blue to White
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0F7FA), Colors.white], // Light Cyan/Sky to White
              ),
              borderRadius: BorderRadius.circular(30), // Pill Shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), 
                  blurRadius: 20, 
                  offset: const Offset(0, 10),
                  spreadRadius: 1,
                )
              ],
              // Neon Green Border
              border: Border.all(color: const Color(0xFFD4FF00), width: 2), // Firefly Neon
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  debugPrint("🔔 Overlay InkWell Tapped!");
                  
                  try {
                    onTap?.call();
                  } catch (e) {
                    debugPrint("🔔 Error executing onTap: $e");
                  }
                  
                  Future.delayed(const Duration(milliseconds: 200), () {
                     if (overlayEntry.mounted) {
                       overlayEntry.remove();
                     }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Avatar
                       Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
                          color: Colors.white,
                          image: imageUrl != null && imageUrl.isNotEmpty 
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (imageUrl == null || imageUrl.isEmpty) 
                            ? const Icon(Icons.person, color: Colors.black54, size: 24)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      
                      // Texts
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title, 
                              style: const TextStyle(
                                color: Colors.black, // Explicit Black
                                fontWeight: FontWeight.w800, 
                                fontSize: 15,
                                letterSpacing: -0.5
                              )
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message, 
                              style: const TextStyle(
                                color: Colors.black87, // Slightly softer black
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ), 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // "View" Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "View",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto remove after 4 seconds
  Future.delayed(const Duration(seconds: 4), () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

class SafelyDismissible extends StatefulWidget {
  final Widget child;
  const SafelyDismissible({super.key, required this.child});

  @override
  State<SafelyDismissible> createState() => _SafelyDismissibleState();
}

class _SafelyDismissibleState extends State<SafelyDismissible> with SingleTickerProviderStateMixin {
   late AnimationController _controller;
   late Animation<Offset> _offsetAnimation;
   
   @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}
