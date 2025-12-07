import 'dart:convert';
import 'dart:io';
import 'package:backend/chat_store.dart';
import 'package:dart_frog/dart_frog.dart';

final _store = ChatStore.instance;

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method == HttpMethod.get) {
    print('Fetching channels');
    final channels = _store.getChannels();
    return Response.json(body: channels.map((c) => c.toJson()).toList());
  }

  if (request.method == HttpMethod.post) {
    print('Creating channel');
    final body = await request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final name = data['name'] as String;
    print('channel name: $name');
    final channel = _store.createChannel(name);
    return Response.json(
        body: channel.toJson(), statusCode: HttpStatus.created);
  }

  if (request.method == HttpMethod.options) {
    // Preflight request - handled by middleware, but keep for safety
    return Response(statusCode: HttpStatus.ok);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
