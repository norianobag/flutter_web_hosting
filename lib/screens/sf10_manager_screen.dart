import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SF10ViewerScreen extends StatefulWidget {
  const SF10ViewerScreen({Key? key}) : super(key: key);

  @override
  State<SF10ViewerScreen> createState() => _SF10ViewerScreenState();
}

class _SF10ViewerScreenState extends State<SF10ViewerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _sf10Collection;

  final List<TextEditingController> _controllers = List.generate(
    7,
    (_) => TextEditingController(),
  );
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sf10Collection = _firestore.collection('public_sf10_items');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Custodian Slip'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
            tooltip: 'Add new item',
          ),
        ],
      ),
      body: _buildInventoryList(),
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _sf10Collection
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: ErrorWidget(
              'Error loading data:\n${snapshot.error}',
              onRetry: () => setState(() {}),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget();
        }

        final documents = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final record = SF10Item.fromMap(doc.id, data);

            return _InventoryCard(
              item: record,
              onTap: () => _showItemDetails(record),
              onEdit: () => _showEditDialog(record),
              onDelete: () => _confirmDelete(record.id),
              onPrint: () => _showPrintPreview(record),
            );
          },
        );
      },
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

  void _showItemDetails(SF10Item item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(child: _ItemDetailsView(item: item)),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditDialog(item);
                  },
                  child: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPrintPreview(item);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog([SF10Item? item]) {
    if (item != null) {
      _controllers[0].text = item.recipient;
      _controllers[1].text = item.unit;
      _controllers[2].text = item.nameDescription;
      _controllers[3].text = item.unitCost.toString();
      _controllers[4].text = item.dateAcquired;
      _controllers[5].text = item.inventoryItemNo;
      _controllers[6].text = item.estimatedLife;
    } else {
      for (var controller in _controllers) {
        controller.clear();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item == null ? 'Add New Item' : 'Edit Item',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  label: 'Recipient',
                  controller: _controllers[0],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildFormField(
                  label: 'Unit',
                  controller: _controllers[1],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildFormField(
                  label: 'Name/Description',
                  controller: _controllers[2],
                  maxLines: 2,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildFormField(
                  label: 'Unit Cost',
                  controller: _controllers[3],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(value!) == null)
                      return 'Invalid number';
                    return null;
                  },
                ),
                _buildDateField(
                  label: 'Date Acquired',
                  controller: _controllers[4],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildFormField(
                  label: 'Inventory Item No',
                  controller: _controllers[5],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                _buildFormField(
                  label: 'Estimated Life',
                  controller: _controllers[6],
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => _saveItem(item?.id),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save'),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                controller.text = DateFormat('yyyy-MM-dd').format(date);
              }
            },
          ),
        ),
        readOnly: true,
        validator: validator,
      ),
    );
  }

  Future<void> _saveItem(String? id) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final unitCost = double.tryParse(_controllers[3].text) ?? 0.0;

      final data = {
        'recipient': _controllers[0].text,
        'unit': _controllers[1].text,
        'nameDescription': _controllers[2].text,
        'unitCost': unitCost,
        'dateAcquired': _controllers[4].text,
        'inventoryItemNo': _controllers[5].text,
        'estimatedLife': _controllers[6].text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (id == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _sf10Collection.add(data);
      } else {
        await _sf10Collection.doc(id).update(data);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Are you sure you want to delete this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);

              try {
                await _sf10Collection.doc(id).delete();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting item: ${e.toString()}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } finally {
                setState(() => _isLoading = false);
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class _InventoryCard extends StatelessWidget {
  final SF10Item item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const _InventoryCard({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.nameDescription,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.print_outlined, size: 20),
                        onPressed: onPrint,
                        tooltip: 'Print',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        tooltip: 'Delete',
                        color: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Recipient: ${item.recipient}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Unit Cost: \$${item.unitCost.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemDetailsView extends StatelessWidget {
  final SF10Item item;

  const _ItemDetailsView({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(label: 'Recipient:', value: item.recipient),
        _DetailRow(label: 'Unit:', value: item.unit),
        _DetailRow(label: 'Description:', value: item.nameDescription),
        _DetailRow(
          label: 'Unit Cost:',
          value: '\$${item.unitCost.toStringAsFixed(2)}',
        ),
        _DetailRow(label: 'Date Acquired:', value: item.dateAcquired),
        _DetailRow(label: 'Inventory No:', value: item.inventoryItemNo),
        _DetailRow(label: 'Estimated Life:', value: item.estimatedLife),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorWidget(this.message, {required this.onRetry, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No inventory items found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
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

  factory SF10Item.fromMap(String id, Map<String, dynamic> data) {
    return SF10Item(
      id: id,
      recipient: data['recipient'] ?? '',
      unit: data['unit'] ?? '',
      nameDescription: data['nameDescription'] ?? '',
      unitCost: data['unitCost']?.toDouble() ?? 0.0,
      dateAcquired: data['dateAcquired'] ?? '',
      inventoryItemNo: data['inventoryItemNo'] ?? '',
      estimatedLife: data['estimatedLife'] ?? '',
    );
  }
}
