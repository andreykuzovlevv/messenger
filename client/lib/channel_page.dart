import 'dart:convert';

import 'package:client/chat_api.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shimmer/shimmer.dart';

class ChannelPage extends StatefulWidget {
  final Channel channel;
  final ChatApi api;
  final String nickname;

  const ChannelPage({
    super.key,
    required this.channel,
    required this.api,
    required this.nickname,
  });

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  late WebSocketChannel _channel;
  final _messages = <Message>[];
  final _controller = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _connectSocket();
  }

  Future<void> _loadInitial() async {
    final msgs = await widget.api.getMessages(widget.channel.id);

    setState(() {
      _messages.addAll(msgs);
      _isLoading = false;
    });
  }

  void _connectSocket() {
    _channel = widget.api.connectToChannel(widget.channel.id);

    _channel.stream.listen((data) {
      final map = jsonDecode(data as String) as Map<String, dynamic>;
      final msg = Message.fromJson(map);
      setState(() {
        _messages.add(msg);
      });
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final payload = {'text': text, 'author': widget.nickname};

    _channel.sink.add(jsonEncode(payload));
    _controller.clear();
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.channel.name)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildSkeletonShimmer(colorScheme)
                : ListView.separated(
                    separatorBuilder: (context, index) => Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(left: 68),
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          msg.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.outline,
                          ),
                        ),
                        subtitle: Text(msg.text),
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',

                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonShimmer(ColorScheme colorScheme) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainer,
      child: ListView.separated(
        separatorBuilder: (context, index) => Container(
          width: double.infinity,
          margin: EdgeInsets.only(left: 68),
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(backgroundColor: Colors.white),
            title: Container(
              height: 12,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
