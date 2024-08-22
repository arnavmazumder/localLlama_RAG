import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:file_picker/file_picker.dart';

class DashboardScreen extends StatelessWidget {
  void _pickDirectory(BuildContext context) async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      // Process the directory to create a vector store
      await _makeVectorstore(directoryPath);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(directoryPath)),
      );
    }
  }

  Future<void> _makeVectorstore(String path) async {
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Back, Sir',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _pickDirectory(context),
              child: Text('Select Directory and Start'),
            ),
          ],
        ),
      ),
    );
  }
}

