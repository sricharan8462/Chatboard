import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String boardName;
  ChatScreen({required this.boardName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<types.Message> _messages = [];
  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('messages_${widget.boardName}')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final msgs =
              snapshot.docs.map((doc) {
                return types.TextMessage(
                  id: doc.id,
                  text: doc['text'],
                  author: types.User(id: doc['userId']),
                  createdAt: doc['createdAt'],
                );
              }).toList();
          setState(() => _messages = msgs);
        });
  }

  void _handleSendPressed(types.PartialText message) {
    final msg = {
      'userId': user.uid,
      'text': message.text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    FirebaseFirestore.instance
        .collection('messages_${widget.boardName}')
        .add(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.boardName)),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        user: types.User(id: user.uid),
      ),
    );
  }
}
