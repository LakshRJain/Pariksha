import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class CreateTestScreen extends StatefulWidget {
  final Map<String, dynamic>? existingTest;
  final String classId;

  const CreateTestScreen({required this.classId, this.existingTest, super.key});

  @override
  _CreateTestScreenState createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _testDurationController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (index) => TextEditingController());
  int? _correctOption;
  String? _existingTestId; // To store the existing test's Firestore document ID
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  @override
  void dispose() {
    _testNameController.dispose();
    _testDurationController.dispose();
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingTest != null) {
      _existingTestId =
          widget.existingTest!['id']; // Store the existing test ID
      _testNameController.text = widget.existingTest!['name'] ?? '';
      _questions = List.from(widget.existingTest!['questions'] ?? []);

      print("hiiiiii");

      // Safely check and set start and end dates
      var startDateRaw = widget.existingTest!['startDateTime'];
      if (startDateRaw != null) {
        print("date1");
        if (startDateRaw is Timestamp) {
          _startDate = startDateRaw.toDate(); // Convert Firestore Timestamp
        } else if (startDateRaw is String) {
          try {
            _startDate = DateTime.parse(startDateRaw); // If it's an ISO string
          } catch (e) {
            print("Error parsing startDateTime string: $e");
          }
        } else if (startDateRaw is DateTime) {
          _startDate = startDateRaw; // If already converted
        }

        _startTime =
            _startDate != null ? TimeOfDay.fromDateTime(_startDate!) : null;
      }
      print("date");

      var endDateRaw = widget.existingTest!['endDateTime'];
      if (endDateRaw != null) {
        print("time");
        if (endDateRaw is Timestamp) {
          _endDate = endDateRaw.toDate();
        } else if (endDateRaw is String) {
          try {
            _endDate = DateTime.parse(endDateRaw);
          } catch (e) {
            print("Error parsing endDateTime string: $e");
          }
        } else if (endDateRaw is DateTime) {
          _endDate = endDateRaw;
        }

        _endTime = _endDate != null ? TimeOfDay.fromDateTime(_endDate!) : null;
      }
      print("time");

      // Populate test duration if exists
      if (widget.existingTest!['duration'] != null) {
        print("duration");
        _testDurationController.text =
            widget.existingTest!['duration'].toString();
      }
      print("duration");
    }
  }

  Future<void> _selectStartDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _startTime ?? TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _startDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _startTime = pickedTime;
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _endTime ?? TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _endDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _endTime = pickedTime;
        });
      }
    }
  }

  Future<void> _importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String csvString = await file.readAsString();

        // Print raw CSV content for debugging
        print('Raw CSV Content:\n$csvString');

        // Try different parsing strategies
        List<List<dynamic>> csvTable = [];

        try {
          // First, try with custom CSV converter that's more lenient
          csvTable = const CsvToListConverter(
            eol: '\n',
            fieldDelimiter: '\t', // Change from ',' to '\t'
            textDelimiter: '"',
            shouldParseNumbers: false,
          ).convert(csvString);
          print('CSV Content Preview:\n$csvString');
          print('Processed Rows: ${csvTable.length}');
          print(
              'First Row Columns: ${csvTable.isNotEmpty ? csvTable[0].length : "Empty"}');

          for (var row in csvTable) {
            print(row);
          }
        } catch (e) {
          print('First parsing method failed: 🟥$e');

          // Fallback: manual parsing
          csvTable = csvString.split('\n').map((line) {
            // Use regex to split while respecting quotes
            return RegExp(r',(?=(?:[^"]"[^"]")[^"]$)')
                .allMatches(line)
                .map((match) => line.substring(match.start, match.end).trim())
                .toList();
          }).toList();
        }

        // Enhanced debugging for column detection
        if (csvTable.isNotEmpty) {
          var firstRow = csvTable[0][0].split(',');
          print('fff');
          print(firstRow);
          print('Total Columns Detected: ${firstRow.length}');
          print('Detected Columns:');
          for (int i = 0; i < firstRow.length; i++) {
            print('Column $i: "${firstRow[i]}"');
          }
        }

        // Skip header row if it exists
        List<List<dynamic>> dataRows =
            csvTable.length > 1 ? csvTable.sublist(1) : csvTable;

        List<Map<String, dynamic>> importedQuestions = [];
        List<String> skippedRowReasons = [];

        for (var Trow in dataRows) {
          var row=Trow[0].split(',');
          // Detailed logging of row length and content
          print('Processing Row (Length: ${row.length}):');
          for (int i = 0; i < row.length; i++) {
            print('Column $i: "${row[i]}" (Type: ${row[i].runtimeType})');
          }

          // Ensure we have enough columns
          if (row.length < 6) {
            skippedRowReasons.add(
                'Row skipped: Insufficient columns (found ${row.length}, expected at least 6)');
            continue;
          }

          // Validate question and options are not empty
          if (row[0].toString().trim().isEmpty) {
            skippedRowReasons.add('Row skipped: Question is empty');
            continue;
          }

          // Check if options are not empty
          bool anyEmptyOption = false;
          for (int i = 1; i < 5; i++) {
            if (row[i].toString().trim().isEmpty) {
              skippedRowReasons.add('Row skipped: Option ${i - 1} is empty');
              anyEmptyOption = true;
              break;
            }
          }
          if (anyEmptyOption) continue;

          // Find the correct option index
          String correctAnswer = row[5].toString().toLowerCase().trim();
          int correctOptionIndex = -1;

          switch (correctAnswer) {
            case '0':
              correctOptionIndex = 0;
              break;
            case '1':
              correctOptionIndex = 1;
              break;
            case '2':
              correctOptionIndex = 2;
              break;
            case '3':
              correctOptionIndex = 3;
              break;
            default:
              skippedRowReasons.add(
                  'Row skipped: Invalid correct answer "$correctAnswer" (must be 0, 1, 2, or 3)');
              continue;
          }

          // Create the question map
          Map<String, dynamic> question = {
            'question': row[0].toString().trim(),
            'options': [
              row[1].toString().trim(),
              row[2].toString().trim(),
              row[3].toString().trim(),
              row[4].toString().trim(),
            ],
            'correct': correctOptionIndex,
          };

          importedQuestions.add(question);
        }

        // Update state with imported questions
        setState(() {
          _questions.addAll(importedQuestions);
        });

        // Prepare feedback message
        String message =
            '${importedQuestions.length} questions imported successfully';
        if (skippedRowReasons.isNotEmpty) {
          message += '\n\nSkipped Rows:';
          for (var reason in skippedRowReasons) {
            message += '\n- $reason';
          }
        }

        // Show success message
        _showSnackBar(message, Colors.green);

        // Print total imported questions
        print('Total Imported Questions: ${importedQuestions.length}');
        print('Skipped Row Reasons: $skippedRowReasons');
      }
    } catch (e) {
      // Show error message
      _showSnackBar('Error importing CSV: ${e.toString()}', Colors.red);
      print('CSV Import Error: $e');
    }
  }

  void _addQuestion() {
    if (_questionController.text.isNotEmpty && _correctOption != null) {
      _questions.add({
        'question': _questionController.text,
        'options':
            _optionControllers.map((controller) => controller.text).toList(),
        'correct': _correctOption,
      });
      _questionController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      setState(() {
        _correctOption = null;
      });
    } else {
      _showSnackBar(
          'Please fill all fields and select a correct option', Colors.amber);
    }
  }

  Future<void> _submitTest() async {
    if (_testNameController.text.isEmpty) {
      _showSnackBar('Please enter a test name', Colors.amber);
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Please select start and end date/time', Colors.amber);
      return;
    }

    // Validate test duration
    if (_testDurationController.text.isEmpty) {
      _showSnackBar('Please enter test duration in minutes', Colors.amber);
      return;
    }

    // Validate end date is after start date
    if (_endDate!.isBefore(_startDate!)) {
      _showSnackBar('End date must be after start date', Colors.amber);
      return;
    }
    if (_questions.isNotEmpty) {
      try {
        // Prepare test data for Firebase
        Map<String, dynamic> testData = {
          'name': _testNameController.text,
          'questions': _questions,
          'startDateTime': Timestamp.fromDate(_startDate!),
          'endDateTime': Timestamp.fromDate(_endDate!),
          'duration': int.parse(_testDurationController.text),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Check if this is an existing test or a new test
        if (_existingTestId != null && _existingTestId!.isNotEmpty) {
          // Update existing test
          await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('tests')
              .doc(_existingTestId)
              .update(testData);

          // Return the updated test data with the existing ID
          testData['id'] = _existingTestId;
        } else {
          // Create new test
          DocumentReference docRef = await FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('tests')
              .add(testData);

          // Add the new document ID to the test data
          testData['id'] = docRef.id;
        }

        Navigator.pop(context, testData);
      } catch (e) {
        _showSnackBar('Error saving test: ${e.toString()}', Colors.red);
      }
    } else {
      _showSnackBar('Please add at least one question', Colors.amber);
    }
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Create Test',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20, // Reduced from 22
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4, // Slightly reduced
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12.0, vertical: 8.0), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Name Input
              _buildTextField(
                controller: _testNameController,
                labelText: 'Test Name',
                icon: Icons.text_fields,
                color: Colors.blue.shade200,
              ),

              const SizedBox(height: 12), // Reduced height

              // Test Duration Input
              _buildTextField(
                controller: _testDurationController,
                labelText: 'Duration (minutes)',
                icon: Icons.timer,
                color: Colors.green.shade200,
              ),

              const SizedBox(height: 12),

              // Date and Time Selectors
              _buildDateTimeSelector(
                label: 'Start Date/Time',
                icon: Icons.calendar_today,
                color: Colors.purple.shade200,
                dateTime: _startDate,
                onTap: _selectStartDateTime,
              ),

              const SizedBox(height: 12),

              _buildDateTimeSelector(
                label: 'End Date/Time',
                icon: Icons.event_available,
                color: Colors.orange.shade200,
                dateTime: _endDate,
                onTap: _selectEndDateTime,
              ),

              const SizedBox(height: 12),

              // Question Container
              _buildQuestionContainer(),

              const SizedBox(height: 12),

              // Action Buttons (Compact Row)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCompactButton(
                      text: 'Import CSV',
                      icon: Icons.upload_file,
                      onPressed: _importFromCSV,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactButton(
                      text: 'Add Question',
                      icon: Icons.add,
                      onPressed: _addQuestion,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 8),
                    _buildCompactButton(
                      text: 'Submit Test',
                      icon: Icons.check,
                      onPressed: _submitTest,
                      color: Colors.green.shade700,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Questions List with Constrained Height
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height *
                      0.3, // Reduced from 0.4
                ),
                child: _buildQuestionsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
          color: Colors.white, fontSize: 14), // Reduced font size
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        prefixIcon: Icon(icon, color: color, size: 20),
        isDense: true, // More compact
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        // Rest of the decoration remains the same
      ),
    );
  }

  Widget _buildCompactButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: Colors.white, // Ensure icon is white for visibility
      ),
      label: Text(
        text,
        style: TextStyle(
            fontSize: 12,
            color: Colors.white, // Explicit white text
            fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white, // Ensures text and icon color
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 3, // Add some elevation for depth
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required IconData icon,
    required Color color,
    DateTime? dateTime,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey.shade900,
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                dateTime == null
                    ? label
                    : DateFormat('dd MMM yyyy HH:mm').format(dateTime),
                style: TextStyle(
                  color: dateTime == null ? Colors.grey.shade500 : Colors.white,
                ),
              ),
            ),
            Icon(Icons.edit_calendar, color: color),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildQuestionContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.shade200.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _questionController,
            labelText: 'Enter Question',
            icon: Icons.question_answer,
            color: Colors.cyan.shade200,
          ),
          ...List.generate(4, (index) => _buildOptionTile(index)),
        ],
      ),
    );
  }

  Widget _buildOptionTile(int index) {
    return ListTile(
      title: _buildTextField(
        controller: _optionControllers[index],
        labelText: 'Option ${index + 1}',
        icon: Icons.check_circle_outline,
        color: Colors.pink.shade200,
      ),
      leading: Radio<int>(
        value: index,
        groupValue: _correctOption,
        onChanged: (int? value) {
          setState(() {
            _correctOption = value;
          });
        },
        activeColor: Colors.pink.shade200,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildGradientButton(
          text: 'Import CSV',
          startColor: Colors.blue.shade900.withOpacity(0.5),
          endColor: Colors.cyan.shade900.withOpacity(0.5),
          onPressed: _importFromCSV,
        ),
        _buildGradientButton(
          text: 'Add Question',
          startColor: Colors.purple.shade900.withOpacity(0.5),
          endColor: Colors.indigo.shade900.withOpacity(0.5),
          onPressed: _addQuestion,
        ),
        _buildGradientButton(
          text: 'Submit Test',
          startColor: Colors.green.shade900.withOpacity(0.5),
          endColor: Colors.teal.shade900.withOpacity(0.5),
          onPressed: _submitTest,
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    return _questions.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              return _buildQuestionTile(index);
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            color: Colors.purple.shade200,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'No questions added',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your first question to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900.withOpacity(0.3),
            Colors.indigo.shade900.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ListTile(
        title: Text(
          _questions[index]['question'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            4,
            (optIndex) => Text(
              "${optIndex + 1}. ${_questions[index]['options'][optIndex]}",
              style: TextStyle(
                color: optIndex == _questions[index]['correct']
                    ? Colors.green.shade200
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red.shade200),
          onPressed: () => _deleteQuestion(index),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required Color startColor,
    required Color endColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 150,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
