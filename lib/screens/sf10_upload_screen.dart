// lib/screens/sf10_upload_screen.dart
import 'package:flutter/material.dart';
import '../models/sf10.dart';
import 'package:intl/intl.dart';

class SF10UploadScreen extends StatefulWidget {
  final Future<void> Function(SF10 newRecord) onSave;

  const SF10UploadScreen({Key? key, required this.onSave}) : super(key: key);

  @override
  _SF10UploadScreenState createState() => _SF10UploadScreenState();
}

class _SF10UploadScreenState extends State<SF10UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();

  @override
  void dispose() {
    _studentNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final newRecord = SF10(
      studentName: _studentNameController.text.trim(),
      dateIssued: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      id: '', // Consider generating a unique ID here
    );

    try {
      await widget.onSave(newRecord);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving record: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload SF10')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
                autofocus: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
