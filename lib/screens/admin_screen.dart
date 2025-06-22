import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/agent.dart';
import '../services/database_service.dart';
import 'privacy_and_security_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'profile_screen.dart';
import 'agent_parcel_screen.dart';
import 'activity_tracking_screen.dart';
import 'notification_test_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Agent> _agents = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _pendingCount = 0;
  int _inTransitCount = 0;
  int _deliveredCount = 0;
  String? _operationResult;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agents = await DatabaseService().getAllAgents();
      final pendingCount = await DatabaseService().getPendingParcelsCount();
      final inTransitCount = await DatabaseService().getInTransitParcelsCount();
      final deliveredCount = await DatabaseService().getDeliveredParcelsCount();

      if (mounted) {
        setState(() {
          _agents = agents;
          _pendingCount = pendingCount;
          _inTransitCount = inTransitCount;
          _deliveredCount = deliveredCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAgent(String agentId) async {
    try {
      await DatabaseService().deleteAgent(agentId);
      await _fetchData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to delete agent: $e';
        });
      }
    }
  }

  Future<void> _pickAndUpdateProfilePicture(String agentId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      try {
        await DatabaseService().updateAgentProfilePicture(agentId, pickedFile.path);
        await _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile picture: $e')),
          );
        }
      }
    }
  }

  void _showAddEditAgentDialog({Agent? agent}) {
    final isEditing = agent != null;
    final nameController = TextEditingController(text: agent?.name ?? '');
    final emailController = TextEditingController(text: agent?.email ?? '');
    final passwordController = TextEditingController(text: agent?.password ?? '');
    final mobileController = TextEditingController(text: agent?.mobile ?? '');
    bool isAdmin = agent?.isAdmin ?? false;
    bool isFrozen = agent?.isFrozen ?? false;
    final currentUserId = DatabaseService().getCurrentUser().id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Agent' : 'Add New Agent'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    TextField(
                      controller: mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile'),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isAdmin,
                          onChanged: (value) {
                            setDialogState(() {
                              isAdmin = value ?? false;
                            });
                          },
                        ),
                        const Text('Admin Role'),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: isFrozen,
                          onChanged: (value) {
                            setDialogState(() {
                              isFrozen = value ?? false;
                            });
                          },
                        ),
                        const Text('Freeze Account'),
                      ],
                    ),
                    if (isEditing && agent.id == currentUserId)
                      ElevatedButton(
                        onPressed: () => _pickAndUpdateProfilePicture(agent.id),
                        child: const Text('Update Profile Picture'),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final newAgent = Agent(
                      id: isEditing ? agent.id : const Uuid().v4(),
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text,
                      mobile: mobileController.text.trim(),
                      profilePicture: agent?.profilePicture,
                      isAdmin: isAdmin,
                      isFrozen: isFrozen,
                    );

                    if (Navigator.canPop(dialogContext)) {
                      Navigator.pop(dialogContext);
                    }

                    DatabaseService().thenAgentOperation(
                      isEditing ? () => DatabaseService().updateAgent(newAgent) : () => DatabaseService().insertAgent(newAgent),
                      onSuccess: () {
                        if (mounted) {
                          setState(() {
                            _operationResult = isEditing ? 'Agent updated successfully' : 'Agent added successfully';
                          });
                          _fetchData().then((_) {
                            if (mounted) {
                              setState(() {
                                _operationResult = null;
                              });
                            }
                          });
                        }
                      },
                      onError: (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Operation failed: $e')),
                          );
                        }
                      },
                    );
                  },
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _operationResult = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        centerTitle: true,
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
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Parcel Analysis Section
                        const Text(
                          'Parcel Analysis',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatCard(
                                      'Received but Pending',
                                      _pendingCount,
                                      const Color(0xFFF57C00), // Orange
                                    ),
                                    _buildStatCard(
                                      'In Transit',
                                      _inTransitCount,
                                      const Color(0xFF1976D2), // Blue
                                    ),
                                    _buildStatCard(
                                      'Delivered',
                                      _deliveredCount,
                                      Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Agents Section
                        const Text(
                          'Agents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_operationResult != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _operationResult!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        _agents.isEmpty
                            ? const Center(child: Text('No agents found.'))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _agents.length,
                                itemBuilder: (context, index) {
                                  final agent = _agents[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(agent.name),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(agent.email),
                                          Text(agent.mobile),
                                          Text('Role: ${agent.isAdmin ? 'Admin' : 'Agent'}'),
                                          Text('Status: ${agent.isFrozen ? 'Frozen' : 'Active'}'),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showAddEditAgentDialog(agent: agent),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteAgent(agent.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(height: 24),
                        // Settings Section
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 4,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person, color: Color(0xFF1976D2)),
                                title: const Text('Profile'),
                                onTap: () async {
                                  if (_agents.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No agents loaded. Please try again later.')),
                                    );
                                    return;
                                  }
                                  final currentUserId = DatabaseService().getCurrentUser().id;
                                  final agent = _agents.firstWhere(
                                    (a) => a.id == currentUserId,
                                    orElse: () => _agents.firstWhere(
                                      (a) => a.isAdmin,
                                      orElse: () => _agents.first,
                                    ),
                                  );
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(agent: agent),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.local_shipping, color: Color(0xFF1976D2)),
                                title: const Text('My Parcels'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AgentParcelScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.history, color: Color(0xFF1976D2)),
                                title: const Text('Track Activities'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ActivityTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.notifications_active, color: Color(0xFF1976D2)),
                                title: const Text('Test Notifications'),
                                subtitle: const Text('Test the new messaging system'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationTestScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.lock, color: Color(0xFF1976D2)),
                                title: const Text('Privacy & Security'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PrivacyAndSecurityScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.description, color: Color(0xFF1976D2)),
                                title: const Text('Terms & Conditions'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TermsAndConditionsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAgentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

extension DatabaseServiceExtension on DatabaseService {
  Future<void> thenAgentOperation(Future<void> Function() operation, {required VoidCallback onSuccess, required Function(dynamic) onError}) async {
    try {
      await operation();
      onSuccess();
    } catch (e) {
      onError(e);
    }
  }
}