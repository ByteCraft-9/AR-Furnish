import 'package:ar_furnish/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class FirebaseMessage {
  final String id;
  final String message;
  final String senderId;
  final Timestamp timestamp;
  final bool isRead;
  final String? attachment;
  final String? attachmentType;
  final String chatId;
  final dynamic metadata;

  FirebaseMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.timestamp,
    required this.isRead,
    required this.chatId,
    this.attachment,
    this.attachmentType,
    this.metadata,
  });

  factory FirebaseMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FirebaseMessage(
      id: doc.id,
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      chatId: data['chatId'] ?? '',
      attachment: data['attachment'],
      attachmentType: data['attachmentType'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderId': senderId,
      'timestamp': timestamp,
      'isRead': isRead,
      'chatId': chatId,
      'attachment': attachment,
      'attachmentType': attachmentType,
      'metadata': metadata,
    };
  }
}

class ChatScreen extends StatefulWidget {
  final int productId;

  const ChatScreen({super.key, required this.productId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<FirebaseMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _chatId;
  StreamSubscription? _messagesSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Remove the local initial message, we'll save it to the database
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_auth.currentUser == null) {
        _showError('You must be logged in to use chat');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = _auth.currentUser!.uid;

      // Check if a chat already exists for this user and product
      final existingChatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      String? chatId;

      // Look for a chat with this product
      for (var doc in existingChatsQuery.docs) {
        final data = doc.data();
        if (data['metadata'] != null &&
            data['metadata']['productId'] != null &&
            data['metadata']['productId'] == widget.productId.toString()) {
          chatId = doc.id;
          break;
        }
      }

      // If no existing chat, create a new one with initial message
      if (chatId == null) {
        chatId = await _createNewChat(userId);
      }

      setState(() {
        _chatId = chatId;
        _isLoading = false;
      });

      // Start listening to messages
      _listenToMessages();
    } catch (e) {
      print('Error initializing chat: $e');
      _showError('Failed to initialize chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _createNewChat(String userId) async {
    // Default to customer support user ID
    const String supportUserId = 'QU6uSOmqX0cp8s4PotEGpZ5ut613';

    // Create a new chat document
    final chatDocRef = await _firestore.collection('chats').add({
      'participants': [userId, supportUserId],
      'lastMessage': 'Inquiry about product ID: ${widget.productId}',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {
        userId: 0,
        supportUserId: 1,
      },
      'chatType': 'customer',
      'metadata': {
        'productId': widget.productId.toString(),
      },
    });

    // Add initial message to database
    await _firestore.collection('chatMessages').add({
      'message': 'Inquiry about product ID: ${widget.productId}',
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'chatId': chatDocRef.id,
      'attachment': null,
      'attachmentType': null,
      'metadata': null,
    });

    return chatDocRef.id;
  }

  void _listenToMessages() {
    if (_chatId == null) return;

    // Cancel any existing subscription
    _messagesSubscription?.cancel();

    // Listen to messages for this chat
    _messagesSubscription = _firestore
        .collection('chatMessages')
        .where('chatId', isEqualTo: _chatId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => FirebaseMessage.fromFirestore(doc))
          .toList();

      setState(() {
        // Replace all messages with those from the database
        _messages = messages;
      });

      _scrollToBottom();
      _markMessagesAsRead();
    }, onError: (error) {
      print('Error listening to messages: $error');
      _showError('Failed to load messages');
    });
  }

  void _markMessagesAsRead() async {
    if (_chatId == null || _auth.currentUser == null) return;

    try {
      final userId = _auth.currentUser!.uid;
      final batch = _firestore.batch();
      bool hasUnreadMessages = false;

      // Get all unread messages sent by other users
      final unreadMessagesQuery = await _firestore
          .collection('chatMessages')
          .where('chatId', isEqualTo: _chatId)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: userId)
          .get();

      for (var doc in unreadMessagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
        hasUnreadMessages = true;
      }

      if (hasUnreadMessages) {
        // Also update the unread count in the chat document
        final chatDoc = _firestore.collection('chats').doc(_chatId);
        final chatData = (await chatDoc.get()).data();

        if (chatData != null && chatData['unreadCount'] != null) {
          final unreadCount =
              Map<String, dynamic>.from(chatData['unreadCount']);
          unreadCount[userId] = 0;
          batch.update(chatDoc, {'unreadCount': unreadCount});
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _chatId == null || _auth.currentUser == null)
      return;

    _messageController.clear();

    try {
      final userId = _auth.currentUser!.uid;
      final participants =
          (await _firestore.collection('chats').doc(_chatId).get())
              .data()?['participants'] as List<dynamic>;

      // Find the other participant(s)
      final otherParticipants = participants.where((p) => p != userId).toList();

      if (otherParticipants.isEmpty) {
        _showError('No recipients found for this chat');
        return;
      }

      // Create message document
      await _firestore.collection('chatMessages').add({
        'message': messageText,
        'senderId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'chatId': _chatId,
        'attachment': null,
        'attachmentType': null,
        'metadata': null,
      });

      // Update the chat document
      final chatDoc = _firestore.collection('chats').doc(_chatId);
      final chatData = (await chatDoc.get()).data();

      if (chatData != null) {
        final unreadCount =
            Map<String, dynamic>.from(chatData['unreadCount'] ?? {});

        // Increment unread count for other participants
        for (var participantId in otherParticipants) {
          unreadCount[participantId] = (unreadCount[participantId] ?? 0) + 1;
        }

        await chatDoc.update({
          'lastMessage': messageText,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'unreadCount': unreadCount,
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      _showError('Failed to send message');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Inquiry'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(FirebaseMessage message) {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final isSent = message.senderId == currentUserId;

    String timeText = '';
    final dateTime = message.timestamp.toDate();
    timeText = DateFormat('h:mm a').format(dateTime);

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSent ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isSent ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeText,
              style: TextStyle(
                color: isSent ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              maxLines: null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
