import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:study_app/services/file_service.dart';
import 'package:study_app/providers/pdf_annotation_provider.dart';
import 'package:study_app/screens/academic/pdf_study_screen.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/widgets/custom_card.dart';

class SubjectSpacePage extends StatefulWidget {
  final String subjectName;

  const SubjectSpacePage({
    super.key,
    required this.subjectName,
  });

  @override
  State<SubjectSpacePage> createState() => _SubjectSpacePageState();
}

class _SubjectSpacePageState extends State<SubjectSpacePage> {
  // Navigation State: Empty stack is Subject Root
  List<String> _navigationStack = []; 
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load entities for current path in the stack
    final entities = await FileService.getSubjectContents(
      widget.subjectName,
      subPath: _navigationStack,
    );

    // Sort: Directories first, then Files
    _entities = entities.toList()
      ..sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

    setState(() => _isLoading = false);
  }

  String get _currentRelativePath => _navigationStack.isEmpty ? 'root' : _navigationStack.join('/');

  void _pushFolder(String folderName) {
    setState(() {
      _navigationStack.add(folderName);
    });
    _loadData();
  }

  void _popFolder() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _navigationStack.removeLast();
      });
      _loadData();
    }
  }

  void _jumpToPath(int index) {
    setState(() {
      _navigationStack = _navigationStack.sublist(0, index + 1);
    });
    _loadData();
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add to /${_navigationStack.join('/')}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _menuOption(
              icon: Icons.folder,
              label: 'New Chapter',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(ctx);
                _showCreateChapterDialog();
              },
            ),
            _menuOption(
              icon: Icons.picture_as_pdf,
              label: 'Import to Folder',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(ctx);
                _importPDF();
              },
            ),
            _menuOption(
              icon: Icons.note,
              label: 'Create Note',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.pop(ctx);
                _showCreateNoteDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Future<void> _showCreateChapterDialog() async {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(hintText: 'Folder name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await FileService.createChapter(
                  widget.subjectName, 
                  ctrl.text,
                  currentPath: _navigationStack,
                );
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateNoteDialog() async {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: TextField(controller: ctrl, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'Write your note...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await HiveService.vaultNotesBox.add({
                  'subject': widget.subjectName,
                  'path': _currentRelativePath,
                  'content': ctrl.text,
                  'date': DateTime.now().toIso8601String(),
                });
                Navigator.pop(ctx);
                setState(() {}); // Refresh list
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _importPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      await FileService.importPDF(
        File(result.files.single.path!),
        widget.subjectName,
        subPath: _navigationStack,
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return PopScope(
      canPop: _navigationStack.isEmpty,
      onPopInvoked: (didPop) {
        if (!didPop && _navigationStack.isNotEmpty) {
          _popFolder();
        }
      },
      child: Scaffold(
        body: ValueListenableBuilder(
          valueListenable: HiveService.vaultNotesBox.listenable(),
          builder: (context, Box box, _) {
            final notes = box.values
                .where((n) => n['subject'] == widget.subjectName && n['path'] == _currentRelativePath)
                .toList();

            return CustomScrollView(
              slivers: [
                // 1. Breadcrumb Bar
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: _buildBreadcrumbBar(),
                  ),
                ),

                // 2. Combined Entities List (Folders, PDFs, Notes)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _entities.length) {
                          final entity = _entities[index];
                          if (entity is Directory) {
                            return _buildFolderTile(entity);
                          } else {
                            return _buildFileTile(entity as File);
                          }
                        } else {
                          final noteIndex = index - _entities.length;
                          return _buildNoteTile(notes[noteIndex], box);
                        }
                      },
                      childCount: _entities.length + notes.length,
                    ),
                  ),
                ),
                
                // Empty State
                if (_entities.isEmpty && notes.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('This folder is empty', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMenu,
          child: const Icon(Icons.add_rounded, size: 32),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbBar() {
    return Container(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _navigationStack.length + 1,
        separatorBuilder: (_, __) => const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        itemBuilder: (context, index) {
          final isRoot = index == 0;
          final isLast = index == _navigationStack.length;
          final name = isRoot ? widget.subjectName : _navigationStack[index - 1];

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isLast ? null : () {
              setState(() {
                if (isRoot) _navigationStack.clear();
                else _navigationStack = _navigationStack.sublist(0, index - 1 + 1);
              });
              _loadData();
            },
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                color: isLast ? AppTheme.primaryColor : Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderTile(Directory dir) {
    final name = dir.path.split(Platform.pathSeparator).last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            debugPrint('SOLID CLICK: Opening folder: $name');
            setState(() => _navigationStack.add(name));
            _loadData();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber, size: 32),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Chapter Folder'),
              trailing: const Icon(Icons.chevron_right, size: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileTile(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            debugPrint('SOLID CLICK: Opening PDF: $name');
            final absolutePath = file.absolute.path;
            if (await File(absolutePath).exists()) {
              if (mounted) {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => PdfStudyScreen(filePath: absolutePath, title: name)),
                );
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 32),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('PDF Document'),
              trailing: const Icon(Icons.open_in_new, size: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(dynamic note, Box box) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        child: ListTile(
          leading: const Icon(Icons.note, color: Colors.blueAccent, size: 28),
          title: Text(note['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(note['date'].toString().substring(0, 10)),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () {
              final key = box.keys.firstWhere((k) => box.get(k) == note);
              box.delete(key);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FileSystemEntity entity) async {
    final isFile = entity is File;
    final name = entity.path.split(Platform.pathSeparator).last;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${isFile ? 'File' : 'Folder'}'),
        content: Text('Are you sure you want to delete "$name"?${isFile ? '' : '\nThis will delete all contents inside.'}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      final provider = context.read<PdfAnnotationProvider>();
      await FileService.deleteEntity(entity, provider);
      _loadData();
    }
  }
}
