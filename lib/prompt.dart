import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class Prompt {
  final String text;
  final types.User author;
  final int time;

  Prompt(this.author, this.text, {int? time}) :
    time = time ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, String> toJson() {
    return {"authorId": author.id, "text": text, "time": time.toString()};
  }

  Map<String, String> toPromptJson() {
    return {"role": author.id, "content": text};
  }
}