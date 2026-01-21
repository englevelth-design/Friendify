import 'package:flutter/material.dart';
import 'package:friendify/src/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://lcnpedbzmzvhrtfhqfno.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjbnBlZGJ6bXp2aHJ0ZmhxZm5vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5NjIyNjQsImV4cCI6MjA4NDUzODI2NH0.OrNjVt0tzxpuxhpfxbU9uIp0Eu7AcB5xiTUFscwfY3M',
  );

  runApp(const FriendifyApp());
}
