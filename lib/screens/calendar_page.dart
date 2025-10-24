import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';
import '../providers/milestone_provider.dart';
import '../models/milestone.dart';
import '../widgets/add_edit_task_dialog.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

/// Lớp Wrapper cho các sự kiện trên lịch
class _CalEvent {
  final String kind;
  final String title;
  final String? subtitle;
  final DateTime date;
  final Color? color;
  final dynamic raw;

  _CalEvent({
    required this.kind,
    required this.title,
    this.subtitle,
    required this.date,
    this.color,
    this.raw,
  });
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<_CalEvent>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);

    Future.microtask(() {
      final tp = Provider.of<TaskProvider>(context, listen: false);
      final mp = Provider.of<MilestoneProvider>(context, listen: false);
      tp.loadTasks();
      mp.loadMilestones();
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Color _parseColor(String? hex, {Color fallback = Colors.blue}) {
    if (hex == null) return fallback;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    try {
      return Color(int.parse(s, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  List<_CalEvent> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    final List<_CalEvent> out = [];

    final taskProv = Provider.of<TaskProvider>(context, listen: false);
    final milestoneProv = Provider.of<MilestoneProvider>(context, listen: false);

    for (var t in taskProv.tasks) {
      if (t.dueDate == null) continue;
      final d = DateTime.utc(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      if (isSameDay(d, key)) {
        Color col = _parseColor(t.projectColors.isNotEmpty ? t.projectColors.first : null, fallback: Colors.cyan);
        out.add(_CalEvent(
          kind: 'task',
          title: t.title,
          subtitle: t.note,
          date: d,
          color: col,
          raw: t,
        ));
      }
    }

    for (var m in milestoneProv.milestones) {
      if (m.date == null) continue;
      final d = DateTime.utc(m.date!.year, m.date!.month, m.date!.day);
      if (isSameDay(d, key)) {
        Color projectColor = _parseColor(m.projectColors.isNotEmpty ? m.projectColors.first : null, fallback: Colors.amber);
        out.add(_CalEvent(
          kind: 'milestone',
          title: m.name,
          subtitle: m.description,
          date: d,
          color: projectColor,
          raw: m,
        ));
      }
    }
    return out;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  Widget _buildMarkers(BuildContext context, DateTime date, List events) {
    if (events.isEmpty) return const SizedBox.shrink();
    final markers = <Widget>[];
    for (var e in events.take(4)) {
      if (e is _CalEvent) {
        final color = e.color ?? (e.kind == 'milestone' ? Colors.red : Colors.blue);
        Widget marker = e.kind == 'milestone'
            ? Icon(Icons.star, color: color, size: 10)
            : Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
        markers.add(Padding(padding: const EdgeInsets.symmetric(horizontal: 1.5), child: marker));
      }
    }
    return Positioned(
      bottom: 5,
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: markers),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe provider để rebuild khi dữ liệu thay đổi
    Provider.of<TaskProvider>(context);
    Provider.of<MilestoneProvider>(context);

    if (_selectedDay != null) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }

    return Scaffold(
      body: Column(
        children: [
          TableCalendar<_CalEvent>(
            locale: 'vi_VN',
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerDecoration: const BoxDecoration(),
              todayDecoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.3), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
            ),
            calendarBuilders: CalendarBuilders<_CalEvent>(
              markerBuilder: _buildMarkers,
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<List<_CalEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                if (events.isEmpty) return Center(child: Text('Không có sự kiện cho ngày này.', style: TextStyle(color: Colors.grey[600])));
                return RefreshIndicator(
                  onRefresh: () async {
                    await Provider.of<TaskProvider>(context, listen: false).loadTasks();
                    await Provider.of<MilestoneProvider>(context, listen: false).loadMilestones();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventTile(event);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- HÀM BUILD TILE ĐÃ ĐƯỢC KHÔI PHỤC ĐẦY ĐỦ ---
  Widget _buildEventTile(_CalEvent event) {
    if (event.kind == 'task') {
      final Task t = event.raw as Task;
      final taskProv = Provider.of<TaskProvider>(context, listen: false);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: (event.color ?? Colors.blue).withOpacity(0.2),
              child: Icon(Icons.task_alt, color: event.color ?? Colors.blue, size: 22)
          ),
          title: Text(t.title, style: TextStyle(decoration: t.isDone ? TextDecoration.lineThrough : null)),
          subtitle: t.projectName != null && t.projectName!.isNotEmpty ? Text(t.projectName!) : null,
          trailing: t.dueDate != null ? Text(DateFormat('dd/MM').format(t.dueDate!)) : null,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(t.title),
                content: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (t.projectName != null) Text('Dự án: ${t.projectName}'),
                        const SizedBox(height: 8),
                        Text('Ghi chú: ${t.note ?? 'Không có'}'),
                        const SizedBox(height: 8),
                        Text('Hạn chót: ${t.dueDate != null ? DateFormat.yMd().add_jm().format(t.dueDate!) : 'Không có'}'),
                        Text('Hoàn thành: ${t.isDone ? 'Rồi' : 'Chưa'}'),
                      ]),
                ),
                actions: [

                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
                ],
              ),
            );
          },
        ),
      );
    } else {
      final Milestone m = event.raw as Milestone;
      final projColor = event.color ?? Colors.amber;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
              backgroundColor: projColor.withOpacity(0.2),
              child: Icon(Icons.flag_circle, color: projColor, size: 22)
          ),
          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(m.projectName ?? ''),
          trailing: m.date != null ? Text(DateFormat('dd/MM').format(m.date!)) : null,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(m.name),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (m.projectName != null) Text('Dự án: ${m.projectName}'),
                      const SizedBox(height: 8),
                      Text('Mô tả: ${m.description ?? 'Không có'}'),
                      const SizedBox(height: 8),
                      Text('Ngày: ${m.date != null ? DateFormat.yMd().format(m.date!) : 'Không có'}'),
                    ],
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
              ),
            );
          },
        ),
      );
    }
  }
}