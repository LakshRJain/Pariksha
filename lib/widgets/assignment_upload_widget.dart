import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class AssignmentUploadWidget extends StatefulWidget {
  final String classId;

  const AssignmentUploadWidget({super.key, required this.classId});

  @override
  _AssignmentUploadWidgetState createState() => _AssignmentUploadWidgetState();
}

class _AssignmentUploadWidgetState extends State<AssignmentUploadWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  PlatformFile? _pickedFile;
  String? _filePath;
  PlatformFile? _rubricFile;
  String? _rubricFilePath;
  bool _isUploading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withReadStream: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _filePath = result.files.first.path;
        });
      } else {
        _showSnackBar('No file selected', Colors.amber);
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', Colors.red.shade300);
    }
  }

  Future<void> pickRubric() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(withReadStream: true);

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _rubricFile = result.files.first;
          _rubricFilePath = result.files.first.path;
        });
      } else {
        _showSnackBar('No rubric file selected', Colors.amber);
      }
    } catch (e) {
      _showSnackBar('Error picking rubric file: $e', Colors.red.shade300);
    }
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

  Future<void> uploadAssignment() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _dueDate == null ||
        _pickedFile == null ||
        _rubricFile == null ||
        _filePath == null ||
        _rubricFilePath == null) {
      _showSnackBar('Please complete all fields and upload files', Colors.amber);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String assignmentId = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc()
          .id;

      Reference rubricStorageRef = FirebaseStorage.instance.ref().child(
          'classes/${widget.classId}/assignments/$assignmentId/rubric.pdf');
      UploadTask rubricUploadTask;

      if (kIsWeb) {
        rubricUploadTask = rubricStorageRef.putData(_rubricFile!.bytes!);
      } else {
        rubricUploadTask = rubricStorageRef.putFile(File(_rubricFilePath!));
      }

      TaskSnapshot rubricSnapshot = await rubricUploadTask;
      String rubricUrl = await rubricSnapshot.ref.getDownloadURL();

      Reference assignmentStorageRef = FirebaseStorage.instance.ref().child(
          'classes/${widget.classId}/assignments/$assignmentId/teacher_assignment.pdf');
      UploadTask assignmentUploadTask;

      if (kIsWeb) {
        assignmentUploadTask =
            assignmentStorageRef.putData(_pickedFile!.bytes!);
      } else {
        assignmentUploadTask = assignmentStorageRef.putFile(File(_filePath!));
      }

      TaskSnapshot assignmentSnapshot = await assignmentUploadTask;
      String assignmentUrl = await assignmentSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc(assignmentId)
          .set({
        'assignmentId': assignmentId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'dueDate': DateFormat('yyyy-MM-dd').format(_dueDate!),
        'uploadedBy': FirebaseAuth.instance.currentUser!.uid,
        'rubricUrl': rubricUrl,
        'fileUrl': assignmentUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Assignment uploaded successfully!', Colors.greenAccent);

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _dueDate = null;
        _pickedFile = null;
        _rubricFile = null;
        _filePath = null;
        _rubricFilePath = null;
      });
    } catch (e) {
      _showSnackBar('Failed to upload assignment: $e', Colors.red.shade300);
    } finally {
      setState(() {
        _isUploading = false;
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
        title: const Text(
          'New Assignment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: FadeTransition(
          opacity: _animation,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Assignment",
                          style: TextStyle(
                            color: Colors.pink.shade100,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Fill in the details below",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _titleController,
                    labelText: 'Assignment Title',
                    icon: Icons.title,
                    color: Colors.cyan.shade200,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descriptionController,
                    labelText: 'Assignment Description',
                    icon: Icons.description,
                    color: Colors.pink.shade200,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 25),
                  _buildDateTimePicker(),
                  const SizedBox(height: 25),
                  _buildFilePicker(
                    file: _pickedFile,
                    onPick: pickFile,
                    label: "Assignment File",
                    icon: Icons.insert_drive_file,
                    color: Colors.purple.shade200,
                  ),
                  const SizedBox(height: 20),
                  _buildFilePicker(
                    file: _rubricFile,
                    onPick: pickRubric,
                    label: "Rubric File",
                    icon: Icons.grading,
                    color: Colors.green.shade200,
                  ),
                  const SizedBox(height: 30),
                  _buildUploadButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
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
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: Colors.blue.shade200),
        title: Text(
          _dueDate == null
              ? "Select Due Date & Time"
              : "Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate!)}",
          style: TextStyle(
            color: _dueDate == null ? Colors.grey.shade400 : Colors.white,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.blue.shade200,
          size: 16,
        ),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2101),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.blue.shade200,
                    onPrimary: Colors.black,
                    surface: Colors.grey.shade900,
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: Colors.grey.shade900,
                ),
                child: child!,
              );
            },
          );

          if (pickedDate != null) {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.dark(
                      primary: Colors.blue.shade200,
                      onPrimary: Colors.black,
                      surface: Colors.grey.shade900,
                      onSurface: Colors.white,
                    ),
                    dialogBackgroundColor: Colors.grey.shade900,
                  ),
                  child: child!,
                );
              },
            );

            if (pickedTime != null) {
              setState(() {
                _dueDate = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }
          }
        },
      ),
    );
  }

  Widget _buildFilePicker({
    required PlatformFile? file,
    required Function onPick,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade900,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (file != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black.withOpacity(0.3),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              "No file selected",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 10),
          _buildGradientButton(
            onTap: () => onPick(),
            text: "Select File",
            startColor: color.withOpacity(0.5),
            endColor: color.withOpacity(0.2),
            textColor: Colors.white,
            icon: Icons.upload_file,
            minWidth: 130,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required Function onTap,
    required String text,
    required Color startColor,
    required Color endColor,
    required Color textColor,
    required IconData icon,
    double? minWidth,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth ?? double.infinity),
      height: 45,
      child: ElevatedButton(
        onPressed: () => onTap(),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return _isUploading
        ? Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade200),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 15),
                Text(
                  "Uploading assignment...",
                  style: TextStyle(
                    color: Colors.purple.shade200,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
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
              onPressed: uploadAssignment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purpleAccent.shade100.withOpacity(0.8),
                      Colors.blueAccent.shade100.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        "Submit Assignment",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}