import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../services/excel_service.dart';
import '../../models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({super.key});

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  final List<Task> _allTasks = [];
  final List<Task> _filteredTasks = [];
  bool _isLoading = true;
  String _filterStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;

  final Map<String, String> _statusFilters = {
    'all': 'All Tasks',
    'completed': 'Completed',
    'pending': 'Pending',
    'overdue': 'Overdue',
  };

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final tasks = await SupabaseService.getTasks(assignedTo: user.id);
    
    setState(() {
      _allTasks.clear();
      _allTasks.addAll(tasks);
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    List<Task> filtered = _allTasks;

    // Apply status filter
    if (_filterStatus == 'completed') {
      filtered = filtered.where((task) => task.isCompleted).toList();
    } else if (_filterStatus == 'pending') {
      filtered = filtered.where((task) => !task.isCompleted).toList();
    } else if (_filterStatus == 'overdue') {
      final now = DateTime.now();
      filtered = filtered.where((task) => 
        !task.isCompleted && task.dueDate.isBefore(now)
      ).toList();
    }

    // Apply date range filter
    if (_startDate != null) {
      filtered = filtered.where((task) => 
        task.dueDate.isAfter(_startDate!) || 
        task.dueDate.isAtSameMomentAs(_startDate!)
      ).toList();
    }

    if (_endDate != null) {
      filtered = filtered.where((task) => 
        task.dueDate.isBefore(_endDate!) || 
        task.dueDate.isAtSameMomentAs(_endDate!)
      ).toList();
    }

    // Sort by due date (most recent first)
    filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));

    setState(() {
      _filteredTasks.clear();
      _filteredTasks.addAll(filtered);
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() => _startDate = picked);
      _applyFilters();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() => _endDate = picked);
      _applyFilters();
    }
  }

  void _clearDateFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _applyFilters();
  }

  Future<void> _exportToExcel() async {
    try {
      final filePath = await ExcelService.exportTasksToExcel(_filteredTasks);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tasks exported to: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, dynamic> _calculateStats() {
    final total = _allTasks.length;
    final completed = _allTasks.where((task) => task.isCompleted).length;
    final pending = total - completed;
    final overdue = _allTasks.where((task) => 
      !task.isCompleted && task.dueDate.isBefore(DateTime.now())
    ).length;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'overdue': overdue,
      'completionRate': total > 0 ? (completed / total) * 100 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToExcel,
            tooltip: 'Export to Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Total', stats['total'].toString(), Colors.blue),
                  _buildStatItem('Completed', stats['completed'].toString(), Colors.green),
                  _buildStatItem('Pending', stats['pending'].toString(), Colors.orange),
                  _buildStatItem('Overdue', stats['overdue'].toString(), Colors.red),
                ],
              ),
            ),
          ),
          // Filters
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statusFilters.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _filterStatus = value!);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectStartDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _startDate != null
                                ? DateFormat('MMM d, y').format(_startDate!)
                                : 'Start Date',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectEndDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _endDate != null
                                ? DateFormat('MMM d, y').format(_endDate!)
                                : 'End Date',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_startDate != null || _endDate != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _clearDateFilters,
                      child: const Text('Clear Date Filters'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Completion Rate
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: stats['completionRate'] / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${stats['completionRate'].toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Tasks List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          return TaskHistoryCard(task: task);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class TaskHistoryCard extends StatelessWidget {
  final Task task;

  const TaskHistoryCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task, isOverdue),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getStatusText(task, isOverdue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  task.isPersonal ? Icons.person : Icons.work,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  task.isPersonal ? 'Personal' : 'Assigned',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, y').format(task.dueDate),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (task.dueTime != null) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.dueTime!.substring(0, 5),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            if (task.isCompleted && task.completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Completed: ${DateFormat('MMM d, y HH:mm').format(task.completedAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Task task, bool isOverdue) {
    if (task.isCompleted) return Colors.green;
    if (isOverdue) return Colors.red;
    return const Color(0xFFFF7A00);
  }

  String _getStatusText(Task task, bool isOverdue) {
    if (task.isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }
}