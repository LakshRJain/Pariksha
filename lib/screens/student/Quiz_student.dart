import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentTestScreen extends StatefulWidget {
  final String testId;
  final String classId;
  final Map<String, dynamic> testDetails;

  const StudentTestScreen({
    super.key,
    required this.testId,
    required this.classId,
    required this.testDetails,
  });

  @override
  _StudentTestScreenState createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends State<StudentTestScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  List<int?> _selectedAnswers = [];
  Timer? _testTimer;
  int _remainingSeconds = 0;
  bool _isTestSubmitted = false;
  int _correctAnswers = 0;
  bool _isLoading = true;
  bool _hasAlreadyAttempted = false;
  String? _studentId;
  Map<String, dynamic>? _previousAttemptData;

  // App switch tracking
  int _switchCount = 0;
  final bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _studentId = FirebaseAuth.instance.currentUser?.uid;
    _resetSwitchCounter();
    _checkTestAttempt();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _testTimer?.cancel();
    super.dispose();
  }

  Future<void> _resetSwitchCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('switch_count', 0);
    setState(() {
      _switchCount = 0;
    });
  }

  Future<void> _incrementSwitchCount() async {
    if (!_isActive) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _switchCount++;
    });
    await prefs.setInt('switch_count', _switchCount);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isActive) {
      _incrementSwitchCount();
    }
  }

  Future<void> _checkTestAttempt() async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('tests')
          .doc(widget.testId)
          .collection('results')
          .where('studentId', isEqualTo: _studentId)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        setState(() {
          _hasAlreadyAttempted = true;
          _previousAttemptData = result.docs.first.data();
          _isLoading = false;
        });
      } else {
        _fetchTestDetails();
      }
    } catch (e) {
      print('Error checking test attempt: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTestDetails() async {
    try {
      DocumentSnapshot testDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('tests')
          .doc(widget.testId)
          .get();

      if (testDoc.exists) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(testDoc['questions']);
          _selectedAnswers = List.filled(_questions.length, null);
          _remainingSeconds = testDoc['duration'] * 60;
          _isLoading = false;
        });

        _startTimer();
      }
    } catch (e) {
      print('Error fetching test details: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    _testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _submitTest();
          timer.cancel();
        }
      });
    });
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitTest() {
    _testTimer?.cancel();
    _correctAnswers = _questions.asMap().entries.where((entry) {
      int index = entry.key;
      Map<String, dynamic> question = entry.value;
      return _selectedAnswers[index] == question['correct'];
    }).length;

    setState(() {
      _isTestSubmitted = true;
    });

    _saveTestResult();
  }

  Future<void> _saveTestResult() async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('tests')
          .doc(widget.testId)
          .collection('results')
          .add({
        'studentId': _studentId,
        'score': _correctAnswers,
        'totalQuestions': _questions.length,
        'selectedAnswers': _selectedAnswers,
        'submittedAt': FieldValue.serverTimestamp(),
        'appSwitchCount': _switchCount,
      });
    } catch (e) {
      print('Error saving test result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue.shade200,
          ),
        ),
      );
    }

    if (_hasAlreadyAttempted) {
      return _buildAlreadyAttemptedScreen();
    }

    if (_isTestSubmitted) {
      return _buildResultScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Quiz',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: _remainingSeconds <= 60
                  ? Colors.red.shade400
                  : Colors.blue.shade400,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildQuestionCard(),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final currentQuestion = _questions[_currentQuestionIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      currentQuestion['question'],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                4,
                (index) => _buildOptionTile(
                  currentQuestion['options'][index],
                  index,
                  _selectedAnswers[_currentQuestionIndex] == index,
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 64,
                    height: 89,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.5),
                        ],
                        stops: [0.05, 0.9, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, int optionIndex, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade700 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? Colors.purple.shade300 : Colors.grey.shade700,
        ),
      ),
      child: ListTile(
        title: Text(
          option,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade300,
          ),
        ),
        onTap: () => _selectAnswer(optionIndex),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _previousQuestion,
          ),
          ElevatedButton(
            onPressed: _submitTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Submit Test'),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: _nextQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    double scorePercentage = (_correctAnswers / _questions.length) * 100;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Test Result',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: scorePercentage >= 60
                    ? Colors.green.shade200.withOpacity(0.3)
                    : Colors.red.shade200.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Score',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$_correctAnswers / ${_questions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${scorePercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: scorePercentage >= 60
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'App Switches: $_switchCount',
                style: TextStyle(
                  color: _switchCount > 3 ? Colors.red : Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Back to Tests'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyAttemptedScreen() {
    if (_previousAttemptData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blue.shade200,
          ),
        ),
      );
    }

    final score = _previousAttemptData!['score'] ?? 0;
    final totalQuestions = _previousAttemptData!['totalQuestions'] ?? 1;
    final percentage = (score / totalQuestions) * 100;
    final appSwitchCount = _previousAttemptData!['appSwitchCount'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Test Results',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: percentage >= 60
                    ? Colors.green.shade200.withOpacity(0.3)
                    : Colors.red.shade200.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_turned_in,
                color: Colors.blue,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'You have already attempted this test.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Your Score:',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$score / $totalQuestions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: percentage >= 60
                      ? Colors.green.shade300
                      : Colors.red.shade300,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'App Switches: $appSwitchCount',
                style: TextStyle(
                  color: appSwitchCount > 3 ? Colors.red : Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Back to Tests'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
