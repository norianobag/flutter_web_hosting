import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  String _filter = 'All';
  int _currentTabIndex = 0;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
          onTap: () => setState(() => _isSearching = true),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              selected: _filter == 'All',
              onSelected: () => setState(() => _filter = 'All'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Borrowed',
              selected: _filter == 'Borrowed',
              onSelected: () => setState(() => _filter = 'Borrowed'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Returned',
              selected: _filter == 'Returned',
              onSelected: () => setState(() => _filter = 'Returned'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _isSearching = false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching
                ? const SizedBox.shrink()
                : const Text('History'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                FocusScope.of(context).requestFocus(FocusNode());
                setState(() => _isSearching = !_isSearching);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isSearching) _buildSearchField(),
            if (_currentTabIndex == 0 && !_isSearching) _buildFilterChips(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Force refresh both streams
                  setState(() {});
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: IndexedStack(
                  index: _currentTabIndex,
                  children: [_buildBorrowedItems(), _buildInventoryItems()],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            FocusScope.of(context).unfocus();
            setState(() {
              _currentTabIndex = index;
              _isSearching = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildBorrowedItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowed_items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorWidget(onRetry: () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget();
        }

        final items =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final item = (data['item'] ?? '').toString().toLowerCase();
              final isReturned = data['isReturned'] == true;

              return item.contains(_searchQuery.toLowerCase()) &&
                  (_filter == 'All' ||
                      (_filter == 'Borrowed' && !isReturned) ||
                      (_filter == 'Returned' && isReturned));
            }).toList() ??
            [];

        if (items.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.history,
            message: _searchQuery.isEmpty
                ? 'No ${_filter.toLowerCase()} items'
                : 'No results for "$_searchQuery"',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            final isReturned = data['isReturned'] == true;
            final borrowedDate = data['createdAt'] as Timestamp?;
            final returnedDate = data['returnedDate'] as Timestamp?;

            return _BorrowedItemCard(
              itemName: data['item']?.toString() ?? 'Unknown Item',
              borrower: data['borrower']?.toString() ?? 'Unknown',
              borrowedDate: borrowedDate?.toDate(),
              returnedDate: returnedDate?.toDate(),
              isReturned: isReturned,
              onTap: () => _showItemDetails(context, data),
            );
          },
        );
      },
    );
  }

  Widget _buildInventoryItems() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('public_sf10_items')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorWidget(onRetry: () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingWidget();
        }

        final items =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['nameDescription'] ?? '')
                  .toString()
                  .toLowerCase();
              return name.contains(_searchQuery.toLowerCase());
            }).toList() ??
            [];

        if (items.isEmpty) {
          return _EmptyStateWidget(
            icon: Icons.inventory,
            message: _searchQuery.isEmpty
                ? 'No inventory items'
                : 'No results for "$_searchQuery"',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            return _InventoryItemCard(
              itemName: data['nameDescription']?.toString() ?? 'No Name',
              recipient: data['recipient']?.toString() ?? 'Unknown',
              dateAcquired: data['dateAcquired']?.toString() ?? 'N/A',
              unit: data['unit']?.toString() ?? '',
              onTap: () => _showItemDetails(context, data),
            );
          },
        );
      },
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Item Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...data.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(entry.value?.toString() ?? 'N/A')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Widgets for better organization and reusability

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Borrowed'),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Inventory',
        ),
      ],
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).primaryColor : null,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? Theme.of(context).primaryColor : Colors.grey[300]!,
        ),
      ),
    );
  }
}

class _BorrowedItemCard extends StatelessWidget {
  final String itemName;
  final String borrower;
  final DateTime? borrowedDate;
  final DateTime? returnedDate;
  final bool isReturned;
  final VoidCallback onTap;

  const _BorrowedItemCard({
    required this.itemName,
    required this.borrower,
    this.borrowedDate,
    this.returnedDate,
    required this.isReturned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      itemName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(isReturned ? 'Returned' : 'Borrowed'),
                    backgroundColor: isReturned
                        ? Colors.green[100]
                        : Colors.orange[100],
                    labelStyle: TextStyle(
                      color: isReturned
                          ? Colors.green[800]
                          : Colors.orange[800],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Borrower: $borrower',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (borrowedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Borrowed: ${DateFormat('MMM dd, yyyy').format(borrowedDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (isReturned && returnedDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Returned: ${DateFormat('MMM dd, yyyy').format(returnedDate!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final String itemName;
  final String recipient;
  final String dateAcquired;
  final String unit;
  final VoidCallback onTap;

  const _InventoryItemCard({
    required this.itemName,
    required this.recipient,
    required this.dateAcquired,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Text(itemName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Recipient: $recipient',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Date Acquired: $dateAcquired',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Unit: $unit',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading items...'),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('Failed to load data'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateWidget({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
