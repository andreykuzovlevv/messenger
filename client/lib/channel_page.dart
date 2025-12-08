import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:client/chat_api.dart';
import 'package:shared/shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _SendIntent extends Intent {
  const _SendIntent();
}

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
  final _scrollController = ScrollController();
  bool _autoScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _loadInitial();
    _connectSocket();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final threshold = 50.0; // Threshold in pixels from the bottom

      // If user is near the bottom, enable auto-scroll
      if (maxScroll - currentScroll <= threshold) {
        if (!_autoScrollEnabled) {
          setState(() {
            _autoScrollEnabled = true;
          });
        }
      } else {
        // If user scrolled up, disable auto-scroll
        if (_autoScrollEnabled) {
          setState(() {
            _autoScrollEnabled = false;
          });
        }
      }
    });
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients && _autoScrollEnabled) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _loadInitial() async {
    final msgs = await widget.api.getMessages(widget.channel.id);
    setState(() {
      _messages.addAll(msgs);
    });
    // Wait for the next frame to ensure ListView is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
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
      // Wait for the next frame to ensure ListView is updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToEnd();
      });
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final payload = {'text': text, 'author': widget.nickname};

    _channel.sink.add(jsonEncode(payload));
    _controller.clear();
    // When user sends a message, ensure auto-scroll is enabled and scroll to end
    setState(() {
      _autoScrollEnabled = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToEnd();
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _controller.dispose();
    _scrollController.dispose();
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
            child: ListView.separated(
              controller: _scrollController,
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
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
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
                    child: Shortcuts(
                      shortcuts: {
                        LogicalKeySet(LogicalKeyboardKey.enter): _SendIntent(),
                      },
                      child: Actions(
                        actions: {
                          _SendIntent: CallbackAction<_SendIntent>(
                            onInvoke: (_) {
                              if (_controller.text.trim().isNotEmpty) {
                                _send();
                              }
                              return null;
                            },
                          ),
                        },
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _send(),
                          maxLines: 5,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
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
}
