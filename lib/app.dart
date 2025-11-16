import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';
import 'manager/manager_dashboard.dart';
import '../employee/employee_dashboard.dart';

class TaskFlowManager extends StatelessWidget {
  const TaskFlowManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow Manager',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF7A00),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFF7A00),
          secondary: Color(0xFFFF7A00),
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF7A00),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7A00),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF7A00)),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final AuthState state = snapshot.data!;
          if (state.event == AuthChangeEvent.signedIn) {
            return const RoleBasedRedirect();
          }
        }
        return const LoginPage();
      },
    );
  }
}

class RoleBasedRedirect extends StatefulWidget {
  const RoleBasedRedirect({super.key});

  @override
  State<RoleBasedRedirect> createState() => _RoleBasedRedirectState();
}

class _RoleBasedRedirectState extends State<RoleBasedRedirect> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      
      setState(() {
        userRole = response['role'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return userRole == 'manager' 
        ? const ManagerDashboard() 
        : const EmployeeDashboard();
  }
}