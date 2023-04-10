import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class SpeechMessage extends StatelessWidget {
  const SpeechMessage({
    super.key,
    required this.chat,
    required this.message,
    required this.onTtsPressed,
    required this.messageWidth
  });

  final Chat chat;

  final types.CustomMessage message;

  final void Function() onTtsPressed;

  final double messageWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextMessage(
          emojiEnlargementBehavior: chat.emojiEnlargementBehavior,
          hideBackgroundOnEmojiMessages: chat.hideBackgroundOnEmojiMessages,
          message: types.TextMessage(
            author: message.author,
            id: message.id,
            text: message.metadata?["text"] ?? "Error building message"
          ),
          showName: false,
          usePreviewData: chat.usePreviewData
        ),
        SizedBox(
          width: messageWidth,
          child: Material(
            color: const Color(0xff2b2250),
            child: IconButton(
              onPressed: onTtsPressed,
              icon: const Icon(Icons.volume_up),
              iconSize: 24,
              color: Colors.white
            )
          ),
        )
      ],
    );
  }
}