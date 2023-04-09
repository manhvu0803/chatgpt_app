import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt_app/voice_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
      home: ChatPage(),
    );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _greeting = "Hello, how can i help you today?";

  static const _user = types.User(id: 'user');

  static const _chatGpt = types.User(id: 'assistant');

  static const _client = types.User(id: 'client');

  final List<types.Message> _messages = [];

  final List<Map<String, String>> prompts = [];

  final FlutterTts tts = FlutterTts();

  late OpenAI _openAi;

  // Init OpenAI in here because global init produce error (probally due to lazy initialization)
  @override
  void initState() {
    _openAi = OpenAI.instance.build(
      token: dotenv.env["api_key"],
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 90)),
      isLog: true
    );

    _messages.insert(0, _buildMessage(_greeting, _chatGpt));
    _addPromt(_greeting, _chatGpt);
    tts.setSpeechRate(0.75);

    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      body: Chat(
        theme: const DarkChatTheme(),
        messages: _messages,
        onSendPressed: _onSendButtonPressed,
        user: _user,
        customBottomWidget: VoiceInput(onSendButtonPressed: _onSendButtonPressed, onVoiceButtonPressed: () => print("voice")),
      ),
    );

  void _onSendButtonPressed(types.PartialText message) async {
    _addPromt(message.text, _user);

    setState(() {
      _messages.insertAll(0, [
        _buildMessage("_chatGPT is typing..._", _client),
        _buildMessage(message.text, _user)
      ]);
    });

    final request = ChatCompleteText(
      maxToken: 400,
      messages: prompts,
      model: ChatModel.ChatGptTurbo0301Model,
    );

    try {
      final response = await _openAi.onChatCompletion(request: request);
      final responseText = response!.choices[0].message!.content;
      await tts.stop();
      tts.speak(responseText);
      _replaceLastMessage(responseText.replaceAll("```", "`"), _chatGpt);
      _addPromt(responseText, _chatGpt);
    }
    catch (error) {
      print(error);
      _replaceLastMessage("Error with contacting the server, please try again later", _client);
    }
  }

  void _addPromt(String text, User author) {
    prompts.add({"role": author.id, "content": text});
  }

  void _replaceLastMessage(String text, User author) {
    setState(() => _messages[0] = _buildMessage(text, author));
  }

  types.Message _buildMessage(String text, User author) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final textMessage = types.TextMessage(
      author: author,
      createdAt: now,
      id: now.toString(),
      text: text,
    );

    return textMessage;
  }
}