import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
        title: const Text(
          'Create Test',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test Name Input
              _buildTextField(
                controller: _testNameController,
                labelText: 'Enter Test Name',
                icon: Icons.text_fields,
                color: Colors.blue.shade200,
              ),

              const SizedBox(height: 20),

              // Test Duration Input
              _buildTextField(
                controller: _testDurationController,
                labelText: 'Test Duration (minutes)',
                icon: Icons.timer,
                color: Colors.green.shade200,
              ),

              const SizedBox(height: 20),

              // Start Date and Time
              _buildDateTimeSelector(
                label: 'Start Date and Time',
                icon: Icons.calendar_today,
                color: Colors.purple.shade200,
                dateTime: _startDate,
                onTap: _selectStartDateTime,
              ),

              const SizedBox(height: 20),

              // End Date and Time
              _buildDateTimeSelector(
                label: 'End Date and Time',
                icon: Icons.event_available,
                color: Colors.orange.shade200,
                dateTime: _endDate,
                onTap: _selectEndDateTime,
              ),

              const SizedBox(height: 20),

              // Existing question creation logic remains the same
              _buildQuestionContainer(),

              const SizedBox(height: 20),

              _buildActionButtons(),

              const SizedBox(height: 20),

              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _buildQuestionsList(),
              ),
            ],
          ),
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required Color color,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
