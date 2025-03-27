import 'package:classcare/screens/teacher/generate_mcq_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classcare/screens/teacher/createTestScreen.dart';

class quiz_generate extends StatefulWidget {
  final String classId;

  const quiz_generate({
    super.key,
    required this.classId,
  });
  @override
  _quiz_generateState createState() => _quiz_generateState();
}

class _quiz_generateState extends State<quiz_generate> {
  List<Map<String, dynamic>> _tests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTests();
  }

  Future<void> _fetchTests() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use snapshots() for real-time updates
      FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('tests')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .listen((QuerySnapshot querySnapshot) {
        setState(() {
          _tests = querySnapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'name': doc['name'] ?? 'Unnamed Test',
              'questions': doc['questions'] ?? [],
              'updatedAt': doc['updatedAt'],
              'startDateTime': convertTimestampToDateTime(doc['startDateTime']),
              'endDateTime': convertTimestampToDateTime(doc['endDateTime']),
              'duration': doc['duration'],
            };
          }).toList();
          _isLoading = false;
          print(_tests);
        });
      }, onError: (error) {
        print("Error fetching tests: $error");
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(error.toString());
      });
    } catch (e) {
      print("Unexpected error: $e");
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  DateTime? convertTimestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is Timestamp) {
      return timestamp.toDate(); // Convert Firestore Timestamp to DateTime
    } else if (timestamp is String) {
      try {
        return DateTime.parse(
            timestamp); // If stored as a string in ISO 8601 format
      } catch (e) {
        print("Error parsing timestamp string: $e");
        return null;
      }
    }

    return null;
  }

  void _showErrorSnackBar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error: $errorMessage',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToCreateTest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CreateTestScreen(
                classId: widget.classId,
              )),
    );

    if (result != null) {
      // No need to manually update the list as snapshots() will handle it
    }
  }

  void _editTest(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTestScreen(
            existingTest: _tests[index], classId: widget.classId),
      ),
    );

    if (result != null) {
      // No need to manually update the list as snapshots() will handle it
    }
  }

  void _deleteTest(int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('tests')
          .doc(_tests[index]['id'])
          .delete();
    } catch (e) {
      _showErrorSnackBar('Error deleting test: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manage Tests',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildGradientButton(
                text: 'GenerateMCQScreen',
                startColor: Colors.purple.shade900.withOpacity(0.5),
                endColor: Colors.indigo.shade900.withOpacity(0.5),
                onPressed: () => {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GenerateMCQScreen()))
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.purple.shade200,
                      ),
                    )
                  : _tests.isEmpty
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
          _tests[index]['name'] ?? 'Unnamed Test',
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
              icon: Icon(Icons.delete, color: Colors.red.shade200),
              onPressed: () => _deleteTest(index),
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
