import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:friendify/main.dart'; // Import to access navigatorKey

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
     
    try {
      final senderProfile = await supabase.from('profiles').select('name').eq('id', senderId).single();
      final senderName = senderProfile['name'] ?? 'someone';

      final text = message['content'];
      
      if (overlayState != null) {
        showOverlayNotification(overlayState, senderName, text);
    } catch (e) {
      // Fallback
      if (overlayState != null) {
        showOverlayNotification(overlayState, "New Message", message['content']);
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
void showOverlayNotification(OverlayState overlay, String title, String message) {
  // We don't need Overlay.of(context) anymore, we have the state!
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60, // Below Dynamic Island / notch
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SafelyDismissible(
            child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD4FF00), // Firefly Neon
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_chat_unread, color: Colors.black),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(message, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto remove after 3 seconds
  Future.delayed(const Duration(seconds: 4), () {
    overlayEntry.remove();
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
