import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/excel_service.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({super.key});

  @override
  State<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  final List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = true;
  String _selectedPeriod = 'daily';
  String? _selectedEmployeeId;
  final List<Map<String, dynamic>> _employees = [];

  final Map<String, String> _periods = {
    'daily': 'Today',
    'weekly': 'Last 7 Days',
    'monthly': 'Last Month',
    'yearly': 'Last Year',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadEmployees();
    await _loadAttendanceRecords();
  }

  Future<void> _loadEmployees() async {
    final employees = await SupabaseService.getEmployees();
    setState(() {
      _employees.clear();
      _employees.addAll(employees.map((e) => {
        'id': e.id,
        'name': e.fullName,
      }).toList());
    });
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() => _isLoading = true);
    
    final records = await SupabaseService.getAttendanceAnalytics(
      period: _selectedPeriod,
      userId: _selectedEmployeeId,
    );
    
    setState(() {
      _attendanceRecords.clear();
      _attendanceRecords.addAll(records);
      _isLoading = false;
    });
  }

  Future<void> _exportToExcel() async {
    try {
      final filePath = await ExcelService.exportAttendanceToExcel(_attendanceRecords);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to: $filePath'),
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
    int presentDays = 0;
    int totalDays = _attendanceRecords.length;
    double totalHours = 0;

    for (final record in _attendanceRecords) {
      if (record['start_time'] != null && record['end_time'] != null) {
        presentDays++;
        
        final start = DateTime.parse(record['start_time'] as String);
        final end = DateTime.parse(record['end_time'] as String);
        final hours = end.difference(start).inHours.toDouble();
        totalHours += hours;
      }
    }

    return {
      'presentDays': presentDays,
      'totalDays': totalDays,
      'averageHours': totalDays > 0 ? totalHours / presentDays : 0,
      'attendanceRate': totalDays > 0 ? (presentDays / totalDays) * 100 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Analytics'),
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
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                    ),
                    items: _periods.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPeriod = value!);
                      _loadAttendanceRecords();
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: 'Employee (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Employees'),
                      ),
                      ..._employees.map((employee) {
                        return DropdownMenuItem(
                          value: employee['id'] as String,
                          child: Text(employee['name'] as String),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedEmployeeId = value);
                      _loadAttendanceRecords();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard(
                  'Attendance Rate',
                  '${stats['attendanceRate'].toStringAsFixed(1)}%',
                  const Color(0xFFFF7A00),
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Present Days',
                  '${stats['presentDays']}/${stats['totalDays']}',
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Avg Hours/Day',
                  stats['averageHours'].toStringAsFixed(1),
                  Colors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Records List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _attendanceRecords.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance records found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = _attendanceRecords[index];
                          return AttendanceRecordCard(record: record);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const AttendanceRecordCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final employeeName = record['users']?['full_name'] ?? 'Unknown';
    final date = DateTime.parse(record['date'] as String);
    final startTime = record['start_time'] != null 
        ? DateTime.parse(record['start_time'] as String) 
        : null;
    final endTime = record['end_time'] != null 
        ? DateTime.parse(record['end_time'] as String) 
        : null;

    double hoursWorked = 0;
    if (startTime != null && endTime != null) {
      hoursWorked = endTime.difference(startTime).inMinutes / 60.0;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: startTime != null && endTime != null 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            startTime != null && endTime != null ? Icons.check_circle : Icons.schedule,
            color: startTime != null && endTime != null ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(employeeName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM d, y').format(date)),
            if (startTime != null) 
              Text('In: ${DateFormat('HH:mm').format(startTime)}'),
            if (endTime != null) 
              Text('Out: ${DateFormat('HH:mm').format(endTime)}'),
            if (hoursWorked > 0)
              Text(
                'Hours: ${hoursWorked.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}