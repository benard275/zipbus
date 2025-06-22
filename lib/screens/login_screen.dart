import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent.dart';
import '../services/database_service.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      try {
        final Agent? agent = await DatabaseService().getAgentByEmail(email);

        if (agent == null) {
          setState(() {
            _errorMessage = 'User not found. Please check your email.';
          });
          return;
        }

        if (agent.isFrozen) {
          setState(() {
            _errorMessage = 'Account is frozen. Contact support.';
          });
          return;
        }

        if (agent.password != password) {
          setState(() {
            _errorMessage = 'Incorrect password. Please try again.';
          });
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_agent_email', email);

        final savedEmail = prefs.getString('current_agent_email');
        if (savedEmail != email) {
          throw Exception('Failed to save session. Please try again.');
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: agent,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Login failed: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Enter email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Enter password' : null,
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
              // Removed "Create Account" button to restrict registration to admins
            ],
          ),
        ),
      ),
    );
  }
}