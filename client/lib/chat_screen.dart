import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final String directoryPath;
  ChatScreen(this.directoryPath);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final List<int> _messageClasses = [];
  final ScrollController _scrollController = ScrollController();
  bool isTyping = false;
  bool isGenerating = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this, // Ensure this mixin is added to the class
    )..repeat(); // Repeats the animation continuously
  }

  void _getResponse() async {
  setState(() {
    isTyping = true;
  });

  List<String> payload = [];
  for (int i = _messages.length - 1; i >= 0; i -= 1) {
    payload.add(_messages[i]);
    if (payload.length == 5) {
      break;
    }
  }

  try {
    final request = http.Request("POST", Uri.parse('http://localhost:3000/api/llm'))
      ..headers['Content-Type'] = 'application/json; charset=UTF-8'
      ..body = jsonEncode(<String, List<String>>{
        'msgs': payload,
      });

    final response = await http.Client().send(request);

    _messages.add('');
    _messageClasses.add(2);
    setState(() {
      isTyping = false;  // Stop showing the typing indicator
      isGenerating=true;
    });
    response.stream.transform(utf8.decoder).listen(
      (chunk) {
        setState(() {
          _messages[_messages.length-1] += chunk;  // Add each chunk of data to the messages
        });
        _scrollToBottom();
      },
      onError: (error) {
        // Handle the error appropriately in your UI
        throw Exception('Error occurred: $error');
      },
      onDone: () {
        setState(() {
          isGenerating = false;  // Stop the loading indicator when the stream is done
        });
      },
      cancelOnError: true,
    );
    

  } catch (e) {
    setState(() {
      isTyping = false;
      isGenerating=false;
    });
    // Handle the error appropriately in your UI
    throw Exception('Error occurred: $e');
  }
}


  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(_controller.text);
        _messageClasses.add(1);
        _controller.clear();
        isTyping = true;
      });
      _scrollToBottom();
      _getResponse();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LocalLlama RAG', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'What can I do for you today?',
                  style: TextStyle(fontSize: 24, fontFamily: 'gidole'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_messages.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(8.0),
                itemCount: _messages.length + (isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && isTyping) {
                    // Show the animated typing indicator
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 14),
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (dotIndex) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                  child: Opacity(
                                    opacity: _animationController.value > (dotIndex / 3) ? 1.0 : 0.2,
                                    child: Text(
                                      '.',
                                      style: TextStyle(fontSize: 24, color: Colors.white),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    );
                  }

                  Alignment alignment;
                  MaterialAccentColor color;
                  if (_messageClasses[index] == 1) {
                    alignment = Alignment.centerRight;
                    color = Colors.blueAccent;
                  } else {
                    alignment = Alignment.centerLeft;
                    color = Colors.lightBlueAccent;
                  }
                  return Align(
                    alignment: alignment,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: SelectableText(
                        _messages[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    enabled: !isGenerating && !isTyping,
                    controller: _controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      _sendMessage(); // Send message when Enter is pressed
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
