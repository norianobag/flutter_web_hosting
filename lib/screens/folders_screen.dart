import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FoldersScreen extends StatefulWidget {
  final String? userId;

  const FoldersScreen({super.key, this.userId});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late CollectionReference _foldersRef;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAddingFolder = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _folderNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final targetUserId = widget.userId ?? _auth.currentUser?.uid;
    if (targetUserId != null) {
      _foldersRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('folders');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _addFolder() async {
    if (_folderNameController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _foldersRef.add({
        'name': _folderNameController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
        'userEmail': _auth.currentUser!.email,
      });

      _folderNameController.clear();
      setState(() {
        _isAddingFolder = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Folder created successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to create folder: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this folder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // Delete folder and all its files
        final batch = _firestore.batch();
        final filesRef = _foldersRef.doc(folderId).collection('files');

        // Delete all files in the folder first
        final filesSnapshot = await filesRef.get();
        for (var doc in filesSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Then delete the folder itself
        batch.delete(_foldersRef.doc(folderId));

        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAddFolderForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _folderNameController,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isAddingFolder = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addFolder,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Folder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(DocumentSnapshot folder) {
    final data = folder.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.folder, size: 40, color: Colors.amber),
        title: Text(data['name'] ?? 'Unnamed Folder'),
        subtitle: Text(
          'Created ${DateFormat('MMM d, y').format((data['createdAt'] as Timestamp).toDate())}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFolder(folder.id),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderDetailScreen(
              folderId: folder.id,
              folderName: data['name'],
              userId: data['userId'],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No folders yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _isAddingFolder = true),
            child: const Text('Create First Folder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folders'),
        actions: [
          if (!_isAddingFolder)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _isAddingFolder = true),
            ),
        ],
      ),
      body: _isLoading && !_isAddingFolder
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isAddingFolder) _buildAddFolderForm(),
                if (!_isAddingFolder)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                if (!_isAddingFolder)
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _foldersRef.orderBy('createdAt').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final folders = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              data['name']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (folders.isEmpty) {
                          return const Center(
                            child: Text('No matching folders'),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            // Force refresh
                            setState(() {});
                          },
                          child: ListView.builder(
                            itemCount: folders.length,
                            itemBuilder: (context, index) =>
                                _buildFolderCard(folders[index]),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class FolderDetailScreen extends StatefulWidget {
  final String folderId;
  final String? folderName;
  final String userId;

  const FolderDetailScreen({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.userId,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  late CollectionReference _filesRef;
  final _fileNameController = TextEditingController();
  final _fileTypeController = TextEditingController();
  final _fileSizeController = TextEditingController();
  bool _isAddingFile = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('folders')
        .doc(widget.folderId)
        .collection('files');
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _fileTypeController.dispose();
    _fileSizeController.dispose();
    super.dispose();
  }

  Future<void> _addFile() async {
    if (_fileNameController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _filesRef.add({
        'name': _fileNameController.text,
        'type': _fileTypeController.text,
        'size': _fileSizeController.text,
        'uploadedAt': FieldValue.serverTimestamp(),
        'userId': widget.userId,
      });

      _fileNameController.clear();
      _fileTypeController.clear();
      _fileSizeController.clear();
      setState(() {
        _isAddingFile = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File added successfully')));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to add file: ${e.toString()}';
      });
    }
  }

  Future<void> _deleteFile(String fileId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _filesRef.doc(fileId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildAddFileForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileTypeController,
              decoration: const InputDecoration(
                labelText: 'File Type (e.g., PDF, Image)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileSizeController,
              decoration: const InputDecoration(
                labelText: 'File Size (e.g., 2.5 MB)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isAddingFile = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addFile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add File'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(DocumentSnapshot file) {
    final data = file.data() as Map<String, dynamic>;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(_getFileIcon(data['type']?.toString() ?? ''), size: 40),
        title: Text(data['name'] ?? 'Unnamed File'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${data['type'] ?? 'Unknown'}'),
            Text('Size: ${data['size'] ?? 'Unknown'}'),
            if (data['uploadedAt'] != null)
              Text(
                'Uploaded: ${DateFormat('MMM d, y').format((data['uploadedAt'] as Timestamp).toDate())}',
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFile(file.id),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No files in "${widget.folderName}"',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _isAddingFile = true),
            child: const Text('Add First File'),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    if (type.contains('image')) return Icons.image;
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('video')) return Icons.video_file;
    if (type.contains('audio')) return Icons.audio_file;
    if (type.contains('word')) return Icons.description;
    if (type.contains('excel')) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName ?? 'Folder'),
        actions: [
          if (!_isAddingFile)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _isAddingFile = true),
            ),
        ],
      ),
      body: _isLoading && !_isAddingFile
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isAddingFile) _buildAddFileForm(),
                if (!_isAddingFile)
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _filesRef.orderBy('uploadedAt').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            // Force refresh
                            setState(() {});
                          },
                          child: ListView.builder(
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) =>
                                _buildFileCard(snapshot.data!.docs[index]),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
