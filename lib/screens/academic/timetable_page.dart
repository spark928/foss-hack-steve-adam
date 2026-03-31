import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/providers/academic_provider.dart';

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  static const List<String> _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  bool _isClassNow(String startTime, String endTime, int dayOfWeek) {
    final now = DateTime.now();
    if (now.weekday != dayOfWeek) return false;
    
    // Parse HH:mm (24h)
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final startMins = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMins = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      final nowMins = now.hour * 60 + now.minute;
      
      return nowMins >= startMins && nowMins <= endMins;
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller, Function(void Function()) setDialogState) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), // Force 24h for consistent parsing
          child: child!,
        );
      },
    );
    if (picked != null) {
      setDialogState(() {
        final h = picked.hour.toString().padLeft(2, '0');
        final m = picked.minute.toString().padLeft(2, '0');
        controller.text = '$h:$m';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      initialIndex: DateTime.now().weekday - 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Timetable'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: _dayNames.map((d) => Tab(text: d.substring(0, 3))).toList(),
          ),
        ),
        body: Consumer<AcademicProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              children: List.generate(7, (i) {
                final dayOfWeek = i + 1;
                final classes = provider.getScheduleForDay(dayOfWeek);

                if (classes.isEmpty) {
                  return const Center(child: Text('No classes scheduled.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final sched = classes[index];
                    final subName = provider.getSubjectName(sched.subjectId) ?? 'Unknown';
                    final isLive = _isClassNow(sched.startTime, sched.endTime, dayOfWeek);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isLive ? Colors.green.withOpacity(0.1) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isLive ? const BorderSide(color: Colors.green, width: 1) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isLive ? Colors.green.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLive ? Icons.sensors_rounded : Icons.class_rounded, 
                            color: isLive ? Colors.green : AppTheme.primaryColor
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(subName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (isLive) ...[
                              const SizedBox(width: 8),
                              const Text('● ONGOING', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ],
                        ),
                        subtitle: Text('${sched.startTime} – ${sched.endTime}${sched.room != null && sched.room!.isNotEmpty ? '  •  Room: ${sched.room}' : ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          onPressed: () => provider.deleteSchedule(sched.id),
                        ),
                      ),
                    );
                  },
                );
              }),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: null,
          onPressed: () => _showAddScheduleDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) {
    final provider = Provider.of<AcademicProvider>(context, listen: false);
    final subjects = provider.subjects;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add an academic subject first!')));
      return;
    }

    String? selectedSubjectId = subjects.first.id;
    int selectedDay = DateTime.now().weekday;
    final startCtrl = TextEditingController(text: '09:00');
    final endCtrl = TextEditingController(text: '10:00');
    final roomCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Add Class'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.subjectName))).toList(),
                      onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: List.generate(7, (i) => DropdownMenuItem(value: i + 1, child: Text(_dayNames[i]))),
                      onChanged: (v) => setDialogState(() => selectedDay = v!),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: startCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        suffixIcon: Icon(Icons.access_time_rounded),
                      ),
                      onTap: () => _selectTime(ctx, startCtrl, setDialogState),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: endCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        suffixIcon: Icon(Icons.access_time_rounded),
                      ),
                      onTap: () => _selectTime(ctx, endCtrl, setDialogState),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room (Optional)')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSubjectId != null && startCtrl.text.isNotEmpty && endCtrl.text.isNotEmpty) {
                      provider.addSchedule(selectedSubjectId!, selectedDay, startCtrl.text, endCtrl.text, roomCtrl.text.isEmpty ? null : roomCtrl.text);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
