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
  bool errors = false;
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

      if (!errors) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(directoryPath)),
        );
      }
    }
  }

  Future<void> _clearVectorstore() async {
    final url = Uri.parse('http://localhost:3000/api/clearVstore');
    final Map<String, String> data = {
      'msg':'Invoke clear.'
    };
    try
    {  final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',  
        },
        body: jsonEncode(data),
    );

      if (response.statusCode != 200) {
        print('Request failed with status: ${response.statusCode}');
        setState(() {
          errors=true;
        });
      } else {
         setState(() {
          errors=false;
      });
      }
    } catch (error) {
      setState(() {
          errors=true;
      });
    }
  }


  Future<void> _updateVectorstore(String path) async {
    var files = Directory(path).listSync();

    try {
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
            setState(() {
              errors=true;
            });
            print('Failed to upload: $fileName');
          } else {
          setState(() {
          errors=false;
      });
      }
        }
      }
    }
    } catch (error) {
      setState(() {
          errors=true;
      });
    }


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LocalLlama RAG',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: isLoading ? null : () => _pickDirectory(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 78, 35, 131),
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text('Select Vectorstore Directory'),
            ),
            const SizedBox(height: 20),
            ((isLoading || errors)) ? Text(errors ? 'Server Error: Try again in a few moments' : 'Creating Vectorstore',
              style: const TextStyle(fontSize: 16, color: Color.fromARGB(255, 78, 35, 131)),
            ) : const Text(''),
          ],
        ),
      ),
    );
  }
}

