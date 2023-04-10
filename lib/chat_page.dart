import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatgpt_app/speech_message.dart';
import 'package:chatgpt_app/voice_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _Prompt {
  final String text;
  final types.User author;
  final int time;

  _Prompt(this.author, this.text, {int? time}) :
    time = time ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, String> toJson() {
    return {"authorId": author.id, "text": text, "time": time.toString()};
  }

  Map<String, String> toPromptJson() {
    return {"role": author.id, "content": text};
  }
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  static const _user = types.User(id: 'user');

  static const _chatGpt = types.User(id: 'assistant');

  static const _client = types.User(id: 'client');

  late List<types.Message> _messages = [];

  final List<_Prompt> _prompts = [];

  late final int _currentPromptIndex;

  final FlutterTts tts = FlutterTts();

  late OpenAI _openAi;

  late Chat _chat;

  bool _isTyping = false;

  // Init OpenAI in here because global init produce error (probally due to lazy initialization)
  @override
  void initState() {
    _openAi = OpenAI.instance.build(
      token: dotenv.env["api_key"],
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 90)),
      isLog: true
    );

    tts.setSpeechRate(0.5);
    _readSavedConversation();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void _readSavedConversation() async {
    final prefs = await SharedPreferences.getInstance();
    var jsons = jsonDecode(prefs.getString("conversation") ?? '[]') as List;

    var emptyMessage = const types.CustomMessage(author: _client, id: "");
    _messages = List.filled(jsons.length, emptyMessage, growable: true);
    _currentPromptIndex = _messages.length;

    setState(() {
      var i = 0;

      for (var json in jsons) {
        var prompt = _addPromt(json["text"]!, _getAuthor(json["authorId"]!), time: int.parse(json["time"]!));
        _messages[jsons.length - 1 - i] = _buildMessageByAuthor(prompt.text, prompt.author, time: prompt.time);
        i++;
      }

      _addPromt("Hello! How can I assist you today?", _chatGpt);
      _messages.insertAll(0, [
        _buildResponse("Hello! How can I assist you today?"),
        _buildSystemMessage("New conversation")
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.paused) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("conversation", jsonEncode(_prompts));
  }

  @override
  Widget build(BuildContext context)
  {
    var bottom = _isTyping? const SizedBox(height: 24) : VoiceInput(onSendButtonPressed: _onSendButtonPressed, onVoiceButtonPressed: () => print("voice"));

    _chat = Chat(
      theme: const DarkChatTheme(),
      messages: _messages,
      onSendPressed: _onSendButtonPressed,
      user: _user,
      customBottomWidget: bottom,
      customMessageBuilder: (message, {required messageWidth}) => SpeechMessage(
          chat: _chat,
          message: message,
          messageWidth: messageWidth.toDouble(),
          tts: tts
        ),
    );

    return Scaffold(
      body: _chat
    );
  }

  void _onSendButtonPressed(types.PartialText message) async {
    _addPromt(message.text, _user);

    setState(() {
      _messages.insertAll(0, [
        _buildMessage("_chatGPT is typing..._", author: _client),
        _buildMessage(message.text)
      ]);
    });

    final request = ChatCompleteText(
      maxToken: 400,
      messages: List.from(_prompts.sublist(_currentPromptIndex).where((e) => e.author != _client).map((e) => e.toPromptJson())),
      model: ChatModel.ChatGptTurbo0301Model,
    );

    try {
      _isTyping = true;
      final response = await _openAi.onChatCompletion(request: request);
      final responseText = response!.choices[0].message!.content;
      _replaceLastMessage(responseText.replaceAll("```", "`"), _chatGpt, _buildResponse);
      _addPromt(responseText, _chatGpt);
    }
    catch (error) {
      _replaceLastMessage("Error with contacting the server, please try again later", _client, _buildMessage);
    }
    finally {
      _isTyping = false;
    }
  }

  _Prompt _addPromt(String text, types.User author, {int? time}) {
    time ??= DateTime.now().millisecondsSinceEpoch;
    var prompt = _Prompt(author, text, time: time);
    _prompts.add(prompt);
    return prompt;
  }

  void _replaceLastMessage(String text, types.User author, types.Message Function(String) builder) {
    setState(() => _messages[0] = builder(text));
  }

  types.Message _buildMessageByAuthor(String text, types.User author, {int? time}) {
    if (author == _chatGpt) {
      return _buildResponse(text, time: time);
    }
    else if (author == _client) {
      return _buildSystemMessage(text, time: time);
    }

    return _buildMessage(text, time: time);
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

  types.Message _buildSystemMessage(String text, {int? time}) {
    time ??= DateTime.now().millisecondsSinceEpoch;

    return types.SystemMessage(
      author: _client,
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