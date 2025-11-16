import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/supabase_service.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;
  final bool showAssignee;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    this.showAssignee = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final bool isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) async {
            if (value != null) {
              await SupabaseService.updateTask(
                task.copyWith(isCompleted: value),
              );
              widget.onTaskUpdated();
            }
          },
          activeColor: const Color(0xFFFF7A00),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: isOverdue && !task.isCompleted ? Colors.red : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isOverdue && !task.isCompleted ? Colors.red : null,
                ),
              ),
            const SizedBox(height: 4),
            if (widget.showAssignee && task.assignedUserName != null)
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${task.assignedUserName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            if (task.dueTime != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.dueTime!.substring(0, 5),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (isOverdue && !task.isCompleted) ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(
                    Icons.warning,
                    size: 12,
                    color: Colors.red,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: task.isRecurring
            ? const Icon(Icons.repeat, color: Color(0xFFFF7A00))
            : null,
      ),
    );
  }
}