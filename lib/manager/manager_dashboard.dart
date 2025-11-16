import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart'; 
import 'manager_tasks.dart';
import 'manage_employees.dart';
import 'report_center.dart';
import 'attendance_analytics.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _currentIndex = 0;
  AppUser? _currentUser;
  List<Task> _todayTasks = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayTasks();
  }

  Future<void> _loadUserData() async {
    final user = await SupabaseService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadTodayTasks() async {
    final today = DateTime.now();
    final tasks = await SupabaseService.getTasks(dueDate: today);
    setState(() {
      _todayTasks = tasks;
    });
  }

  Future<void> _markAttendance(String status) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await SupabaseService.markAttendance(
      userId: user.id,
      status: status,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully marked $status!'),
        backgroundColor: const Color(0xFFFF7A00),
      ),
    );
  }

  final List<Widget> _pages = [
    const ManagerHomeTab(),
    const ManagerTasksPage(),
    const ManageEmployeesPage(),
    const ReportCenterPage(),
    const AttendanceAnalyticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_currentUser?.fullName ?? 'Manager'}'),
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
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Employees'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
        ],
      ),
    );
  }
}

class ManagerHomeTab extends StatefulWidget {
  const ManagerHomeTab({super.key});

  @override
  State<ManagerHomeTab> createState() => _ManagerHomeTabState();
}

class _ManagerHomeTabState extends State<ManagerHomeTab> {
  List<Task> _todayTasks = [];
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _loadTodayTasks();
    _loadTodayAttendance();
  }

  Future<void> _loadTodayTasks() async {
    final today = DateTime.now();
    final tasks = await SupabaseService.getTasks(dueDate: today);
    setState(() {
      _todayTasks = tasks;
    });
  }

  Future<void> _loadTodayAttendance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final attendance = await SupabaseService.getTodayAttendance(user.id);
      setState(() {
        _todayAttendance = attendance;
      });
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

  @override
  Widget build(BuildContext context) {
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
            "Today's To-Do Tasks",
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
                    'No tasks for today',
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
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: task.isCompleted 
                ? Colors.green.withOpacity(0.1)
                : const Color(0xFFFF7A00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: task.isCompleted ? Colors.green : const Color(0xFFFF7A00),
          ),
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
            Text(
              'Assigned to: ${task.assignedUserName ?? 'All Employees'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: task.dueTime != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.dueTime!.substring(0, 5),
                  style: const TextStyle(
                    color: Color(0xFFFF7A00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}