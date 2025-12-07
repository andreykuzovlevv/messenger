class Channel {
  final String id;
  final String name;
  final DateTime createdAt;

  Channel({required this.id, required this.name, required this.createdAt});

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
}

class Message {
  final String id;
  final String channelId;
  final String text;
  final String author;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.channelId,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    channelId: json['channelId'] as String,
    text: json['text'] as String,
    author: json['author'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'channelId': channelId,
    'text': text,
    'author': author,
    'createdAt': createdAt.toIso8601String(),
  };
}
