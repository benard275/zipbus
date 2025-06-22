import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/agent.dart'; // Added import for Agent class

class ActivityTrackingScreen extends StatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  State<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  List<Map<String, String>> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activities = await DatabaseService().getActivities();
      final users = await DatabaseService().getAllAgents();
      if (mounted) {
        setState(() {
          _activities = activities.map((activity) {
            final user = users.firstWhere(
              (agent) => agent.id == activity['user_id'],
              orElse: () => Agent(
                id: activity['user_id']!,
                name: 'Unknown User',
                email: '',
                password: '',
                mobile: '',
                isAdmin: false,
                isFrozen: false,
              ),
            );
            return {
              'time': activity['time']!,
              'user': user.name,
              'action': activity['action']!,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load activities: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Activities'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // Blue theme
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchActivities,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _activities.isEmpty
                  ? const Center(child: Text('No activities recorded.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _activities.length,
                      itemBuilder: (context, index) {
                        final activity = _activities[index];
                        return Card(
                          elevation: 4,
                          child: ListTile(
                            title: Text(activity['action']!),
                            subtitle: Text('${activity['time']} - ${activity['user']}'),
                          ),
                        );
                      },
                    ),
    );
  }
}