import 'package:flutter/material.dart';

class CreateTestScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? existingQuestions;

  CreateTestScreen({this.existingQuestions});

  @override
  _CreateTestScreenState createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  List<Map<String, dynamic>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers =
      List.generate(4, (index) => TextEditingController());
  int? _correctOption;

  @override
  void initState() {
    super.initState();
    if (widget.existingQuestions != null) {
      _questions = List.from(widget.existingQuestions!);
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

  void _submitTest() {
    if (_questions.isNotEmpty) {
      Navigator.pop(context, _questions);
    } else {
      _showSnackBar('Please add at least one question', Colors.amber);
    }
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
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
      children: [
        _buildQuestionContainer(),
        const SizedBox(height: 20),
        _buildActionButtons(),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4, // Set a height
          child: _buildQuestionsList(),
        ),
      ],
    ),
  ),
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