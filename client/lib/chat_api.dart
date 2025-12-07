import 'dart:convert';
import 'package:shared/shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class ChatApi {
  final String baseUrl; // e.g. 'http://localhost:8080'

  ChatApi(this.baseUrl);

  Future<List<Channel>> getChannels() async {
    final res = await http.get(Uri.parse('$baseUrl/channels'));
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Channel> createChannel(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/channels'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return Channel.fromJson(data);
  }

  Future<List<Message>> getMessages(String channelId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/channels/$channelId/messages'),
    );
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  WebSocketChannel connectToChannel(String channelId) {
    final uri = Uri.parse(
      baseUrl.replaceFirst('http', 'ws') + '/ws/$channelId',
    );
    return WebSocketChannel.connect(uri);
  }
}
