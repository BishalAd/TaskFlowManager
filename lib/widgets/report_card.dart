import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onRespond;
  final bool showActions;

  const ReportCard({
    super.key,
    required this.report,
    this.onRespond,
    this.showActions = true,
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
            if (showActions && !isResolved && onRespond != null) ...[
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