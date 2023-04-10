import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt_app/speech_message.dart';
import 'package:chatgpt_app/voice_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  late Chat _chat;

  // Init OpenAI in here because global init produce error (probally due to lazy initialization)
  @override
  void initState() {
    _openAi = OpenAI.instance.build(
      token: dotenv.env["api_key"],
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 90)),
      isLog: true
    );

    tts.setSpeechRate(0.5);
    _messages.insert(0, _buildResponse(_greeting, _chatGpt));
    _addPromt(_greeting, _chatGpt);
    super.initState();
  }

  @override
  Widget build(BuildContext context)
  {
    _chat = Chat(
      theme: const DarkChatTheme(),
      messages: _messages,
      onSendPressed: _onSendButtonPressed,
      user: _user,
      customBottomWidget: VoiceInput(onSendButtonPressed: _onSendButtonPressed, onVoiceButtonPressed: () => print("voice")),
      customMessageBuilder: _responseBuilder,
    );

    return Scaffold(
      body: _chat
    );
  }

  Widget _responseBuilder(types.CustomMessage message, {required messageWidth})
  {
    return SpeechMessage(
      chat: _chat,
      message: message,
      messageWidth: (messageWidth as int).toDouble(),
      tts: tts
    );
  }

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
      _replaceLastMessage(responseText.replaceAll("```", "`"), _chatGpt, _buildResponse);
      _addPromt(responseText, _chatGpt);
    }
    catch (error) {
      _replaceLastMessage("Error with contacting the server, please try again later", _client, _buildMessage);
    }
  }

  Future<void> _speak(String responseText) async {
    await tts.stop();
    await tts.setSpeechRate(0.75);
    tts.speak(responseText);
  }

  void _addPromt(String text, types.User author) {
    prompts.add({"role": author.id, "content": text});
  }

  void _replaceLastMessage(String text, types.User author, types.Message Function(String, types.User) builder) {
    setState(() => _messages[0] = builder(text, author));
  }

  types.Message _buildMessage(String text, types.User author) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return types.TextMessage(
      author: author,
      createdAt: now,
      id: now.toString(),
      text: text,
    );
  }

  types.Message _buildResponse(String text, types.User author) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return types.CustomMessage(
      author: author,
      createdAt: now,
      id: now.toString(),
      metadata: { "text" : text }
    );
  }
}