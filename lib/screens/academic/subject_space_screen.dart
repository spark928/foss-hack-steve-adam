import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:study_app/services/file_service.dart';
import 'package:study_app/providers/pdf_annotation_provider.dart';
import 'package:study_app/providers/subject_note_provider.dart';
import 'package:study_app/models/academic/subject_note.dart';
import 'package:study_app/screens/academic/pdf_study_screen.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/widgets/custom_card.dart';

class SubjectSpaceScreen extends StatefulWidget {
  final String subjectName;
  final List<String> subPath;

  const SubjectSpaceScreen({
    super.key,
    required this.subjectName,
    this.subPath = const [],
  });

  @override
  State<SubjectSpaceScreen> createState() => _SubjectSpaceScreenState();
}

class _SubjectSpaceScreenState extends State<SubjectSpaceScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load Files/Chapters
    final files = await FileService.getSubjectContents(
      widget.subjectName,
      subPath: widget.subPath,
    );
    
    // Load Notes (Only at root level for now, or match chapter)
    if (mounted) {
      context.read<SubjectNoteProvider>().loadNotes(widget.subjectName);
    }

    setState(() {
      _files = files;
      _isLoading = false;
    });
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
            Text(
              'Add to ${widget.subPath.isEmpty ? widget.subjectName : widget.subPath.last}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _menuOption(
              icon: Icons.create_new_folder_rounded,
              label: 'New Chapter',
              color: Colors.amber,
              onTap: () {
                Navigator.pop(ctx);
                _showCreateChapterDialog();
              },
            ),
            _menuOption(
              icon: Icons.upload_file_rounded,
              label: 'Import PDF',
              color: Colors.redAccent,
              onTap: () {
                Navigator.pop(ctx);
                _importPDF();
              },
            ),
            _menuOption(
              icon: Icons.note_add_rounded,
              label: 'New Quick Note',
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

  Widget _menuOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
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
        title: const Text('New Chapter'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter chapter name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await FileService.createChapter(
                  widget.subjectName, 
                  ctrl.text, 
                  currentPath: widget.subPath,
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
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quick Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Note content...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty) {
                await context.read<SubjectNoteProvider>().addNote(
                  widget.subjectName,
                  titleCtrl.text,
                  content: contentCtrl.text,
                );
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _importPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final importedFile = await FileService.importPDF(
        sourceFile,
        widget.subjectName,
        subPath: widget.subPath,
      );
      
      if (importedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF imported successfully!')),
          );
        }
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subPath.isEmpty ? widget.subjectName : widget.subPath.last),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData),
        ],
      ),
      body: Consumer<SubjectNoteProvider>(
        builder: (context, noteProvider, child) {
          final notes = widget.subPath.isEmpty 
              ? noteProvider.getNotesForSubject(widget.subjectName) 
              : <SubjectNote>[];
              
          final allItems = [
            ..._files,
            ...notes,
          ];

          if (_isLoading) return const Center(child: CircularProgressIndicator());

          if (allItems.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];

              if (item is Directory) {
                return _buildFolderTile(item);
              } else if (item is File && item.path.endsWith('.pdf')) {
                return _buildPDFTile(item);
              } else if (item is SubjectNote) {
                return _buildNoteTile(item);
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'The Space is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Add chapters, PDFs, or notes to begin.', style: TextStyle(color: Colors.grey)),
        ],
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
            debugPrint('SOLID CLICK: Opening sub-folder: $name');
            final nextPath = [...widget.subPath, name];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectSpaceScreen(
                  subjectName: widget.subjectName,
                  subPath: nextPath,
                ),
              ),
            ).then((_) => _loadData());
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.folder_rounded, color: Colors.amber, size: 32),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Chapter Folder'),
              trailing: const Icon(Icons.chevron_right, size: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPDFTile(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            debugPrint('SOLID CLICK: Opening PDF in Sub-Space: $name');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfStudyScreen(filePath: file.path, title: name),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('PDF Document'),
              trailing: const Icon(Icons.open_in_new, size: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTile(SubjectNote note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        child: ListTile(
          leading: const Icon(Icons.note_alt_rounded, color: Colors.blueAccent, size: 32),
          title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => context.read<SubjectNoteProvider>().deleteNote(note),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEntity(FileSystemEntity entity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure? This action is permanent and deletes all associated annotations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FileService.deleteEntity(
        entity,
        context.read<PdfAnnotationProvider>(),
      );
      if (success) _loadData();
    }
  }
}
