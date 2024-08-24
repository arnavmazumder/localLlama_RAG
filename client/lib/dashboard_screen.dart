import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;


class DashboardScreen extends StatefulWidget {

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = false;

  void _pickDirectory(BuildContext context) async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();
    if (directoryPath != null) {
      // Process the directory to create a vector store
      setState(() {
        isLoading=true;
      });
      await _clearVectorstore();
      await _updateVectorstore(directoryPath);
      setState(() {
        isLoading=false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(directoryPath)),
      );
    }
  }

  Future<void> _clearVectorstore() async {
    final url = Uri.parse('http://localhost:3000/api/clearVstore');
    final Map<String, String> data = {
      'msg':'Invoke clear.'
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',  
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      print('Request failed with status: ${response.statusCode}');
    }
  }


  Future<void> _updateVectorstore(String path) async {
    var files = Directory(path).listSync();

    for (var f in files) {
      if (!(f is Directory)) {
        String fileName = f.path.split('/').last;
        if (fileName[0] != '.') {
          var request = http.MultipartRequest(
            'POST',
            Uri.parse('http://localhost:3000/api/updateVstore'),
          );

          // Add the file to the request
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            f.path,
            filename: fileName,
          ));

          // Send the request
          var response = await request.send();

          if (response.statusCode != 200) {
            print('Failed to upload: $fileName');
          }
        }
      }
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LocalLlama RAG',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(height: 40),

            ElevatedButton(
              onPressed: isLoading ? null : () => _pickDirectory(context),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: const Color.fromARGB(255, 0, 191, 255),
                        strokeWidth: 2.0,
                      ),
                    )
                  : Text('Select Vectorstore Directory'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

