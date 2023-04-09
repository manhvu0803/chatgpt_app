import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

class VoiceInput extends StatelessWidget {
  final void Function(PartialText) onSendButtonPressed;

  final void Function() onVoiceButtonPressed;

  const VoiceInput({
    super.key,
    required this.onSendButtonPressed,
    required this.onVoiceButtonPressed
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Row(
        children: [
          Expanded(child: Input(onSendPressed: onSendButtonPressed)),
          SizedBox(
            height: 64,
            child: Material(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  onPressed: onVoiceButtonPressed,
                  icon: const Icon(Icons.mic_outlined),
                  iconSize: 24,
                  color: Colors.white
                ),
              ),
            ),
          )
        ]
      ),
    );
  }

}