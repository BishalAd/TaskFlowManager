import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';

class ManagerTasksPage extends StatefulWidget {
  const ManagerTasksPage({super.key});

  @override
  State<ManagerTasksPage> createState() => _ManagerTasksPageState();
}

class _ManagerTasksPageState extends State<ManagerTasksPage> {
  final List<Task> _tasks = [];
  final List<AppUser> _employees = [];
  bool _isLoading = true;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTasks(),
      _loadEmployees(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadTasks() async {
    final tasks = await SupabaseService.getTasks(isCompleted: _showCompleted);
    setState(() => _tasks.clear());
    setState(() => _tasks.addAll(tasks));
  }

  Future<void> _loadEmployees() async {
    final employees = await SupabaseService.getEmployees();
    setState(() => _employees.clear());
    setState(() => _employees.addAll(employees));
  }

  void _toggleCompletedFilter() {
    setState(() {
      _showCompleted = !_showCompleted;
      _isLoading = true;
    });
    _loadTasks().then((_) => setState(() => _isLoading = false));
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(
        employees: _employees,
        onTaskAdded: _loadTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _showCompleted ? 'Completed Tasks' : 'Pending Tasks',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _showCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: const Color(0xFFFF7A00),
                        ),
                        onPressed: _toggleCompletedFilter,
                      ),
                    ],
                  ),
                ),
                // Tasks List
                Expanded(
                  child: _tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return TaskCard(
                              task: task,
                              onTaskUpdated: _loadTasks,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    
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
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Assigned to: ${task.assignedUserName ?? 'All Employees'}',
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
                    '${DateFormat('MMM d, y').format(task.dueDate)} at ${task.dueTime!.substring(0, 5)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _deleteTask();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SupabaseService.deleteTask(widget.task.id!);
      widget.onTaskUpdated();
    }
  }
}

class AddTaskDialog extends StatefulWidget {
  final List<AppUser> employees;
  final VoidCallback onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.employees,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedEmployeeId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;
  bool _assignToAll = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = await SupabaseService.getCurrentUser();
    if (currentUser == null) return;

    // create task without setting id (leave model id as String or String?)
final task = Task(
  // do NOT set id here — keep your model's id value empty or a placeholder
  id: null, // <- keep model happy; actual DB id will be generated
  title: _titleController.text.trim(),
  description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
  assignedTo: _assignToAll ? null : _selectedEmployeeId,
  assignedBy: currentUser.id,
  dueDate: _selectedDate,
  dueTime: _selectedTime != null
      ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
      : null,
  isRecurring: _isRecurring,
  isCompleted: false,
  createdAt: DateTime.now(),
  isPersonal: true,
);

    await SupabaseService.createTask(task);
    widget.onTaskAdded();
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create New Task',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Assignment Section
              const Text(
                'Assign To:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _assignToAll,
                    onChanged: (value) {
                      setState(() {
                        _assignToAll = value ?? false;
                        if (_assignToAll) {
                          _selectedEmployeeId = null;
                        }
                      });
                    },
                    activeColor: const Color(0xFFFF7A00),
                  ),
                  const Text('All Employees'),
                ],
              ),
              if (!_assignToAll) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedEmployeeId,
                  decoration: const InputDecoration(
                    labelText: 'Select Employee',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select an employee'),
                    ),
                    ...widget.employees.map((employee) {
                      return DropdownMenuItem(
                        value: employee.id,
                        child: Text(employee.fullName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedEmployeeId = value);
                  },
                  validator: (value) {
                    if (!_assignToAll && (value == null || value.isEmpty)) {
                      return 'Please select an employee';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM d, y').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Select Time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Recurring Option
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() => _isRecurring = value ?? false);
                    },
                    activeColor: const Color(0xFFFF7A00),
                  ),
                  const Text('Repeat Daily'),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create Task'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}