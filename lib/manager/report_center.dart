import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';

class ReportCenterPage extends StatefulWidget {
  const ReportCenterPage({super.key});

  @override
  State<ReportCenterPage> createState() => _ReportCenterPageState();
}

class _ReportCenterPageState extends State<ReportCenterPage> {
  final List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await SupabaseService.getReports();
    setState(() {
      _reports.clear();
      _reports.addAll(reports);
      _isLoading = false;
    });
  }

  void _showResponseDialog(Map<String, dynamic> report) {
    final TextEditingController responseController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report: ${report['title']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Description: ${report['description']}'),
            const SizedBox(height: 16),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                labelText: 'Your Response',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isNotEmpty) {
                await SupabaseService.updateReportStatus(
                  report['id'] as String,
                  'resolved',
                  managerResponse: responseController.text.trim(),
                );
                await _loadReports();
                if (mounted) Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Center'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(
                  child: Text(
                    'No reports submitted yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return ReportCard(
                      report: report,
                      onRespond: () => _showResponseDialog(report),
                    );
                  },
                ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onRespond;

  const ReportCard({
    super.key,
    required this.report,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final bool isResolved = report['status'] == 'resolved';
    final String employeeName = report['users']?['full_name'] ?? 'Unknown';

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
                    report['title'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green : const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isResolved ? 'Resolved' : 'Open',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'By: $employeeName',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              report['description'] as String,
              style: const TextStyle(fontSize: 14),
            ),
            if (report['image_url'] != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(report['image_url'] as String),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            if (report['manager_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manager Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(report['manager_response'] as String),
                  ],
                ),
              ),
            ],
            if (!isResolved) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRespond,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Respond to Report'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Submitted: ${_formatDate(report['created_at'] as String)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}