import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://dqufjhazuaofdordneta.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxdWZqaGF6dWFvZmRvcmRuZXRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxNDIyMzksImV4cCI6MjA3ODcxODIzOX0.C1OPZm3mvhmgkJeZ3lBTx7aNc1ECTOvCvSRS7Uwg8TU',
  );

  // Initialize notifications
  await NotificationService.initialize();

  // Set up error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // You can also send errors to a logging service
    Text('Flutter Error: ${details.exception}');
  };

  // Run the app with error boundary
  runApp(const TaskFlowManager());
}

// Optional: Add a custom error widget for better error handling
class ErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ErrorWidget({super.key, required this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please restart the app',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // You could add app restart logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}