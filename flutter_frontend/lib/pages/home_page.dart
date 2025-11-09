import 'package:flutter/material.dart';
import 'dart:ui';
import 'chat_detail_page.dart';
import 'profile_page.dart';
import '../services/api_client.dart';
import '../themes/colors.dart';
import '../widgets/frosted_glass_button.dart';
import '../widgets/frosted_glass_textfield.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  final _createRoomController = TextEditingController();
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final rooms = await apiClient.getRooms();
      setState(() {
        _rooms = rooms
            .map((r) => {
                  'id': r['id'] as int,
                  'name': r['name'] as String,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rooms: $e')),
        );
      }
    }
  }

  Future<void> _createRoom() async {
    final name = _createRoomController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room name cannot be empty')),
      );
      return;
    }

    try {
      await apiClient.createRoom(name);
      _createRoomController.clear();
      setState(() => _showCreateForm = false);
      await _loadRooms();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room created successfully')),
        );
      }
    } catch (e) {
      print('Error creating room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _createRoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grocery Ai',
          style: TextStyle(
            fontFamily: 'StackSansNotch',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF064E3B),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search rooms...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(0xFF064E3B).withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF064E3B).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(
                                      () => _showCreateForm = !_showCreateForm);
                                },
                                child: Center(
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showCreateForm)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        FrostedGlassTextField(
                          controller: _createRoomController,
                          placeholder: 'Enter room name...',
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FrostedGlassButton(
                                label: 'Create',
                                onPressed: _createRoom,
                                isPrimary: true,
                                backgroundColor: Color(0xFF10B981),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: FrostedGlassButton(
                                label: 'Cancel',
                                onPressed: () {
                                  setState(() => _showCreateForm = false);
                                  _createRoomController.clear();
                                },
                                isPrimary: false,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                Expanded(
                  child: _rooms.isEmpty
                      ? Center(
                          child: Text(
                            'No rooms yet. Create one to get started!',
                            style: TextStyle(color: kTextGray),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _rooms.length,
                          itemBuilder: (_, i) {
                            final room = _rooms[i];
                            return ListTile(
                              leading:
                                  Text('💬', style: TextStyle(fontSize: 24)),
                              title: Text(room['name']),
                              subtitle: Text('Tap to enter chat'),
                              trailing: Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(
                                      roomId: room['id'].toString(),
                                      roomName: room['name'],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
