import 'package:client/channel_list_page.dart';
import 'package:flutter/material.dart';
import 'chat_api.dart'; // your existing ChatApi

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  // change URL if your backend is different
  final ChatApi _api = ChatApi('http://localhost:8080');

  // super dumb nickname, just to have *something*
  final String _nickname =
      'Guest${DateTime.now().millisecondsSinceEpoch % 10000}';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      title: 'Messenger',
      home: ChannelListPage(api: _api, nickname: _nickname),
    );
  }
}
