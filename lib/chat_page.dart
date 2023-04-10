import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt_app/prompt.dart';
import 'package:chatgpt_app/speech_message.dart';
import 'package:chatgpt_app/voice_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  static const _user = types.User(id: 'user');

  static const _chatGpt = types.User(id: 'assistant');

  static const _client = types.User(id: 'client');

  List<types.Message> _messages = [];

  final List<Map<String, String>> prompts = [];

  final List<Prompt> _promptData = [];

  final FlutterTts tts = FlutterTts();

  late OpenAI _openAi;

  bool _isAiTyping = false;

  // Init OpenAI in here because global init produce error (probally due to lazy initialization)
  @override
  void initState() {
    _openAi = OpenAI.instance.build(
      token: dotenv.env["api_key"],
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 90)),
      isLog: true
    );

    tts.setSpeechRate(0.5);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _readSavedConversation();
  }

  void _readSavedConversation() async {
    final prefs = await SharedPreferences.getInstance();
    var jsons = jsonDecode(prefs.getString("conversation") ?? '[]') as List;

    var emptyMessage = const types.CustomMessage(author: _client, id: "");
    _messages = List.filled(jsons.length, emptyMessage, growable: true);

    setState(() {
      var i = 0;

      for (var json in jsons) {
        var prompt = _addPromt(json["text"]!, _getAuthor(json["authorId"]!), time: int.parse(json["time"]!));
        _messages[jsons.length - 1 - i] = _buildMessageByAuthor(prompt.text, prompt.author, time: prompt.time);
        i++;
      }

      _addPromt("Hello! How can I assist you today?", _chatGpt);
      _messages.insertAll(0, [
        _buildResponse("Hello! How can I assist you today?")
      ]);
    });
  }

  types.User _getAuthor(String id) {
      switch (id) {
        case "user":
          return _user;
        case "assistant":
          return _chatGpt;
        default:
          return _client;
      }
  }

  types.Message _buildMessageByAuthor(String text, types.User author, {int? time}) {
    if (author == _chatGpt) {
      return _buildResponse(text, time: time);
    }

    return _buildMessage(text, time: time);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.paused) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("conversation", jsonEncode(_promptData));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        theme: const DarkChatTheme(),
        messages: _messages,
        onSendPressed: _onSendButtonPressed,
        user: _user,
        customBottomWidget: _isAiTyping? const SizedBox(height: 24) : VoiceInput(onSendButtonPressed: _onSendButtonPressed, onVoiceButtonPressed: () => print("voice")),
        customMessageBuilder: _responseBuilder,
      )
    );
  }

  Widget _responseBuilder(types.CustomMessage message, {required messageWidth}) {
    return SpeechMessage(
      message: message,
      messageWidth: (messageWidth as int).toDouble(),
      tts: tts
    );
  }

  void _onSendButtonPressed(types.PartialText message) async {
    _addPromt(message.text, _user);

    setState(() {
      _messages.insertAll(0, [
        _buildMessage("_chatGPT is typing..._", author: _client),
        _buildMessage(message.text)
      ]);

      _isAiTyping = true;
    });

    final request = ChatCompleteText(
      maxToken: 400,
      messages: prompts,
      model: ChatModel.ChatGptTurbo0301Model,
    );

    try {
      final response = await _openAi.onChatCompletion(request: request);
      final responseText = response!.choices[0].message!.content;
      _addPromt(responseText, _chatGpt);
      _replaceLastMessage(_buildResponse(responseText.replaceAll("```", "`")));
    }
    catch (error) {
      _replaceLastMessage(_buildMessage("Error with contacting the server, please try again later", author: _client));
    }
  }

  void _replaceLastMessage(types.Message message) {
    setState(() {
      _messages[0] = message;
      _isAiTyping = false;
    });
  }

  Prompt _addPromt(String text, types.User author, {int? time}) {
    prompts.add({"role": author.id, "content": text});
    var prompt = Prompt(author, text, time: time);
    _promptData.add(prompt);
    return prompt;
  }

  types.Message _buildMessage(String text, {types.User? author, int? time}) {
    time ??= DateTime.now().millisecondsSinceEpoch;
    author ??= _user;

    return types.TextMessage(
      author: author,
      createdAt: time,
      id: time.toString(),
      text: text,
    );
  }

  types.Message _buildResponse(String text, {int? time}) {
    time ??= DateTime.now().millisecondsSinceEpoch;

    return types.CustomMessage(
      author: _chatGpt,
      createdAt: time,
      id: time.toString(),
      metadata: { "text" : text }
    );
  }
}