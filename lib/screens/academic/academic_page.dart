import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/widgets/custom_card.dart';
import 'package:study_app/widgets/horizontal_calendar_strip.dart';
import 'package:study_app/providers/academic_provider.dart';
import 'package:study_app/models/academic/subject_attendance.dart';
import 'package:study_app/screens/academic/subject_attendance_detail.dart';
import 'package:study_app/screens/academic/timetable_page.dart';
import 'package:study_app/providers/event_provider.dart';
import 'package:study_app/models/event.dart';
import 'package:study_app/providers/todo_provider.dart';
import 'package:study_app/providers/subject_provider.dart';
import 'package:study_app/models/subject.dart';
import 'package:study_app/database/hive_service.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AcademicPage extends StatefulWidget {
  const AcademicPage({super.key});

  @override
  State<AcademicPage> createState() => _AcademicPageState();
}

class _AcademicPageState extends State<AcademicPage> {
  late DateTime _selectedDate;

  bool _isCurrentlyInClass(String subjectName) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    final currentMins = now.hour * 60 + now.minute;

    final schedules = HiveService.classSchedulesBox.values.where((s) => s.dayOfWeek == dayOfWeek).toList();
    
    for (var sched in schedules) {
      // Get the name for this schedule's subjectId
      final schedSubName = HiveService.academicSubjectsBox.get(sched.subjectId)?.subjectName;
      if (schedSubName == subjectName) {
        try {
          final startParts = sched.startTime.split(':');
          final endParts = sched.endTime.split(':');
          final startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
          final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
          
          if (currentMins >= startMins && currentMins <= endMins) return true;
        } catch (_) {}
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Timetable',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetablePage())),
          ),
        ],
      ),
      body: Consumer<AcademicProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              HorizontalCalendarStrip(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildDashboard(context, provider),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildClassesForDate(context, provider),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildUpcomingEventsSection(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTodoSection(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder(
                valueListenable: HiveService.classSchedulesBox.listenable(),
                builder: (context, Box box, _) {
                  if (provider.subjects.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No academic subjects yet. Add one!')));
                  }
                  return Column(
                    children: provider.subjects.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSubjectTile(context, provider, s),
                    )).toList(),
                  );
                },
              ),
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

  Widget _buildDashboard(BuildContext context, AcademicProvider provider) {
    return Row(
      children: [
        Expanded(child: _statCard(context, 'Subjects', '${provider.subjects.length}', AppTheme.primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _statCard(context, 'Overall', '${provider.overallAttendance.toStringAsFixed(provider.overallAttendance % 1 == 0 ? 0 : 1)}%', AppTheme.success)),
        const SizedBox(width: 8),
        Expanded(child: _statCard(context, 'At Risk', '${provider.subjectsAtRisk}', AppTheme.error)),
        const SizedBox(width: 8),
        Expanded(child: _statCard(context, 'Missed', '${provider.missedThisMonth}', AppTheme.warning)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildClassesForDate(BuildContext context, AcademicProvider provider) {
    final dayOfWeek = _selectedDate.weekday;
    final schedule = provider.getScheduleForDay(dayOfWeek);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isToday = selDay == today;

    final label = isToday ? "Today's Classes" : 'Classes';

    if (schedule.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const CustomCard(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.coffee, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No Classes Today - Time to Study!', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 120, // fixed height for horizontal cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: schedule.length,
            itemBuilder: (context, index) {
              final sched = schedule[index];
              final subName = provider.getSubjectName(sched.subjectId) ?? 'Unknown';
              final subject = provider.subjects.firstWhere((s) => s.id == sched.subjectId, orElse: () => SubjectAttendance(subjectName: 'Unknown'));

              final globalSubjects = Provider.of<SubjectProvider>(context, listen: false).subjects;
              final globalSub = globalSubjects.firstWhere(
                (s) => s.id == subject.id || s.name == subject.subjectName, 
                orElse: () => Subject(id: '', name: '', colorValue: AppTheme.primaryColor.value, createdDate: DateTime.now())
              );
              Color subjectColor = Color(globalSub.colorValue);

              return SizedBox(
                width: 160,
                child: Card(
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  color: subjectColor.withOpacity(0.15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            subName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${sched.startTime} - ${sched.endTime}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          if (sched.room != null && sched.room!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(sched.room!, style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectTile(BuildContext context, AcademicProvider provider, SubjectAttendance subject) {
    final pct = subject.attendancePercentage;
    final color = pct >= 75.0 ? AppTheme.success : AppTheme.error;
    final isLive = _isCurrentlyInClass(subject.subjectName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: isLive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              )
            : null,
        child: CustomCard(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => SubjectAttendanceDetail(subjectId: subject.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(subject.subjectName, style: Theme.of(context).textTheme.titleLarge),
                        if (isLive) ...[
                          const SizedBox(width: 8),
                          const Text('● LIVE NOW',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: subject.totalClasses == 0 ? 1.0 : pct / 100,
                  backgroundColor: Colors.grey.shade300,
                  color: color,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${subject.attendedClasses}/${subject.totalClasses} classes',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  if (pct < 75.0)
                    Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                      const SizedBox(width: 4),
                      const Text('Below 75%', style: TextStyle(color: AppTheme.warning, fontSize: 12)),
                    ])
                  else
                    const Text('Status: Good', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      subject.totalClasses++;
                      subject.attendedClasses++;
                      await subject.save();
                      provider.refresh();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Present'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.success),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      subject.totalClasses++;
                      await subject.save();
                      provider.refresh();
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Absent'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
    final academicProvider = Provider.of<AcademicProvider>(context, listen: false);
    
    final globalSubjects = subjectProvider.subjects;
    final existingNames = academicProvider.subjects.map((s) => s.subjectName).toList();
    final unaddedSubjects = globalSubjects.where((s) => !existingNames.contains(s.name)).toList();

    if (unaddedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No new subjects available! Please add subjects from the Home tab first.')),
      );
      return;
    }

    String? selectedName = unaddedSubjects.first.name;
    final pctCtrl = TextEditingController(text: '75');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Academic Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedName,
                decoration: const InputDecoration(labelText: 'Select Subject'),
                isExpanded: true,
                items: unaddedSubjects.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedName = v),
              ),
              const SizedBox(height: 8),
              TextField(controller: pctCtrl, decoration: const InputDecoration(labelText: 'Required Attendance %'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedName != null) {
                  final pct = double.tryParse(pctCtrl.text) ?? 75.0;
                  final subjectObj = unaddedSubjects.firstWhere((s) => s.name == selectedName);
                  Provider.of<AcademicProvider>(ctx, listen: false).addSubject(
                    selectedName!, 
                    pct, 
                    id: subjectObj.id
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoSection(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, _) {
        final todayTasks = todoProvider.getTodosForContext('general', null).where((t) => !t.isCompleted).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's Tasks", style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: () => _showAddTodoDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty)
              const CustomCard(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text("No tasks for today. You're all caught up!")),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayTasks.length,
                itemBuilder: (context, index) {
                  final task = todayTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CustomCard(
                      child: CheckboxListTile(
                        title: Text(
                          task.task,
                          style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null),
                        ),
                        value: task.isCompleted,
                        onChanged: (bool? value) {
                          todoProvider.toggleTodo(task.id);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final focusNode = FocusNode();
    final taskCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: taskCtrl,
          focusNode: focusNode,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What do you need to do?'),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              Provider.of<TodoProvider>(context, listen: false).addTodo(val.trim(), 'general', null);
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (taskCtrl.text.trim().isNotEmpty) {
                Provider.of<TodoProvider>(context, listen: false).addTodo(taskCtrl.text.trim(), 'general', null);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => focusNode.dispose());
  }

  Widget _buildUpcomingEventsSection(BuildContext context) {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final upcoming = eventProvider.upcomingEvents;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Events (${upcoming.length})', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  onPressed: () => _showAddEventDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const CustomCard(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No upcoming events')),
                ),
              )
            else
              SizedBox(
                height: 130, // Increased height to accommodate label
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final event = upcoming[index];
                    Color iconColor;
                    IconData iconData;
                    if (event.type == 'Exam') {
                      iconColor = Colors.red;
                      iconData = Icons.assignment_late_rounded;
                    } else if (event.type == 'Assignment') {
                      iconColor = Colors.orange;
                      iconData = Icons.task_rounded;
                    } else {
                      iconColor = Colors.blue;
                      iconData = Icons.event_note_rounded;
                    }

                    return GestureDetector(
                      onLongPress: () => eventProvider.deleteEvent(event.id), // Long press to delete
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: iconColor.withOpacity(0.1),
                                border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(iconData, color: iconColor, size: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat('MMM d').format(event.date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'Task';
    final types = ['Exam', 'Assignment', 'Task'];
    // Capture provider BEFORE dialog opens — avoids context scoping issues inside dialog
    final eventProvider = Provider.of<EventProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                isExpanded: true,
                items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final dates = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (dates != null) setDialogState(() => selectedDate = dates);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time: ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time_rounded),
                onTap: () async {
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  final newEvent = Event(title: title, date: selectedDate, type: selectedType);
                  await eventProvider.addEvent(newEvent);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Event "$title" added!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

