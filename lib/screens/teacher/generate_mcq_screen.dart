import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:open_file/open_file.dart';

class GenerateMCQScreen extends StatefulWidget {
  @override
  _GenerateMCQScreenState createState() => _GenerateMCQScreenState();
}

class _GenerateMCQScreenState extends State<GenerateMCQScreen> {
  final TextEditingController _numQuestionsController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  bool _isLoading = false;

  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<String> fetchMCQsFromGemini(
      int numQuestions, String topic, String difficulty) async {
    const apiKey = '';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

    String prompt = """
      Generate strictly $numQuestions multiple-choice questions on the topic '$topic' with difficulty level '$difficulty'.
      Each question should have four options labeled A, B, C, and D, with one correct answer.
      Try to make length of the questions and options to be small.
      Return the output in a structured CSV format:
      Question,Option A,Option B,Option C,Option D,Answer
      Ensure that:
      - Each field is separated by a comma.
      - There are no extra line breaks inside a field.
      - Use double quotes to enclose any field containing a comma.
    """;

    final requestPayload = {
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestPayload),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'].isNotEmpty) {
          var firstCandidate = jsonResponse['candidates'][0];
          if (firstCandidate.containsKey('content')) {
            var content = firstCandidate['content'];
            if (content.containsKey('parts') && content['parts'].isNotEmpty) {
              return content['parts']
                  .map<String>((part) => part['text'].toString())
                  .join("\n");
            }
          }
        }
        return 'No valid content found in API response.';
      } else {
        return 'Error: ${response.statusCode}, Response: ${response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> generateAndSaveCSV() async {
    setState(() => _isLoading = true);
    try {
      await requestPermissions();
      int numQuestions = int.tryParse(_numQuestionsController.text) ?? 0;
      String topic = _topicController.text.trim();
      String difficulty = _difficultyController.text.trim();

      if (numQuestions <= 0 || topic.isEmpty || difficulty.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter valid details!")),
        );
        setState(() => _isLoading = false);
        return;
      }

      String content =
          await fetchMCQsFromGemini(numQuestions, topic, difficulty);
      if (content.isEmpty || content.startsWith("Error")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate content! Try again.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      List<String> lines =
          content.split("\n").where((line) => line.trim().isNotEmpty).toList();
      List<List<String>> mcqData = [];

      for (var line in lines) {
        List<String> values = line.split(",");
        if (values.length == 6) {
          mcqData.add(values.map((e) => e.trim()).toList());
        }
      }

      if (mcqData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Generated data is not in the correct format!")),
        );
        setState(() => _isLoading = false);
        return;
      }

      List<String> csvData = [];
      for (var mcq in mcqData) {
        csvData.add(mcq.map((e) => '"$e"').join(","));
      }

      Directory? downloadsDir = Directory("/storage/emulated/0/Download");
      if (!downloadsDir.existsSync()) {
        downloadsDir = await getExternalStorageDirectory();
      }
      String filePath = '${downloadsDir!.path}/MCQ_$topic.csv';
      final file = File(filePath);
      await file.writeAsString(csvData.join("\n"));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("CSV saved in Downloads: $filePath")),
      );
      OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving CSV: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generate MCQs")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _numQuestionsController,
                decoration: InputDecoration(labelText: "Number of Questions")),
            TextField(
                controller: _topicController,
                decoration: InputDecoration(labelText: "Enter Topic")),
            TextField(
                controller: _difficultyController,
                decoration: InputDecoration(labelText: "Difficulty Level")),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: generateAndSaveCSV, child: Text("Generate CSV")),
          ],
        ),
      ),
    );
  }
}
