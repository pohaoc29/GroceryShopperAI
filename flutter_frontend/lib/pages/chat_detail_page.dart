import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../models/message.dart';
import '../themes/colors.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/frosted_glass_textfield.dart';

class ChatDetailPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatDetailPage({required this.roomId, required this.roomName});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  late WebSocketChannel _channel;
  final _messageController = TextEditingController();
  final _messages = <Message>[];
  late String _currentUsername;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Token not found, please login again')),
        );
        return;
      }

      _currentUsername = getUsernameFromToken(token) ?? 'User';

      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl?token=$token'),
      );

      await _loadMessages();

      _channel.stream.listen(
        (event) {
          _handleWebSocketMessage(event);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket closed');
        },
      );

      if (mounted) {
        setState(() => _isConnecting = false);
      }
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final res = await apiClient.getRoomMessages(int.parse(widget.roomId));
      _messages.clear();
      for (var item in res) {
        _messages.add(Message.fromJson(item));
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _handleWebSocketMessage(dynamic event) {
    try {
      final data = jsonDecode(event);

      if (data['type'] == 'message') {
        final msg = Message.fromJson(data['message']);
        if (mounted) {
          setState(() {
            _messages.add(msg);
          });
        }
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await apiClient.postRoomMessage(int.parse(widget.roomId), text);
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showInviteDialog() {
    final inviteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite User to Room'),
        content: TextField(
          controller: inviteController,
          decoration: InputDecoration(
            hintText: 'Enter username',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final username = inviteController.text.trim();
              if (username.isNotEmpty) {
                await _inviteUser(username);
                if (mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Invite'),
          ),
        ],
      ),
    );
  }

  Future<void> _inviteUser(String username) async {
    try {
      await apiClient.inviteToRoom(int.parse(widget.roomId), username);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User $username invited successfully')),
        );
      }
    } catch (e) {
      print('Error inviting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite user: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - ${widget.roomName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isConnecting
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: kTextGray),
                        ),
                      )
                    : ListView.builder(
                        reverse: false,
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isCurrentUser =
                              msg.username == _currentUsername;

                          return Align(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrentUser ? kUserBubble : kBotBubble,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Column(
                                crossAxisAlignment: isCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isCurrentUser)
                                    Text(
                                      msg.username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: kTextDark,
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Text(
                                    msg.content,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: kTextDark,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    msg.formattedTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: kTextGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FrostedGlassTextField(
                    controller: _messageController,
                    placeholder: 'Type a message...',
                  ),
                ),
                SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _sendMessage,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
