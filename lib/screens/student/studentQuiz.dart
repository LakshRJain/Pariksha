import 'package:classcare/screens/student/Quiz_student.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Studentquiz extends StatefulWidget {
  final String classId;

  const Studentquiz({super.key, required this.classId});

  @override
  _StudentquizState createState() => _StudentquizState();
}

class _StudentquizState extends State<Studentquiz> {
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
              'startDateTime':
                  _convertTimestampToDateTime(doc['startDateTime']),
              'endDateTime': _convertTimestampToDateTime(doc['endDateTime']),
              'duration': doc['duration'],
            };
          }).toList();
          _isLoading = false;
        });
      }, onError: (error) {
        _handleError(error);
      });
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic error) {
    print("Error: $error");
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }

  DateTime? _convertTimestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print("Error parsing timestamp: $e");
        return null;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Makes back arrow white
        title: Text(
          'Available Quizzes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTests,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.blue.shade900.withOpacity(0.7),
              Colors.black,
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingIndicator()
            : _tests.isEmpty
                ? _buildEmptyState()
                : _buildTestList(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: SpinKitWave(
        color: Colors.blue.shade200,
        size: 50.0,
      ),
    );
  }

  Widget _buildTestList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: _tests.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          child: _buildTestCard(index),
        );
      },
    );
  }

  Widget _buildTestCard(int index) {
    final test = _tests[index];
    final startDateTime = test['startDateTime'];
    final endDateTime = test['endDateTime'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.5),
            Colors.blue.shade800.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTestDetailsSheet(index),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test['name'] ?? 'Unnamed Test',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTestInfoRow(
                  icon: Icons.event_outlined,
                  text: startDateTime != null
                      ? DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(startDateTime)
                      : 'Start Time Unspecified',
                ),
                const SizedBox(height: 5),
                _buildTestInfoRow(
                  icon: Icons.calendar_today,
                  text: endDateTime != null
                      ? DateFormat('MMM dd, yyyy - hh:mm a').format(endDateTime)
                      : 'End Time Unspecified',
                ),
                const SizedBox(height: 5),
                _buildTestInfoRow(
                  icon: Icons.timer,
                  text: '${test['duration'] ?? 'Unknown'} minutes',
                ),
                const SizedBox(height: 5),
                _buildTestInfoRow(
                  icon: Icons.question_mark,
                  text: '${test['questions'].length} Questions',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestInfoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade200, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade300,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showTestDetailsSheet(int index) {
    final test = _tests[index];
    final startDateTime = test['startDateTime'];
    final endDateTime = test['endDateTime'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.black,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test['name'] ?? 'Unnamed Test',
                style: TextStyle(
                  color: Colors.blue.shade200,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                icon: Icons.event_outlined,
                label: 'Start Time',
                value: startDateTime != null
                    ? DateFormat('MMMM dd, yyyy - hh:mm a')
                        .format(startDateTime)
                    : 'Not Specified',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'End Time',
                value: endDateTime != null
                    ? DateFormat('MMMM dd, yyyy - hh:mm a').format(endDateTime)
                    : 'Not Specified',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.timer,
                label: 'Duration',
                value: '${test['duration'] ?? 'Unknown'} minutes',
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.question_mark,
                label: 'Total Questions',
                value: '${test['questions'].length}',
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close the bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentTestScreen(
                          testId: test['id'],
                          classId: widget.classId,
                          testDetails: {},
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Start Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade200, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            color: Colors.blue.shade200,
            size: 100,
          ),
          const SizedBox(height: 20),
          Text(
            'No Quizzes Available',
            style: TextStyle(
              color: Colors.blue.shade100,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Check back later or contact your instructor',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
