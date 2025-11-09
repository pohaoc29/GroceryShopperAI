import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// CONFIG
const bool useAndroidEmulator = false;
final String apiBase = useAndroidEmulator
    ? 'http://10.0.2.2:8000/api'
    : 'http://localhost:8000/api';
final String wsUrl =
    useAndroidEmulator ? 'ws://10.0.2.2:8000/ws' : 'ws://localhost:8000/ws';

final storage = FlutterSecureStorage();

// Helper: 從 JWT token 中解析用戶名稱
String? getUsernameFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    final decoded =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final json = jsonDecode(decoded);
    return json['sub']; // JWT 的 "sub" 欄位就是 username
  } catch (e) {
    print('[JWT] Error parsing token: $e');
    return null;
  }
}

// Color Constants
const Color kPrimary = Color(0xFF064E3B);
const Color kSecondary = Color(0xFF10B981);
const Color kBgLight = Color(0xFFF3F4F6);
const Color kBgWhite = Color(0xFFFFFFFF);
const Color kTextDark = Color(0xFF111827);
const Color kTextGray = Color(0xFF6B7280);
const Color kTextLight = Color(0xFF9CA3AF);
const Color kErrorRed = Color(0xFFDC2626);
const Color kUserBubble = Color(0xFFDBEAFE);
const Color kBotBubble = Color(0xFFE8F5E9);

class ApiClient {
  String? token;

  Future<Map<String, String>> _headers() async {
    final h = {'Content-Type': 'application/json'};
    final t = token ?? await storage.read(key: 'token');
    print(
        '[ApiClient] Token: ${t != null ? "found (${t.substring(0, 20)}...)" : "null"}');
    if (t != null) h['Authorization'] = 'Bearer $t';
    return h;
  }

  Future<Map<String, dynamic>> post(String path, Map body) async {
    print('[ApiClient] POST $path with body: $body');
    final res = await http.post(Uri.parse(apiBase + path),
        headers: await _headers(), body: jsonEncode(body));
    print('[ApiClient] POST response: ${res.statusCode}');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      String msg = res.body;
      try {
        final j = jsonDecode(res.body);
        if (j is Map && (j['detail'] != null || j['error'] != null)) {
          msg = (j['detail'] ?? j['error']).toString();
        } else {
          msg = jsonEncode(j);
        }
      } catch (_) {}
      throw Exception('HTTP ${res.statusCode}: $msg');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res =
        await http.get(Uri.parse(apiBase + path), headers: await _headers());
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

final apiClient = ApiClient();

class Message {
  final String id;
  final String content;
  final bool isBot;
  final String username;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.isBot,
    required this.username,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'].toString(),
        content: j['content'] ?? '',
        isBot: j['is_bot'] ?? false,
        username: j['username'] ?? 'Unknown',
        createdAt:
            DateTime.parse(j['created_at'] ?? DateTime.now().toIso8601String()),
      );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery AI',
      theme: ThemeData(
        primaryColor: kPrimary,
        scaffoldBackgroundColor: kBgLight,
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}

// ============================================================================
// LOGIN PAGE
// ============================================================================

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _usernameCtl, _passwordCtl;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _usernameCtl = TextEditingController();
    _passwordCtl = TextEditingController();
  }

