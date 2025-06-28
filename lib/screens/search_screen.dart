import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchAllScreen extends StatefulWidget {
  const SearchAllScreen({super.key});

  @override
  State<SearchAllScreen> createState() => _SearchAllScreenState();
}

class _SearchAllScreenState extends State<SearchAllScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Everything'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search folders, borrowed items, inventory...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle('Public Folders'),
                _buildFolderResults(),
                _buildSectionTitle('Global Borrowed Items'),
                _buildBorrowedItemsResults(),
                _buildSectionTitle('Public Inventory (SF10 Items)'),
                _buildInventoryResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildFolderResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('folders')
          .where('isPublic', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['name']?.toString().toLowerCase().contains(
                _searchQuery,
              ) ==
              true;
        }).toList();

        return Column(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(data['name'] ?? 'Unnamed Folder'),
              subtitle: Text('By: ${data['userEmail'] ?? 'Unknown'}'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBorrowedItemsResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('borrowed_items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['item']?.toString().toLowerCase().contains(
                    _searchQuery,
                  ) ==
                  true ||
              data['borrower']?.toString().toLowerCase().contains(
                    _searchQuery,
                  ) ==
                  true;
        }).toList();

        return Column(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(data['item'] ?? 'Unnamed'),
              subtitle: Text('Borrower: ${data['borrower'] ?? 'Unknown'}'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInventoryResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('public_sf10_items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['nameDescription']?.toString().toLowerCase().contains(
                _searchQuery,
              ) ==
              true;
        }).toList();

        return Column(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.inventory),
              title: Text(data['nameDescription'] ?? 'No Name'),
              subtitle: Text('Unit: ${data['unit'] ?? 'Unknown'}'),
            );
          }).toList(),
        );
      },
    );
  }
}
