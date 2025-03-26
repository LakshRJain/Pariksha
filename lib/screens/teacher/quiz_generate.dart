import 'package:flutter/material.dart';
import 'package:classcare/screens/teacher/createTestScreen.dart';

class quiz_generate extends StatefulWidget {
  @override
  _quiz_generateState createState() => _quiz_generateState();
}

class _quiz_generateState extends State<quiz_generate> {
  List<Map<String, dynamic>> _tests = [];

  void _navigateToCreateTest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateTestScreen()),
    );

    if (result != null) {
      setState(() {
        _tests.add({'name': 'Test ${_tests.length + 1}', 'questions': result});
      });
    }
  }

  void _editTest(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTestScreen(
          existingQuestions: _tests[index]['questions'],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _tests[index]['questions'] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
      Navigator.pop(context);
    },
  ),
  title: const Text(
    'Quiz',
    style: TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  ),
),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildGradientButton(
                text: 'Create New Test',
                startColor: Colors.purple.shade900.withOpacity(0.5),
                endColor: Colors.indigo.shade900.withOpacity(0.5),
                onPressed: _navigateToCreateTest,
              ),
            ),
            Expanded(
              child: _tests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _tests.length,
                      itemBuilder: (context, index) {
                        return _buildTestTile(index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz,
            color: Colors.purple.shade200,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'No tests created yet',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Click "Create New Test" to get started',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTile(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          _tests[index]['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${_tests[index]['questions'].length} Questions',
          style: TextStyle(
            color: Colors.grey.shade400,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade200),
              onPressed: () => _editTest(index),
            ),
            IconButton(
              icon: Icon(Icons.remove_red_eye, color: Colors.green.shade200),
              onPressed: () {
                // TODO: Implement view test details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'View Test Details feature coming soon',
                      style: TextStyle(color: Colors.black),
                    ),
                    backgroundColor: Colors.blue.shade100,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
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
      width: double.infinity,
      height: 60,
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
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}