import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/models/subject.dart';
import 'package:study_app/providers/academic_provider.dart';
import 'package:study_app/models/academic/subject_attendance.dart';
import 'package:study_app/screens/subject/tabs/subject_performance_tab.dart';
import 'package:study_app/screens/global/tools_page.dart';
import 'package:study_app/screens/subject/subject_space_page.dart';

class SubjectShell extends StatelessWidget {
  final Subject subject;

  const SubjectShell({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(subject.colorValue).withAlpha(40),
          elevation: 0,
          iconTheme: Theme.of(context).iconTheme.copyWith(color: AppTheme.primaryColor),
          title: Text(subject.name, style: Theme.of(context).textTheme.headlineMedium),
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 56.0), // Below the app bar title area
              child: _buildAttendanceBar(context),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104), // Title + Attendance bar + Tabs
            child: Column(
              children: [
                const SizedBox(height: 56), // Space for attendance bar (approx height)
                TabBar(
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'Study Space'),
                    Tab(text: 'Tools'),
                    Tab(text: 'Performance'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            SubjectSpacePage(subjectName: subject.name),
            ToolsGrid(specificSubjectId: subject.id),
            SubjectPerformanceTab(subjectId: subject.id),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBar(BuildContext context) {
    return Consumer<AcademicProvider>(
      builder: (context, provider, child) {
        final attendance = provider.subjects.firstWhere(
          (s) => s.subjectName.toLowerCase() == subject.name.toLowerCase(),
          orElse: () => SubjectAttendance(subjectName: ''),
        );

        if (attendance.subjectName.isEmpty) {
          return Center(
            child: ActionChip(
              avatar: const Icon(Icons.add_chart, size: 16),
              label: const Text('Track attendance'),
              onPressed: () => _showTrackAttendanceDialog(context),
            ),
          );
        }

        final pct = attendance.attendancePercentage;
        final color = pct >= 75.0 ? AppTheme.success : AppTheme.error;

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance: ${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                        ),
                        Text(
                          '${attendance.attendedClasses}/${attendance.totalClasses}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: attendance.totalClasses == 0 ? 1.0 : pct / 100,
                        backgroundColor: Colors.grey.shade300,
                        color: color,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.check_circle_outline, color: AppTheme.success),
                onPressed: () => provider.markAttendance(attendance.id, 'present'),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                onPressed: () => provider.markAttendance(attendance.id, 'absent'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTrackAttendanceDialog(BuildContext context) {
    final pctCtrl = TextEditingController(text: '75');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Track ${subject.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set your required attendance percentage for this subject.'),
            const SizedBox(height: 16),
            TextField(
              controller: pctCtrl,
              decoration: const InputDecoration(labelText: 'Required %', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final pct = double.tryParse(pctCtrl.text) ?? 75.0;
              Provider.of<AcademicProvider>(context, listen: false).addSubject(subject.name, pct);
              Navigator.pop(ctx);
            },
            child: const Text('Start Tracking'),
          ),
        ],
      ),
    );
  }
}
