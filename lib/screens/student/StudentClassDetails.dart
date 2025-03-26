import 'package:classcare/screens/student/studentQuiz.dart';
import 'package:classcare/screens/teacher/quiz_generate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:classcare/screens/teacher/chat_tab.dart';

// Refined color palette with subtle tones - copied from the first file
class AppColors {
  // Base colors
  static const Color background = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF252525);

  // Subtle accent colors
  static const Color accentBlue = Color(0xFF81A1C1);
  static const Color accentGreen = Color.fromARGB(255, 125, 225, 130);
  static const Color accentPurple = Color(0xFFB48EAD);
  static const Color accentYellow = Color(0xFFEBCB8B);
  static const Color accentRed = Color(0xFFBF616A);

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0xFFAAAAAA);
  static const Color tertiaryText = Color(0xFF757575);
}

class StudentClassDetails extends StatefulWidget {
  final String classId;
  final String className;

  const StudentClassDetails({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _StudentClassDetailsState createState() => _StudentClassDetailsState();
}

class _StudentClassDetailsState extends State<StudentClassDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0; // Track the current tab index explicitly

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);

    // Add listener to update state when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index; // Update the current index
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> getClassDetails() async {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
  }

  


  // Function to handle tab selection
  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _tabController.animateTo(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleSpacing: w * 0.01,
        ),
        cardColor: AppColors.cardColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.className,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: h * 0.02,
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: AppColors.surfaceColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      color: AppColors.accentBlue,
                      size: h * 0.04,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Class Options",
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: h * 0.02,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          
              ListTile(
                leading: Icon(Icons.assessment, color: AppColors.accentBlue),
                title: Text("Quiz",
                    style: TextStyle(color: AppColors.primaryText)),
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=>Studentquiz(classId: widget.classId,))),
              ),
              
            ],
          ),
        ),
        body: Column(
          children: [
            // Class header section
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(h * 0.018),
              decoration: BoxDecoration( 
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentBlue.withOpacity(0.2),
                    AppColors.accentPurple.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      color: AppColors.accentBlue,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Student Dashboard",
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                ],
              ),
            ),

            // Give Attendance Button - Styled to match the first file's design
            
            // Custom boxed tab bar with fixed segments - matches the first file design
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Assignments Tab
                  
                  // Chat Tab
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTab(0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _currentIndex == 0
                              ? AppColors.cardColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: _currentIndex == 0
                              ? Border.all(
                                  color: AppColors.accentBlue.withOpacity(0.5),
                                  width: 1)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: _currentIndex == 0
                                  ? AppColors.accentBlue
                                  : AppColors.secondaryText,
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Chat",
                              style: TextStyle(
                                color: _currentIndex == 0
                                    ? AppColors.accentBlue
                                    : AppColors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab content - styled to match the first file
            Expanded(
              
              child: Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    ChatTab(classId: widget.classId),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}