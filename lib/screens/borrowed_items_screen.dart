import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SimpleBorrowedItemsScreen extends StatefulWidget {
  const SimpleBorrowedItemsScreen({Key? key}) : super(key: key);

  @override
  State<SimpleBorrowedItemsScreen> createState() =>
      _SimpleBorrowedItemsScreenState();
}

class _SimpleBorrowedItemsScreenState extends State<SimpleBorrowedItemsScreen> {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'borrowed_items',
  );
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _borrowerController = TextEditingController();
  final _dateBorrowedController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isReturned = false;
  String? _editingItemId;

  @override
  void dispose() {
    _itemController.dispose();
    _borrowerController.dispose();
    _dateBorrowedController.dispose();
    _returnDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowed Items'),
        actions: [
          if (FirebaseAuth.instance.currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showEditDialog(),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.03),
              theme.colorScheme.primary.withOpacity(0.01),
            ],
          ),
        ),
        child: _buildContent(),
      ),
      floatingActionButton: FirebaseAuth.instance.currentUser != null
          ? FloatingActionButton(
              onPressed: () => _showEditDialog(),
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _items.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No borrowed items',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (FirebaseAuth.instance.currentUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Item'),
                      onPressed: _showEditDialog,
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isOverdue =
                data['isReturned'] == false &&
                data['returnDate'] != null &&
                DateTime.parse(data['returnDate']).isBefore(DateTime.now());
            final user = FirebaseAuth.instance.currentUser;
            final isOwner = user != null && data['userId'] == user.uid;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showItemDetails(
                  item: data['item'],
                  borrower: data['borrower'],
                  dateBorrowed: data['dateBorrowed'],
                  returnDate: data['returnDate'],
                  notes: data['notes'],
                  isReturned: data['isReturned'] ?? false,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['item'] ?? 'Unnamed Item',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (data['isReturned'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Returned',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.print, size: 20),
                            onPressed: () => _showPrintPreview(
                              item: data['item'] ?? '',
                              borrower: data['borrower'] ?? '',
                              dateBorrowed: data['dateBorrowed'] ?? '',
                              returnDate: data['returnDate'] ?? '',
                              notes: data['notes'] ?? '',
                              isReturned: data['isReturned'] ?? false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['borrower'] ?? 'Unknown borrower',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['dateBorrowed'] ?? 'No date',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: 16,
                            color: isOverdue
                                ? Colors.red
                                : Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['returnDate'] ?? 'No return date',
                            style: TextStyle(
                              color: isOverdue ? Colors.red : null,
                              fontWeight: isOverdue ? FontWeight.bold : null,
                            ),
                          ),
                          if (isOverdue)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '(Overdue)',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (isOwner) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _showEditDialog(
                                id: doc.id,
                                item: data['item'],
                                borrower: data['borrower'],
                                dateBorrowed: data['dateBorrowed'],
                                returnDate: data['returnDate'],
                                notes: data['notes'],
                                isReturned: data['isReturned'] ?? false,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _deleteItem(doc.id),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrintPreview({
    required String item,
    required String borrower,
    required String dateBorrowed,
    required String returnDate,
    required String notes,
    required bool isReturned,
  }) {
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
                  'BORROWED ITEM RECORD',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPrintRow('Item:', item),
              _buildPrintRow('Borrower:', borrower),
              _buildPrintRow('Date Borrowed:', dateBorrowed),
              _buildPrintRow('Return Date:', returnDate),
              _buildPrintRow(
                'Status:',
                isReturned ? 'Returned' : 'Not Returned',
              ),
              if (notes.isNotEmpty) _buildPrintRow('Notes:', notes),
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
            width: 120,
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

  void _showItemDetails({
    required String? item,
    required String? borrower,
    required String? dateBorrowed,
    required String? returnDate,
    required String? notes,
    required bool isReturned,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              item ?? 'Item Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.person_outline, 'Borrower:', borrower),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Borrowed:',
              dateBorrowed,
            ),
            _buildDetailRow(
              Icons.event_available_outlined,
              'Return by:',
              returnDate,
            ),
            _buildDetailRow(
              isReturned ? Icons.check_circle : Icons.hourglass_bottom,
              'Status:',
              isReturned ? 'Returned' : 'Borrowed',
            ),
            if (notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              Text('Notes:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(notes!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).disabledColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not specified',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog({
    String? id,
    String? item,
    String? borrower,
    String? dateBorrowed,
    String? returnDate,
    String? notes,
    bool isReturned = false,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to edit items')),
      );
      return;
    }

    _editingItemId = id;
    _itemController.text = item ?? '';
    _borrowerController.text = borrower ?? '';
    _dateBorrowedController.text = dateBorrowed ?? '';
    _returnDateController.text = returnDate ?? '';
    _notesController.text = notes ?? '';
    _isReturned = isReturned;

    // Set default dates if adding new item
    if (id == null) {
      final now = DateTime.now();
      _dateBorrowedController.text = DateFormat('yyyy-MM-dd').format(now);
      _returnDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(now.add(const Duration(days: 7)));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  id == null ? 'Add Borrowed Item' : 'Edit Item',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _itemController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _borrowerController,
                  decoration: const InputDecoration(
                    labelText: 'Borrower Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dateBorrowedController,
                  decoration: const InputDecoration(
                    labelText: 'Date Borrowed',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(_dateBorrowedController),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _returnDateController,
                  decoration: const InputDecoration(
                    labelText: 'Return Date',
                    prefixIcon: Icon(Icons.event_available),
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(_returnDateController),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (id != null) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Item Returned'),
                    value: _isReturned,
                    onChanged: (value) {
                      setState(() {
                        _isReturned = value;
                      });
                    },
                    secondary: Icon(
                      _isReturned ? Icons.check_circle : Icons.hourglass_bottom,
                      color: _isReturned ? Colors.green : null,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                        onPressed: _saveItem,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Clear controllers when dialog is closed
      _itemController.clear();
      _borrowerController.clear();
      _dateBorrowedController.clear();
      _returnDateController.clear();
      _notesController.clear();
      _editingItemId = null;
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final initialDate = controller.text.isNotEmpty
        ? DateTime.parse(controller.text)
        : DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final data = {
          'item': _itemController.text,
          'borrower': _borrowerController.text,
          'dateBorrowed': _dateBorrowedController.text,
          'returnDate': _returnDateController.text,
          'notes': _notesController.text,
          'isReturned': _isReturned,
          'updatedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        };

        if (_editingItemId == null) {
          data['createdAt'] = FieldValue.serverTimestamp();
          await _items.add(data);
        } else {
          await _items.doc(_editingItemId).update(data);
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        await _items.doc(id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: ${e.toString()}')),
        );
      }
    }
  }
}
