// lib/screens/sf10_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/sf10.dart';

class SF10ListScreen extends StatefulWidget {
  final String? sf10sJson;
  final Future<String?> Function()? onAddNewRecord;

  const SF10ListScreen({Key? key, required this.sf10sJson, this.onAddNewRecord})
    : super(key: key);

  @override
  _SF10ListScreenState createState() => _SF10ListScreenState();
}

class _SF10ListScreenState extends State<SF10ListScreen> {
  List<SF10> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    final raw = widget.sf10sJson ?? '[]';
    _records = (json.decode(raw) as List).map((e) => SF10.fromJson(e)).toList();
  }

  Future<void> _refresh() async {
    if (widget.onAddNewRecord != null) {
      final updatedJson = await widget.onAddNewRecord!();
      if (updatedJson != null) {
        setState(() {
          _records = (json.decode(updatedJson) as List)
              .map((e) => SF10.fromJson(e))
              .toList();
        });
      }
    } else {
      setState(_loadRecords);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SF10 Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleAddNewRecord,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_records.isEmpty) {
      return const Center(child: Text('No SF10 records yet.'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: _records.length,
        itemBuilder: (_, index) => _buildRecordTile(_records[index]),
      ),
    );
  }

  Widget _buildRecordTile(SF10 record) {
    return ListTile(
      leading: const Icon(Icons.description),
      title: Text(record.studentName),
      subtitle: Text('Issued: ${record.dateIssued}'),
      onTap: () => _viewRecordDetails(record),
    );
  }

  void _handleAddNewRecord() async {
    if (widget.onAddNewRecord != null) {
      await widget.onAddNewRecord!();
      await _refresh();
    } else {
      // Fallback if no handler provided
      Navigator.pushNamed(context, '/sf10/upload').then((_) => _refresh());
    }
  }

  void _viewRecordDetails(SF10 record) {
    // Implement record details viewing
    Navigator.pushNamed(context, '/sf10/details', arguments: record.toJson());
  }
}
