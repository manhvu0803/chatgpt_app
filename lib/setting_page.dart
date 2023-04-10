import 'package:chatgpt_app/settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text("Speak message automatically", style: TextStyle(color: Colors.white))),
                Switch(
                  value: Settings.speakMessageAutomatically,
                  onChanged: (value) => setState(() => Settings.speakMessageAutomatically = value)
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Delete conversations"),
                onPressed: () => _deleteConversations(context)
              ),
            )
          ],
        ),
      ),
    );
  }

  void _deleteConversations(BuildContext context) async {
    var pref = await SharedPreferences.getInstance();
    await pref.setString("conversation", "");

    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Deleted all conversation history"))
    );
  }
}