import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_tts/flutter_tts.dart';

class SpeechMessage extends StatefulWidget {
  final Chat chat;

  final types.CustomMessage message;

  final FlutterTts tts;

  final double messageWidth;

  String get text => message.metadata?["text"] ?? "Error building message";

  const SpeechMessage({
    super.key,
    required this.chat,
    required this.message,
    required this.tts,
    required this.messageWidth
  });

  @override
  State<StatefulWidget> createState() => _SpeechMessageState();
}

class _SpeechMessageState extends State<SpeechMessage> {
  bool _isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextMessage(
          emojiEnlargementBehavior: widget.chat.emojiEnlargementBehavior,
          hideBackgroundOnEmojiMessages: widget.chat.hideBackgroundOnEmojiMessages,
          message: types.TextMessage(
            author: widget.message.author,
            id: widget.message.id,
            text: widget.text
          ),
          showName: false,
          usePreviewData: widget.chat.usePreviewData
        ),
        SizedBox(
          width: widget.messageWidth,
          child: Material(
            color: const Color(0xff2b2250),
            child: IconButton(
              onPressed: _handleTtsPressed,
              icon: _isSpeaking? const Icon(Icons.volume_off) : const Icon(Icons.volume_up),
              iconSize: 24,
              color: Colors.white
            )
          ),
        )
      ],
    );
  }

  void _handleTtsPressed() async {
    await widget.tts.stop();

    if (!_isSpeaking) {
      print("start speaking");
      setState(() => _isSpeaking = true);
      await widget.tts.awaitSpeakCompletion(true);
      await widget.tts.speak(widget.text);
      print("stopped speaking");
      setState(() => _isSpeaking = false);
    }
    else {
      setState(() => _isSpeaking = false);
    }
  }
}