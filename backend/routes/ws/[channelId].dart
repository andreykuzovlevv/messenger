import 'dart:convert';

import 'package:backend/chat_store.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:shared/shared.dart';

final _store = ChatStore.instance;

Future<Response> onRequest(RequestContext context, String channelId) async {
  final handler = webSocketHandler((channel, protocol) {
    // New client connected
    _store.addSocket(channelId, channel);

    // // (Optional) send history to the new client
    // final history = _store.getMessages(channelId);
    // for (final msg in history) {
    //   channel.sink.add(jsonEncode(msg.toJson()));
    // }

    // Listen for messages from this client
    channel.stream.listen(
      (data) {
        // Expect JSON { "text": "...", "author": "..." }
        final map = jsonDecode(data as String) as Map<String, dynamic>;

        final msg = Message(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          channelId: channelId,
          text: map['text'] as String,
          author: (map['author'] as String?) ?? 'Anonymous',
          createdAt: DateTime.now(),
        );

        _store.addMessage(msg); // stores + broadcasts to all sockets
      },
      onDone: () {
        _store.removeSocket(channelId, channel);
      },
      onError: (_) {
        _store.removeSocket(channelId, channel);
      },
    );
  });

  return handler(context);
}
