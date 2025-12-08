import 'package:client/channel_list_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_api.dart'; // your existing ChatApi

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: App(),
    ),
  );
}

class App extends StatefulWidget {
  App({super.key});

  @override
  State<App> createState() => AppState();
}

class AppState extends State<App> {
  // change URL if your backend is different
  final ChatApi _api = ChatApi('http://localhost:8080');
  String? _nickname;

  @override
  void initState() {
    super.initState();
    _loadNickname();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNickname = prefs.getString('nickname');

    if (savedNickname != null && savedNickname.isNotEmpty) {
      setState(() {
        _nickname = savedNickname;
      });
    } else {
      // No saved nickname, ask for it
      setState(() {});
      _askForNickname();
    }
  }

  Future<void> _askForNickname({String? currentName}) async {
    final controller = TextEditingController(text: currentName ?? '');

    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(currentName == null ? 'Welcome!' : 'Change Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              labelText: 'Your name',
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(context).pop(trimmed);
              }
            },
          ),
          actions: [
            if (currentName != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: Text(currentName == null ? 'Continue' : 'Save'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      await _saveNickname(name);
    } else if (currentName == null) {
      // If user cancelled on first launch, use a default
      await _saveNickname(
        'Guest${DateTime.now().millisecondsSinceEpoch % 10000}',
      );
    }
  }

  Future<void> _saveNickname(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', name);
    setState(() {
      _nickname = name;
    });
  }

  void changeNickname() {
    _askForNickname(currentName: _nickname);
  }

  @override
  Widget build(BuildContext context) {
    if (_nickname == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChannelListPage(
      api: _api,
      nickname: _nickname!,
      onNicknameChanged: changeNickname,
    );
  }
}
