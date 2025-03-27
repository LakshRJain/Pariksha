import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classcare/screens/student/assignment_details_page.dart';

class AssignmentCard extends StatelessWidget {
  final QueryDocumentSnapshot assignment;
  String classId;
  AssignmentCard({super.key, required this.assignment , required this.classId});

  @override
  Widget build(BuildContext context) {
    var data = assignment.data() as Map<String, dynamic>;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(data['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text('Due Date: ${data['dueDate']}'),
        onTap: () {
          // Navigate to the assignment detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AssignmentDetailPage(assignment: assignment ,classId: classId, ),
            ),
          );
        },
      ),
    );
  }
}
