import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_app/providers/note_provider.dart';
import 'package:study_app/providers/enote_provider.dart';
import 'package:study_app/widgets/custom_card.dart';
import 'package:study_app/screens/chapter/note_editor_screen.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

class SubjectNotesTab extends StatefulWidget {
  final String subjectId;

  const SubjectNotesTab({super.key, required this.subjectId});

  @override
  State<SubjectNotesTab> createState() => _SubjectNotesTabState();
}

class _SubjectNotesTabState extends State<SubjectNotesTab> {
  int _selectedTab = 0; // 0 for Written, 1 for Files

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Written'), icon: Icon(Icons.edit_note)),
              ButtonSegment(value: 1, label: Text('Files'), icon: Icon(Icons.file_copy)),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedTab = newSelection.first;
              });
            },
          ),
        ),
        Expanded(
          child: _selectedTab == 0 ? _buildWrittenNotes() : _buildFileNotes(),
        ),
      ],
    );
  }

  Widget _buildWrittenNotes() {
    return Scaffold(
      body: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          final notes = noteProvider.getNotesForChapter(widget.subjectId);

          if (notes.isEmpty) {
            return const Center(child: Text("No subject notes yet. Create one!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NoteEditorScreen(noteId: note.id),
                      ),
                    );
                  },
                  onLongPress: () => _showDeleteNoteDialog(context, note),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edited ${DateFormat('MMM d, h:mm a').format(note.lastEdited)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_written_note',
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.note_add),
        label: const Text('New subject note'),
      ),
    );
  }

  Widget _buildFileNotes() {
    return Scaffold(
      body: Consumer<ENoteProvider>(
        builder: (context, enoteProvider, child) {
          final enotes = enoteProvider.getENotes(subjectId: widget.subjectId);

          if (enotes.isEmpty) {
            return const Center(child: Text("No files imported yet. Import one!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: enotes.length,
            itemBuilder: (context, index) {
              final enote = enotes[index];
              final icon = enote.fileType == 'pdf'
                  ? Icons.picture_as_pdf
                  : (enote.fileType == 'image' ? Icons.image : Icons.insert_drive_file);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  onTap: () => OpenFilex.open(enote.filePath),
                  onLongPress: () => _showDeleteENoteDialog(context, enote),
                  child: Row(
                    children: [
                      Icon(icon, size: 40, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enote.title,
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Imported ${DateFormat('MMM d, yyyy').format(enote.importedAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _showDeleteENoteDialog(context, enote),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_file_note',
        onPressed: () => Provider.of<ENoteProvider>(context, listen: false).importFile(subjectId: widget.subjectId),
        icon: const Icon(Icons.file_upload),
        label: const Text('Import file'),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Subject Note'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Note Title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Provider.of<NoteProvider>(context, listen: false).addNote(
                    widget.subjectId,
                    titleController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteNoteDialog(BuildContext context, dynamic note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: Text('Are you sure you want to delete "${note.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Provider.of<NoteProvider>(context, listen: false).deleteNote(note.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteENoteDialog(BuildContext context, dynamic enote) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete File?'),
          content: Text('Are you sure you want to delete "${enote.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Provider.of<ENoteProvider>(context, listen: false).deleteENote(enote.id);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
