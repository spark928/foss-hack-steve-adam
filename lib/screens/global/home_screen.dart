import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:study_app/models/event.dart';
import 'package:study_app/models/todo.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/widgets/custom_card.dart';
import 'package:study_app/screens/subject/subject_shell.dart';
import 'package:study_app/providers/subject_provider.dart';
import 'package:study_app/providers/chapter_provider.dart';
import 'package:study_app/providers/study_provider.dart';
import 'package:study_app/providers/note_provider.dart';
import 'package:study_app/providers/todo_provider.dart';
import 'package:study_app/providers/event_provider.dart';
import 'package:study_app/models/subject.dart';
import 'package:study_app/screens/global/search_screen.dart';
import 'package:study_app/screens/global/todo_list_page.dart';
import 'package:study_app/widgets/notification_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _showNotifications(context),
          ),
        ],
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          final subjects = subjectProvider.subjects;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Upcoming Events ──
              _buildUpcomingEvents(context),

              // ── To-do Section ──
              _buildTodoSection(context),

              // ── Subjects list ──
              if (subjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text("No subjects yet. Add one!")),
                )
              else
                ...subjects.map((subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSubjectCard(context, subject),
                )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddSubjectDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  UPCOMING EVENTS SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildUpcomingEvents(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.eventsBox.listenable(),
      builder: (context, Box<Event> box, _) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final upcoming = box.values
            .where((e) => !e.date.isBefore(today))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Events', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  tooltip: 'Add Event',
                  onPressed: () => _showAddEventDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final event = upcoming[index];
                  final icon = _eventIcon(event.type);
                  final color = _eventColor(event.type);
                  
                  final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
                  final daysLeft = eventDate.difference(today).inDays;
                  final daysStr = daysLeft == 0 ? 'Today' : (daysLeft == 1 ? 'Tomorrow' : '$daysLeft days left');

                  return GestureDetector(
                    onTap: () => _showEventDetailDialog(context, event),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(icon, size: 20, color: color),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold, 
                                  color: color,
                                  decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                daysStr,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'test': return Icons.quiz_outlined;
      case 'exam': return Icons.school_outlined;
      case 'programme': return Icons.event_outlined;
      default: return Icons.event_note_outlined;
    }
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'test': return AppTheme.warning;
      case 'exam': return AppTheme.error;
      case 'programme': return AppTheme.primaryColor;
      default: return AppTheme.success;
    }
  }

  void _showEventDetailDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.calendar_today, 'Date', DateFormat('EEEE, MMM d, yyyy').format(event.date)),
            const SizedBox(height: 8),
            _detailRow(Icons.label_outline, 'Type', event.type[0].toUpperCase() + event.type.substring(1)),
            const SizedBox(height: 8),
            _detailRow(Icons.check_circle_outline, 'Status', event.isCompleted ? 'Completed' : 'Pending'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<EventProvider>(context, listen: false).toggleStatus(event.id);
              Navigator.pop(context);
            },
            child: Text(event.isCompleted ? 'Mark Pending' : 'Mark Completed'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<EventProvider>(context, listen: false).deleteEvent(event.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'other';
    final types = ['test', 'exam', 'programme', 'other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat('MMM d, yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  Provider.of<EventProvider>(ctx, listen: false)
                      .addEvent(Event(title: titleCtrl.text, date: selectedDate, type: selectedType));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TO-DO SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildTodoSection(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.todosBox.listenable(),
      builder: (context, Box<Todo> box, _) {
        final todos = box.values.where((t) => t.subjectId == 'general').toList();
        final remaining = todos.where((t) => !t.isCompleted).length;
        final allDone = todos.isNotEmpty && remaining == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('To-do', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(width: 8),
                if (todos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: remaining > 0 ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      remaining > 0 ? '$remaining remaining' : 'All done!',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: remaining > 0 ? AppTheme.primaryColor : AppTheme.success),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoListPage(subjectId: 'general'))),
                  child: const Text('View all', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (allDone)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CustomCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.success, size: 24),
                        const SizedBox(width: 12),
                        Text('All tasks completed! 🎉', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              ...todos.take(5).map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32, height: 32,
                      child: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (_) => Provider.of<TodoProvider>(context, listen: false).toggleTodo(todo.id),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        todo.task,
                        style: TextStyle(
                          fontSize: 14,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                          color: todo.isCompleted ? Colors.grey : null,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 28, height: 28,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        onPressed: () => Provider.of<TodoProvider>(context, listen: false).deleteTodo(todo.id),
                      ),
                    ),
                  ],
                ),
              )),
              _QuickAddTodoField(),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SUBJECTS
  // ════════════════════════════════════════════════════════════════
  Widget _buildSubjectCard(BuildContext context, Subject subject) {
    final baseColor = Color(subject.colorValue);
    final hsl = HSLColor.fromColor(baseColor);
    final gradient = LinearGradient(
      colors: [
        hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 1.0)).toColor(),
        hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Consumer<ChapterProvider>(
      builder: (context, chapterProvider, child) {
        final chaptersCount = chapterProvider.getChaptersForSubject(subject.id).length;
        
        return CustomCard(
          gradient: gradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectShell(
                  subject: subject,
                ),
              ),
            );
          },
          onLongPress: () => _showDeleteSubjectDialog(context, subject),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subject.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: () => _showDeleteSubjectDialog(context, subject),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildStatChip(context, Icons.menu_book_rounded, '$chaptersCount Chapters'),
                  const SizedBox(width: 12),
                  Consumer<StudyProvider>(
                    builder: (context, studyProvider, child) {
                      final mins = studyProvider.getTotalStudyTimeForSubject(subject.id);
                      final hoursStr = mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '${mins}m';
                      return _buildStatChip(context, Icons.timer_rounded, hoursStr);
                    },
                  ), 
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedColor = AppTheme.primaryColor.value;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Subject Name'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorOption(context, AppTheme.primaryColor.value, selectedColor, (val) => selectedColor = val),
                  _colorOption(context, AppTheme.cardGradient1.colors.first.value, selectedColor, (val) => selectedColor = val),
                  _colorOption(context, AppTheme.cardGradient2.colors.first.value, selectedColor, (val) => selectedColor = val),
                  _colorOption(context, AppTheme.cardGradient3.colors.first.value, selectedColor, (val) => selectedColor = val),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  Provider.of<SubjectProvider>(context, listen: false).addSubject(
                    nameController.text,
                    selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _colorOption(BuildContext context, int colorValue, int selectedValue, Function(int) onSelect) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTap: () {
            onSelect(colorValue);
            setState(() {});
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color(colorValue),
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedValue == colorValue ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }
    );
  }

  void _showDeleteSubjectDialog(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subject?'),
          content: Text('Are you sure you want to delete "${subject.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final subjectId = subject.id;
                
                final chapterIds = Provider.of<ChapterProvider>(context, listen: false)
                    .getChaptersForSubject(subjectId)
                    .map((c) => c.id)
                    .toList();
                
                for (final cId in chapterIds) {
                  Provider.of<NoteProvider>(context, listen: false).deleteNotesForChapter(cId);
                  Provider.of<StudyProvider>(context, listen: false).deleteSessionsForChapter(cId);
                }
                
                Provider.of<NoteProvider>(context, listen: false).deleteNotesForChapter(subjectId);
                Provider.of<StudyProvider>(context, listen: false).deleteSessionsForSubject(subjectId);
                Provider.of<ChapterProvider>(context, listen: false).deleteChaptersForSubject(subjectId);
                Provider.of<SubjectProvider>(context, listen: false).deleteSubject(subjectId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    NotificationSheet.show(context);
  }
}

// ════════════════════════════════════════════════════════════════
//  Quick-Add To-do inline widget (needs its own State for the controller)
// ════════════════════════════════════════════════════════════════
class _QuickAddTodoField extends StatefulWidget {
  @override
  State<_QuickAddTodoField> createState() => _QuickAddTodoFieldState();
}

class _QuickAddTodoFieldState extends State<_QuickAddTodoField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Quick add task…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Provider.of<TodoProvider>(context, listen: false).addTodo(val.trim(), 'general', null);
                  _ctrl.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
