import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart';

class PDFUploadService {
  Future<String> extractTextFromPDF(String fileUrl) async {
    try {
      print("Downloading PDF from: $fileUrl");
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/downloaded_file.pdf';

        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        print("PDF downloaded successfully: $filePath");

        // Verify file existence
        if (!await file.exists()) {
          throw Exception("Downloaded PDF file does not exist.");
        }

        // Check file size
        final fileSize = await file.length();
        print("PDF file size: $fileSize bytes");

        if (fileSize == 0) {
          throw Exception("Downloaded PDF file is empty.");
        }

        // Convert PDF pages to images
        List<String> imagePaths = await _convertPdfToImages(file);
        print("Generated Image Paths: $imagePaths");

        // Extract text from images
        String extractedText = await extractTextFromImages(imagePaths);
        print("Extracted Text: $extractedText");
        return extractedText;
      } else {
        throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print("Error: $e");
      return 'Error extracting text from PDF: $e';
    }
  }

  Future<List<String>> _convertPdfToImages(File pdfFile) async {
    print("Converting PDF to images...");

    final pdfBytes = await pdfFile.readAsBytes();
    final pdfDocument = await PdfDocument.openData(pdfBytes);

    final tempDir = await getTemporaryDirectory();
    List<String> imagePaths = [];

    for (int i = 1; i <= pdfDocument.pageCount; i++) {
      final page = await pdfDocument.getPage(i);
      final pdfPageImage = await page.render(
        width: (page.width * 2).toInt(),
        height: (page.height * 2).toInt(),
      );

      final image = await pdfPageImage.createImageIfNotAvailable();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      final imagePath = '${tempDir.path}/page_$i.png';
      final file = File(imagePath);
      await file.writeAsBytes(buffer);
      imagePaths.add(imagePath);

      image.dispose();
    }

    print("PDF conversion complete.");
    return imagePaths;
  }

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) return "";

    int half = (imagePaths.length / 2).ceil();
    List<String> firstHalf = imagePaths.sublist(0, half);
    List<String> secondHalf = imagePaths.sublist(half);

    Future<String> firstHalfText = _processImageBatch(
        firstHalf, "", "API_1");
    Future<String> secondHalfText = _processImageBatch(
        secondHalf, "", "API_2");

    List<String> results = await Future.wait([firstHalfText, secondHalfText]);
    return results.join();
  }

  Future<String> _processImageBatch(
      List<String> imagePaths, String apiKey, String apiLabel) async {
    String extractedText = "";

    for (String imagePath in imagePaths) {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        print("Error: Image $imagePath does not exist.");
        continue;
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [
                {"type": "DOCUMENT_TEXT_DETECTION"}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody["responses"] != null &&
            responseBody["responses"].isNotEmpty) {
          String text =
              responseBody["responses"][0]["fullTextAnnotation"]["text"] ?? "";
          print("Extracted text from $imagePath: $text");
          extractedText += "$text\n";
        } else {
          print("No text found in $imagePath");
        }
      } else {
        print("Error ${response.statusCode} for $imagePath: ${response.body}");
      }
    }
    return extractedText;
  }

  Future<String> sendToGeminiAPI(
      String assignmentText, String rubricText, String studentText) async {
    const apiKey = '';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/tunedModels/copy-of-analysis-model-pq5mo65ip7q1:generateContent?key=$apiKey';

    String prompt = '''
    Assignment Text:
    $assignmentText

    Rubric Text:
    $rubricText

    Student Submission Text:
    $studentText
    Analyze the student's submission based on the assignment text and rubric text. If the final answer is wrong, give step marks.
    Full marks for the assignment is in the rubrics.
    Be very liberal while giving marks.
    Give total marks only along with a short overall feedback of strong or weak topics.
    Follow this format:
    "Marks"_"Feedback"
    Always the output should of this format.
    ''';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty) {
          print(jsonResponse);
          return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      return 'Error analyzing submission';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
