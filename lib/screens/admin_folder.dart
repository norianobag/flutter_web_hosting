import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: UsersFoldersScreen()));
}

class UsersFoldersScreen extends StatefulWidget {
  const UsersFoldersScreen({super.key});

  @override
  State<UsersFoldersScreen> createState() => _UsersFoldersScreenState();
}

class _UsersFoldersScreenState extends State<UsersFoldersScreen> {
  late CollectionReference usersRef;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      usersRef = FirebaseFirestore.instance.collection('users');
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.blue[200]! : Colors.blue[800]!,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Users Folders'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: ErrorRetryCard(
          message: _errorMessage!,
          onRetry: _initializeFirestore,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Folders'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.blue[800],
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          Expanded(child: _buildUsersList(theme, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search users...',
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
            ),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildUsersList(ThemeData theme, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: usersRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorRetryCard(
            message: 'Error loading users: ${snapshot.error}',
            onRetry: _initializeFirestore,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.blue[200]! : Colors.blue[800]!,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyStateCard(
            icon: Icons.people_alt,
            message: 'No users found',
          );
        }

        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final email = data['email']?.toString().toLowerCase() ?? '';
          final name = data['name']?.toString().toLowerCase() ?? '';
          return email.contains(_searchQuery.toLowerCase()) ||
              name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (users.isEmpty) {
          return EmptyStateCard(
            icon: Icons.search_off,
            message: 'No matching users found',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final email = data['email'] ?? 'Unknown User';
            final name = data['name'] ?? 'No name provided';
            final createdAt = data['createdAt'] as Timestamp?;

            return UserCard(
              email: email,
              name: name,
              createdAt: createdAt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserFoldersScreen(userId: user.id),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Users Folders'),
        content: const Text(
          'Browse all users and their shared folders. '
          'Tap on a user to view their available folders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class UserFoldersScreen extends StatefulWidget {
  final String userId;

  const UserFoldersScreen({super.key, required this.userId});

  @override
  State<UserFoldersScreen> createState() => _UserFoldersScreenState();
}

class _UserFoldersScreenState extends State<UserFoldersScreen> {
  late CollectionReference foldersRef;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      foldersRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('folders');
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.blue[200]! : Colors.blue[800]!,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Folders'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: ErrorRetryCard(
          message: _errorMessage!,
          onRetry: _initializeFirestore,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Folders'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.blue[800],
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          Expanded(child: _buildFoldersList(theme, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search folders...',
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
            ),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildFoldersList(ThemeData theme, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: foldersRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorRetryCard(
            message: 'Error loading folders: ${snapshot.error}',
            onRetry: _initializeFirestore,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.blue[200]! : Colors.blue[800]!,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyStateCard(
            icon: Icons.folder,
            message: 'No folders found',
          );
        }

        final folders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (folders.isEmpty) {
          return EmptyStateCard(
            icon: Icons.search_off,
            message: 'No matching folders found',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: folders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final folder = folders[index];
            final data = folder.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed Folder';
            final createdAt = data['createdAt'] as Timestamp?;
            final isPublic = data['isPublic'] == true;

            return FolderCard(
              name: name,
              createdAt: createdAt,
              isPublic: isPublic,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FolderContentsScreen(
                      userId: widget.userId,
                      folderId: folder.id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About User Folders'),
        content: const Text(
          'Browse all folders shared by this user. '
          'Public folders are marked with a globe icon.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class FolderContentsScreen extends StatefulWidget {
  final String userId;
  final String folderId;

  const FolderContentsScreen({
    super.key,
    required this.userId,
    required this.folderId,
  });

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  late CollectionReference contentsRef;
  bool _isLoading = true;
  String? _errorMessage;
  String? _folderName;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      // First get folder name
      final folderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('folders')
          .doc(widget.folderId)
          .get();

      if (folderDoc.exists) {
        setState(() {
          _folderName = folderDoc.data()?['name'] ?? 'Unnamed Folder';
        });
      }

      // Then set up the contents reference
      contentsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('folders')
          .doc(widget.folderId)
          .collection('contents');

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contents: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.blue[200]! : Colors.blue[800]!,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_folderName ?? 'Folder Contents'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: ErrorRetryCard(
          message: _errorMessage!,
          onRetry: _initializeFirestore,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_folderName ?? 'Folder Contents'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: isDarkMode ? Colors.white : Colors.blue[800],
            ),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          Expanded(child: _buildContentsList(theme, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search contents...',
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
            ),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildContentsList(ThemeData theme, bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: contentsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorRetryCard(
            message: 'Error loading contents: ${snapshot.error}',
            onRetry: _initializeFirestore,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? Colors.blue[200]! : Colors.blue[800]!,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyStateCard(
            icon: Icons.insert_drive_file,
            message: 'No contents found in this folder',
          );
        }

        final contents = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString().toLowerCase() ?? '';
          final description =
              data['description']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase()) ||
              description.contains(_searchQuery.toLowerCase());
        }).toList();

        if (contents.isEmpty) {
          return EmptyStateCard(
            icon: Icons.search_off,
            message: 'No matching contents found',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: contents.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final content = contents[index];
            final data = content.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unnamed Item';
            final description = data['description'] ?? 'No description';
            final createdAt = data['createdAt'] as Timestamp?;
            final fileUrl = data['fileUrl'] as String?;

            return ContentItemCard(
              name: name,
              description: description,
              createdAt: createdAt,
              fileUrl: fileUrl,
            );
          },
        );
      },
    );
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Folder Contents'),
        content: const Text(
          'This screen shows all the contents of the selected folder. '
          'You can view details of each item and access files if available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class ContentItemCard extends StatelessWidget {
  final String name;
  final String description;
  final Timestamp? createdAt;
  final String? fileUrl;

  const ContentItemCard({
    super.key,
    required this.name,
    required this.description,
    this.createdAt,
    this.fileUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fileUrl != null ? Icons.insert_drive_file : Icons.note,
                color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (fileUrl != null)
                IconButton(
                  icon: Icon(
                    Icons.download,
                    color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
                  ),
                  onPressed: () {
                    // Implement download functionality
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Added ${DateFormat('MMM d, yyyy').format(createdAt!.toDate())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Reusable Card Components (same as before)
class UserCard extends StatelessWidget {
  final String email;
  final String name;
  final Timestamp? createdAt;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.email,
    required this.name,
    this.createdAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue[900] : Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: isDarkMode ? Colors.blue[200] : Colors.blue[800],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${DateFormat('MMM yyyy').format(createdAt!.toDate())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class FolderCard extends StatelessWidget {
  final String name;
  final Timestamp? createdAt;
  final bool isPublic;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.name,
    this.createdAt,
    this.isPublic = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.amber[900] : Colors.amber[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPublic ? Icons.folder_shared : Icons.folder,
                color: isDarkMode ? Colors.amber[200] : Colors.amber[800],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPublic) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.public,
                          size: 16,
                          color: isDarkMode
                              ? Colors.blue[200]
                              : Colors.blue[600],
                        ),
                      ],
                    ],
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Created ${DateFormat('MMM d, yyyy').format(createdAt!.toDate())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorRetryCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: isDarkMode ? Colors.red[200] : Colors.red[600],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.blue[800]
                        : Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyStateCard({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
