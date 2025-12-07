import 'package:backend/chat_store.dart';
import 'package:dart_frog/dart_frog.dart';

final _store = ChatStore.instance;

Future<Response> onRequest(RequestContext context, String id) async {
  final messages = _store.getMessages(id);
  return Response.json(body: messages.map((m) => m.toJson()).toList());
}
