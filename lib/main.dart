import 'package:flutter/material.dart';
import 'package:friendify/src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Supabase here once env vars are available
  // await Supabase.initialize(url: '...', anonKey: '...');

  runApp(const FriendifyApp());
}
