import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../services/supabase_service.dart';

class EmployeeReportsPage extends StatefulWidget {
  const EmployeeReportsPage({super.key});

  @override
  State<EmployeeReportsPage> createState() => _EmployeeReportsPageState();
}

class _EmployeeReportsPageState extends State<EmployeeReportsPage> {
  final List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final reports = await SupabaseService.getUserReports(user.id);
      setState(() {
        _reports.clear();
        _reports.addAll(reports);
        _isLoading = false;
      });
    } catch (e) {
      Text('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSubmitReportDialog() {
    showDialog(
      context: context,
      builder: (context) => SubmitReportDialog(onReportSubmitted: _loadReports),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7A00)),
              ),
            )
          : Column(
              children: [
                // Statistics
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                            'Total', _reports.length.toString(), Colors.blue),
                        _buildStatItem(
                            'Open',
                            _reports
                                .where((r) => r['status'] == 'open')
                                .length
                                .toString(),
                            const Color(0xFFFF7A00)),
                        _buildStatItem(
                            'Resolved',
                            _reports
                                .where((r) => r['status'] == 'resolved')
                                .length
                                .toString(),
                            Colors.green),
                      ],
                    ),
                  ),
                ),
                // Reports List
                Expanded(
                  child: _reports.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.report_problem,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reports submitted yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap the + button to submit your first report',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReports,
                          color: const Color(0xFFFF7A00),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              final report = _reports[index];
                              return EmployeeReportCard(report: report);
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSubmitReportDialog,
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class EmployeeReportCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const EmployeeReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final bool isResolved = report['status'] == 'resolved';
    final String employeeName = report['users']?['full_name'] ?? 'You';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isResolved ? Colors.green : const Color(0xFFFF7A00),
                    borderRadius: BorderRadius.circular(8),
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
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            if (report['image_url'] != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Show image in full screen
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        width: double.infinity,
                        height: 400,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(report['image_url'] as String),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(report['image_url'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (report['manager_response'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.message, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Manager Response:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report['manager_response'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
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
    try {
      final date = DateTime.parse(dateString);
      return '${_getMonthName(date.month)} ${date.day}, ${date.year} at ${_formatTime(date)}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class SubmitReportDialog extends StatefulWidget {
  final VoidCallback onReportSubmitted;

  const SubmitReportDialog({super.key, required this.onReportSubmitted});

  @override
  State<SubmitReportDialog> createState() => _SubmitReportDialogState();
}

class _SubmitReportDialogState extends State<SubmitReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _imagePath;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _imagePath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_imagePath == null) return null;

    try {
      final file = File(_imagePath!);
      final fileBytes = await file.readAsBytes();
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('reports')
          .uploadBinary(fileName, fileBytes);

      final publicUrl = Supabase.instance.client.storage
          .from('reports')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String? imageUrl = await _uploadImage();

      await SupabaseService.submitReport(
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );

      widget.onReportSubmitted();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem, color: Color(0xFFFF7A00)),
                    SizedBox(width: 8),
                    Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Report Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter report title';
                    }
                    if (value.length < 5) {
                      return 'Title should be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter report description';
                    }
                    if (value.length < 10) {
                      return 'Description should be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Image Upload
                OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Color(0xFFFF7A00)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo,
                        color: _imagePath != null
                            ? Colors.green
                            : const Color(0xFFFF7A00),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _imagePath != null
                            ? 'Image Selected'
                            : 'Add Image (Optional)',
                        style: TextStyle(
                          color: _imagePath != null
                              ? Colors.green
                              : const Color(0xFFFF7A00),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_imagePath != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Image ready for upload',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _imagePath = null),
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Submit Report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
