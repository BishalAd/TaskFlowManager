import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_model.dart';

class AttendanceCard extends StatelessWidget {
  final Attendance attendance;

  const AttendanceCard({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: attendance.isCompleted 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            attendance.isCompleted ? Icons.check_circle : Icons.schedule,
            color: attendance.isCompleted ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          attendance.userName ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, y').format(attendance.date)),
            if (attendance.startTime != null) 
              Text('In: ${DateFormat('HH:mm').format(attendance.startTime!)}'),
            if (attendance.endTime != null) 
              Text('Out: ${DateFormat('HH:mm').format(attendance.endTime!)}'),
            if (attendance.hoursWorked > 0)
              Text(
                'Hours: ${attendance.hoursWorked.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: attendance.isCompleted ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            attendance.isCompleted ? 'Complete' : 'In Progress',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}