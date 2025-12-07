import 'dart:convert';

import 'package:shared/shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatStore {
  final _channels = <String, Channel>{};
  final _messages = <String, List<Message>>{};
  final _socketsByChannel = <String, Set<WebSocketChannel>>{};

  static final ChatStore instance = ChatStore._();
  ChatStore._();

  List<Channel> getChannels() => _channels.values.toList();

  Channel createChannel(String name) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final channel = Channel(
      id: id,
      name: name,
      createdAt: DateTime.now(),
    );
    _channels[id] = channel;
    _messages[id] = [];
    _socketsByChannel[id] = {};
    return channel;
  }

  List<Message> getMessages(String channelId) =>
      List.unmodifiable(_messages[channelId] ?? []);

  void addMessage(Message msg) {
    final list = _messages[msg.channelId];
    if (list == null) return;
    list.add(msg);
    _broadcast(msg);
  }

  void addSocket(String channelId, WebSocketChannel channel) {
    _socketsByChannel.putIfAbsent(channelId, () => <WebSocketChannel>{});
    _socketsByChannel[channelId]!.add(channel);
  }

  void removeSocket(String channelId, WebSocketChannel channel) {
    _socketsByChannel[channelId]?.remove(channel);
  }

  void _broadcast(Message msg) {
    final sockets = _socketsByChannel[msg.channelId] ?? {};
    final payload = jsonEncode(msg.toJson());
    for (final ch in sockets) {
      ch.sink.add(payload);
    }
  }
}
