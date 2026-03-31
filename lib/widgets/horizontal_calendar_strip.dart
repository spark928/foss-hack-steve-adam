import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_app/theme/app_theme.dart';
import 'package:study_app/providers/academic_provider.dart';

class HorizontalCalendarStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const HorizontalCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<HorizontalCalendarStrip> createState() => _HorizontalCalendarStripState();
}

class _HorizontalCalendarStripState extends State<HorizontalCalendarStrip> {
  late ScrollController _scrollController;
  late List<DateTime> _days;
  late int _todayIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _buildDaysList();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _buildDaysList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfMonth = DateTime(now.year, now.month, 1);

    _days = [];
    // Add all days from start of month up to today + 7 days ahead
    final lastDay = today.add(const Duration(days: 7));

    var current = firstOfMonth;
    while (!current.isAfter(lastDay)) {
      _days.add(current);
      current = current.add(const Duration(days: 1));
    }

    _todayIndex = _days.indexWhere((d) => d == today);
    if (_todayIndex < 0) _todayIndex = 0;
  }

  void _scrollToToday() {
    if (!_scrollController.hasClients) return;
    const cellWidth = 60.0; // 52 + 8 padding
    final offset = (_todayIndex * cellWidth) - (MediaQuery.of(context).size.width / 2 - cellWidth / 2);
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final provider = Provider.of<AcademicProvider>(context);
    final selectedDay = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = day == selectedDay;
          final isToday = day == today;
          final hasClasses = provider.getScheduleForDay(day.weekday).isNotEmpty;

          final dayAbbr = _weekdayAbbr(day.weekday);

          return GestureDetector(
            onTap: () => widget.onDateSelected(day),
            child: Container(
              width: 52,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5)
                    : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayAbbr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isToday && !isSelected)
                        Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        ),
                      if (isToday && !isSelected && hasClasses) const SizedBox(width: 3),
                      if (hasClasses)
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white60 : AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _weekdayAbbr(int weekday) {
    const abbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrs[weekday - 1];
  }
}
