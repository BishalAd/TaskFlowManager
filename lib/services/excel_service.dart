import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../models/task_model.dart';

class ExcelService {
  static Future<String> exportTasksToExcel(List<Task> tasks) async {
    // Create Excel
    var excel = Excel.createExcel();
    var sheet = excel['Tasks'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Description'),
      TextCellValue('Due Date'),
      TextCellValue('Due Time'),
      TextCellValue('Status'),
      TextCellValue('Type'),
      TextCellValue('Completed At'),
    ]);

    // Add data
    for (final task in tasks) {
      sheet.appendRow([
        TextCellValue(task.title),
        TextCellValue(task.description ?? ''),
        TextCellValue(_formatDate(task.dueDate)),
        TextCellValue(task.dueTime ?? ''),
        TextCellValue(task.isCompleted ? 'Completed' : 'Pending'),
        TextCellValue(task.isPersonal ? 'Personal' : 'Assigned'),
        TextCellValue(task.completedAt != null ? _formatDateTime(task.completedAt!) : ''),
      ]);
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/tasks_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    
    var bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    // Open the file
    await OpenFile.open(filePath);

    return filePath;
  }

  static Future<String> exportAttendanceToExcel(List<Map<String, dynamic>> records) async {
    // Create Excel
    var excel = Excel.createExcel();
    var sheet = excel['Attendance'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Employee Name'),
      TextCellValue('Date'),
      TextCellValue('Start Time'),
      TextCellValue('End Time'),
      TextCellValue('Hours Worked'),
      TextCellValue('Status'),
    ]);

    // Add data
    for (final record in records) {
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

      sheet.appendRow([
        TextCellValue(employeeName),
        TextCellValue(_formatDate(date)),
        TextCellValue(startTime != null ? _formatTime(startTime) : ''),
        TextCellValue(endTime != null ? _formatTime(endTime) : ''),
        TextCellValue(hoursWorked.toStringAsFixed(2)),
        TextCellValue(startTime != null && endTime != null ? 'Present' : 'Incomplete'),
      ]);
    }

    // Save file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/attendance_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    
    var bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    // Open the file
    await OpenFile.open(filePath);

    return filePath;
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}