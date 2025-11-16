import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task_model.dart';

class EmployeeTasksPage extends StatefulWidget {
  const EmployeeTasksPage({super.key});

  @override
  State<EmployeeTasksPage> createState() => _EmployeeTasksPageState();
}

class _EmployeeTasksPageState extends State<EmployeeTasksPage> {
  final List<Task> _tasks = [];
  bool _isLoading = true;
  bool _showCompleted = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
  final currentUser = await SupabaseService.getCurrentUser(); 
  if (currentUser == null) return;

  final tasks = await SupabaseService.getTasks(
    assignedTo: currentUser.id, 
    dueDate: _selectedDate,
    isCompleted: _showCompleted,
  );
  
  setState(() {
    _tasks.clear();
    _tasks.addAll(tasks);
    _isLoading = false;
  });
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
      builder: (context) => AddPersonalTaskDialog(onTaskAdded: _loadTasks),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      await _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with Date Selection
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat('MMM d, y').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      _showCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: const Color(0xFFFF7A00),
                    ),
                    onPressed: _toggleCompletedFilter,
                    tooltip: _showCompleted ? 'Show Pending' : 'Show Completed',
                  ),
                ],
              ),
            ),
          ),
          // Tasks List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks found for selected date',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return EmployeeTaskCard(
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

class EmployeeTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTaskUpdated;

  const EmployeeTaskCard({
    super.key,
    required this.task,
    required this.onTaskUpdated,
  });

  @override
  State<EmployeeTaskCard> createState() => _EmployeeTaskCardState();
}

class _EmployeeTaskCardState extends State<EmployeeTaskCard> {
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
                  task.isPersonal ? Icons.person : Icons.work,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  task.isPersonal ? 'Personal Task' : 'Assigned Task',
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
          ],
        ),
        trailing: task.isRecurring
            ? const Icon(Icons.repeat, color: Color(0xFFFF7A00))
            : null,
      ),
    );
  }
}

class AddPersonalTaskDialog extends StatefulWidget {
  final VoidCallback onTaskAdded;

  const AddPersonalTaskDialog({super.key, required this.onTaskAdded});

  @override
  State<AddPersonalTaskDialog> createState() => _AddPersonalTaskDialogState();
}

class _AddPersonalTaskDialogState extends State<AddPersonalTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;

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

    final task = Task(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      assignedTo: currentUser.id,
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
          content: Text('Personal task created successfully!'),
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
                'Add Personal Task',
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
                  const SizedBox(width: 8),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Moves incomplete tasks to next day',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                      child: const Text('Add Task'),
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