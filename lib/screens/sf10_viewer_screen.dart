import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SF10ViewerScreen extends StatefulWidget {
  const SF10ViewerScreen({Key? key}) : super(key: key);

  @override
  State<SF10ViewerScreen> createState() => _SF10ViewerScreenState();
}

class _SF10ViewerScreenState extends State<SF10ViewerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _sf10Collection;

  final _recipientController = TextEditingController();
  final _unitController = TextEditingController();
  final _nameDescriptionController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _dateAcquiredController = TextEditingController();
  final _inventoryItemNoController = TextEditingController();
  final _estimatedLifeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sf10Collection = _firestore.collection('public_sf10_items');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Custodian Slip'),
        actions: [
          if (user != null)
            IconButton(icon: const Icon(Icons.add), onPressed: () => _edit()),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (user == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Viewing public data. Log in to edit items.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _sf10Collection
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No items found'));
                  }

                  final documents = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final record = SF10Item(
                        id: doc.id,
                        recipient: data['recipient'] ?? '',
                        unit: data['unit'] ?? '',
                        nameDescription: data['nameDescription'] ?? '',
                        unitCost: data['unitCost']?.toDouble() ?? 0.0,
                        dateAcquired: data['dateAcquired'] ?? '',
                        inventoryItemNo: data['inventoryItemNo'] ?? '',
                        estimatedLife: data['estimatedLife'] ?? '',
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      record.nameDescription,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print),
                                    onPressed: () => _showPrintPreview(record),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Recipient: ${record.recipient}'),
                              Text(
                                'Unit Cost: \$${record.unitCost.toStringAsFixed(2)}',
                              ),
                              if (user != null)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _edit(record),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () =>
                                          _confirmDelete(record.id),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrintPreview(SF10Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'INVENTORY CUSTODIAN SLIP',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPrintRow('Recipient:', item.recipient),
              _buildPrintRow('Unit:', item.unit),
              _buildPrintRow('Name/Description:', item.nameDescription),
              _buildPrintRow(
                'Unit Cost:',
                '\$${item.unitCost.toStringAsFixed(2)}',
              ),
              _buildPrintRow('Date Acquired:', item.dateAcquired),
              _buildPrintRow('Inventory Item No:', item.inventoryItemNo),
              _buildPrintRow('Estimated Life:', item.estimatedLife),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printing...')),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _edit([SF10Item? item]) {
    if (item != null) {
      _recipientController.text = item.recipient;
      _unitController.text = item.unit;
      _nameDescriptionController.text = item.nameDescription;
      _unitCostController.text = item.unitCost.toString();
      _dateAcquiredController.text = item.dateAcquired;
      _inventoryItemNoController.text = item.inventoryItemNo;
      _estimatedLifeController.text = item.estimatedLife;
    } else {
      _recipientController.clear();
      _unitController.clear();
      _nameDescriptionController.clear();
      _unitCostController.clear();
      _dateAcquiredController.clear();
      _inventoryItemNoController.clear();
      _estimatedLifeController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item == null ? 'Add New Item' : 'Edit Item',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Name/Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _unitCostController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Cost',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateAcquiredController,
                  decoration: const InputDecoration(
                    labelText: 'Date Acquired',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      _dateAcquiredController.text = DateFormat(
                        'yyyy-MM-dd',
                      ).format(date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _inventoryItemNoController,
                  decoration: const InputDecoration(
                    labelText: 'Inventory Item No',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _estimatedLifeController,
                  decoration: const InputDecoration(
                    labelText: 'Estimated Life',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final unitCost =
                                double.tryParse(_unitCostController.text) ??
                                0.0;

                            final data = {
                              'recipient': _recipientController.text,
                              'unit': _unitController.text,
                              'nameDescription':
                                  _nameDescriptionController.text,
                              'unitCost': unitCost,
                              'dateAcquired': _dateAcquiredController.text,
                              'inventoryItemNo':
                                  _inventoryItemNoController.text,
                              'estimatedLife': _estimatedLifeController.text,
                              'updatedAt': FieldValue.serverTimestamp(),
                              'createdBy': _auth.currentUser?.uid,
                            };

                            if (item == null) {
                              data['createdAt'] = FieldValue.serverTimestamp();
                              await _sf10Collection.add(data);
                            } else {
                              await _sf10Collection.doc(item.id).update(data);
                            }

                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving data: $e')),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _sf10Collection.doc(id).delete();
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting item: $e')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _unitController.dispose();
    _nameDescriptionController.dispose();
    _unitCostController.dispose();
    _dateAcquiredController.dispose();
    _inventoryItemNoController.dispose();
    _estimatedLifeController.dispose();
    super.dispose();
  }
}

class SF10Item {
  final String id;
  final String recipient;
  final String unit;
  final String nameDescription;
  final double unitCost;
  final String dateAcquired;
  final String inventoryItemNo;
  final String estimatedLife;

  SF10Item({
    required this.id,
    required this.recipient,
    required this.unit,
    required this.nameDescription,
    required this.unitCost,
    required this.dateAcquired,
    required this.inventoryItemNo,
    required this.estimatedLife,
  });
}