  Future<void> _login() async {
    if (_usernameCtl.text.isEmpty || _passwordCtl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final res = await apiClient.post('/login', {
        'username': _usernameCtl.text,
        'password': _passwordCtl.text,
      });
      final token = res['token'];
      await storage.write(key: 'token', value: token);
      apiClient.token = token;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ChatPage()),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_usernameCtl.text.isEmpty || _passwordCtl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final res = await apiClient.post('/signup', {
        'username': _usernameCtl.text,
        'password': _passwordCtl.text,
      });
      final token = res['token'];
      await storage.write(key: 'token', value: token);
      apiClient.token = token;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ChatPage()),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              SizedBox(height: 40),
              // Logo Placeholder
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: kTextLight, width: 2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text(
                    '🛒',
                    style: TextStyle(fontSize: 36),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Title
              Text(
                'Grocery AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                  fontFamily: 'StackSans',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Smart Shopping Assistant',
                style: TextStyle(
                  fontSize: 14,
                  color: kTextGray,
                  fontFamily: 'StackSansText',
                ),
              ),
              SizedBox(height: 48),
              // Username Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextDark,
                    fontFamily: 'StackSans',
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Username Input
              FrostedGlassTextField(
                controller: _usernameCtl,
                placeholder: 'Enter your username',
                enabled: !_isLoading,
              ),
              SizedBox(height: 16),
              // Password Label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextDark,
                    fontFamily: 'StackSans',
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Password Input
              FrostedGlassTextField(
                controller: _passwordCtl,
                placeholder: 'Enter your password',
                obscureText: true,
                enabled: !_isLoading,
              ),
              SizedBox(height: 8),
              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 12,
                    color: kPrimary,
                    decoration: TextDecoration.underline,
                    fontFamily: 'StackSansText',
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Error Message
              if (_errorMsg != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: TextStyle(
                      fontSize: 12,
                      color: kErrorRed,
                      fontFamily: 'StackSansText',
                    ),
                  ),
                ),
              SizedBox(height: 24),
              // Login Button
              FrostedGlassButton(
                label: _isLoading ? 'Logging In...' : 'Log In',
                onPressed: _isLoading ? null : _login,
                isPrimary: true,
              ),
              SizedBox(height: 12),
              // Sign Up Button
              FrostedGlassButton(
                label: _isLoading ? 'Creating...' : 'Create Account',
                onPressed: _isLoading ? null : _signup,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }
}

// ============================================================================
// FROSTED GLASS BUTTON
// ============================================================================

class FrostedGlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const FrostedGlassButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  State<FrostedGlassButton> createState() => _FrostedGlassButtonState();
}

class _FrostedGlassButtonState extends State<FrostedGlassButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDisabled),
                border: Border.all(
                  color: _getBorderColor(),
                  width: widget.isPrimary ? 1 : 2,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _getShadowColor(),
                    blurRadius: _isHovered ? 12 : 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getTextColor(isDisabled),
                    fontFamily: 'StackSans',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDisabled) {
    if (isDisabled) {
      return Color.fromARGB(102, 107, 114, 128);
    }
    if (widget.isPrimary) {
      return Color.fromARGB(230, 6, 78, 59);
    } else {
      return Color.fromARGB(26, 255, 255, 255);
    }
  }

  Color _getBorderColor() {
    if (widget.isPrimary) {
      return Color.fromARGB(51, 255, 255, 255);
    } else {
      return Color.fromARGB(128, 6, 78, 59);
    }
  }

  Color _getShadowColor() {
    if (widget.isPrimary) {
      return Color.fromARGB(26, 6, 78, 59);
    } else {
      return Color.fromARGB(13, 255, 255, 255);
    }
  }

  Color _getTextColor(bool isDisabled) {
    if (isDisabled) return Colors.grey;
    return widget.isPrimary ? kBgWhite : kPrimary;
  }
}

// ============================================================================
// FROSTED GLASS TEXT FIELD
// ============================================================================

class FrostedGlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final bool enabled;

  const FrostedGlassTextField({
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  State<FrostedGlassTextField> createState() => _FrostedGlassTextFieldState();
}

class _FrostedGlassTextFieldState extends State<FrostedGlassTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: _focusNode.hasFocus ? 10 : 8,
          sigmaY: _focusNode.hasFocus ? 10 : 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _focusNode.hasFocus
                ? Color.fromARGB(242, 255, 255, 255)
                : Color.fromARGB(204, 255, 255, 255),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? Color.fromARGB(204, 6, 78, 59)
                  : Color.fromARGB(128, 229, 231, 235),
              width: _focusNode.hasFocus ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (_focusNode.hasFocus)
                BoxShadow(
                  color: Color.fromARGB(26, 6, 78, 59),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              BoxShadow(
                color: Color.fromARGB(10, 0, 0, 0),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            style: TextStyle(
              fontSize: 14,
              color: kTextDark,
              fontFamily: 'StackSansText',
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(153, 155, 163, 175),
                fontFamily: 'StackSansText',
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CHAT PAGE
// ============================================================================

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Message> _messages = [];
  late TextEditingController _inputCtl;
  WebSocketChannel? _wsChannel;
  bool _isLoading = true;
  String? _currentUsername; // 儲存當前登入用戶名稱

  @override
  void initState() {
    super.initState();
    _inputCtl = TextEditingController();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeToken();
    await _loadMessages();
    _connectWebSocket();
  }

  Future<void> _initializeToken() async {
    final token = await storage.read(key: 'token');
    print(
        '[ChatPage] _initializeToken: read token = ${token != null ? "found (${token.substring(0, 20)}...)" : "null"}');
    if (token != null) {
      apiClient.token = token;
      _currentUsername = getUsernameFromToken(token);
      print('[ChatPage] Token set to apiClient, username: $_currentUsername');
    }
  }

  Future<void> _loadMessages() async {
    try {
      print('[ChatPage] Loading messages...');
      final res = await apiClient.get('/messages');
      print('[ChatPage] Got response: $res');
      final msgs =
          (res['messages'] as List).map((m) => Message.fromJson(m)).toList();
      print('[ChatPage] Parsed ${msgs.length} messages');
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    } catch (e) {
      print('[ChatPage] Error loading messages: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  void _connectWebSocket() {
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data);
            print('[WS] Received: $json');

            // Handle message type
            if (json is Map && json['type'] == 'message') {
              final msg = Message.fromJson(json['message']);
              setState(() => _messages.add(msg));
              print('[WS] Message added: ${msg.content}');
            }
          } catch (e) {
            print('[WS] Error parsing message: $e');
          }
        },
        onError: (e) => print('[WS] error: $e'),
        onDone: () => print('[WS] closed'),
      );
    } catch (e) {
      print('[WS] connection failed: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtl.text.trim();
    if (text.isEmpty) return;

    print('[ChatPage] _sendMessage: sending "$text"');
    _inputCtl.clear();
    try {
      await apiClient.post('/messages', {'content': text});
      print('[ChatPage] Message sent successfully');
    } catch (e) {
      print('[ChatPage] Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgWhite,
        elevation: 1,
        title: Text(
          'GroceryChat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kPrimary,
            fontFamily: 'StackSans',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () async {
            await storage.delete(key: 'token');
            apiClient.token = null;
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: kPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (_, i) =>
                        _buildMessage(_messages[_messages.length - 1 - i]),
                  ),
          ),
          // Input Area
          Container(
            color: kBgWhite,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Text('😀', style: TextStyle(fontSize: 24)),
                  onPressed: () {},
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(204, 255, 255, 255),
                          border: Border.all(
                            color: Color.fromARGB(128, 229, 231, 235),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _inputCtl,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'StackSansText',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: kTextLight,
                              fontFamily: 'StackSansText',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: kPrimary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message msg) {
    // 判斷這條訊息是否來自當前用戶
    final isCurrentUser = msg.username == _currentUsername;

    // 當前用戶的訊息顯示在右側（藍色），其他訊息在左側（綠色）
    final isRight = isCurrentUser;
    final bubbleColor = isRight ? kUserBubble : kBotBubble;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              '${msg.username} • ${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: kTextLight,
                fontFamily: 'StackSansText',
              ),
            ),
            SizedBox(height: 4),
            Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextDark,
                  fontFamily: 'StackSansText',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputCtl.dispose();
    _wsChannel?.sink.close();
    super.dispose();
  }
}
