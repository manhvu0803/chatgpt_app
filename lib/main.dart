import 'package:chatgpt_app/chat_page.dart';
import 'package:chatgpt_app/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  Settings.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(color: Color(0xff2b2250)),
        scaffoldBackgroundColor: const Color(0xff1c1c38)
      ),
      home: const ChatPage()
    );
}