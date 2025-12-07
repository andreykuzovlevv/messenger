import 'package:flutter/material.dart';
import 'package:shared/shared.dart'; // Channel model
import 'chat_api.dart';
import 'channel_page.dart';

class ChannelListPage extends StatefulWidget {
  final ChatApi api;
  final String nickname;

  const ChannelListPage({super.key, required this.api, required this.nickname});

  @override
  State<ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<ChannelListPage> {
  List<Channel> _channels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      final channels = await widget.api.getChannels();
      setState(() {
        _channels = channels;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createChannel() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New channel'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Channel name'),
          ),
          actions: [
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    print('Creating channel: $name');

    if (name == null) return;

    final newChannel = await widget.api.createChannel(name);
    print('Channel created: ${newChannel.id}');
    setState(() {
      _channels.add(newChannel);
    });
  }

  void _openChannel(Channel channel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelPage(
          channel: channel,
          api: widget.api,
          nickname: widget.nickname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Channels')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _channels.isEmpty
          ? const Center(child: Text('No channels yet.'))
          : RefreshIndicator(
              onRefresh: _loadChannels,
              child: ListView.separated(
                separatorBuilder: (context, index) => Container(
                  width: double.infinity,
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                itemCount: _channels.length,
                itemBuilder: (context, index) {
                  final channel = _channels[index];
                  return ListTile(
                    title: Text(channel.name),
                    subtitle: Text(channel.createdAt.toString()),
                    onTap: () => _openChannel(channel),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChannel,
        child: const Icon(Icons.add),
      ),
    );
  }
}
