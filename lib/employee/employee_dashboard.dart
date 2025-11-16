import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart'; 
import 'employee_tasks.dart';
import 'task_history.dart';
import 'employee_reports.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _currentIndex = 0;
  AppUser? _currentUser; // ← This should work now

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await SupabaseService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  final List<Widget> _pages = [
    const EmployeeHomeTab(),
    const EmployeeTasksPage(),
    const TaskHistoryPage(),
    const EmployeeReportsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_currentUser?.fullName ?? 'Employee'}'),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFFF7A00),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
        ],
      ),
    );
  }
}

class EmployeeHomeTab extends StatefulWidget {
  const EmployeeHomeTab({super.key});

  @override
  State<EmployeeHomeTab> createState() => _EmployeeHomeTabState();
}

class _EmployeeHomeTabState extends State<EmployeeHomeTab> {
  List<Task> _todayTasks = [];
  Map<String, dynamic>? _todayAttendance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTodayTasks(),
      _loadTodayAttendance(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadTodayTasks() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final tasks = await SupabaseService.getTasks(
      assignedTo: user.id,
      dueDate: today,
      isCompleted: false,
    );
    setState(() => _todayTasks = tasks);
  }

  Future<void> _loadTodayAttendance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final attendance = await SupabaseService.getTodayAttendance(user.id);
      setState(() => _todayAttendance = attendance);
    }
  }

  Future<void> _markAttendance(String status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await SupabaseService.markAttendance(
      userId: user.id,
      status: status,
    );

    await _loadTodayAttendance();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully marked $status!'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(Task task, bool completed) async {
    await SupabaseService.updateTask(
      task.copyWith(isCompleted: completed),
    );
    await _loadTodayTasks();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Mark Your Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_todayAttendance?['start_time'] == null)
                    ElevatedButton.icon(
                      onPressed: () => _markAttendance('present'),
                      icon: const Icon(Icons.login, size: 24),
                      label: const Text(
                        'Mark Present',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    )
                  else if (_todayAttendance?['end_time'] == null)
                    ElevatedButton.icon(
                      onPressed: () => _markAttendance('leave'),
                      icon: const Icon(Icons.logout, size: 24),
                      label: const Text(
                        'Mark Leave',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    )
                  else
                    const Text(
                      'Attendance completed for today',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Today's Tasks
          const Text(
            "Today's Assigned Tasks",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (_todayTasks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No tasks assigned for today',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._todayTasks.map((task) => _buildTaskCard(task)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (value) => _toggleTaskCompletion(task, value ?? false),
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
            if (task.dueTime != null) ...[
              const SizedBox(height: 4),
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
        trailing: task.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }
}