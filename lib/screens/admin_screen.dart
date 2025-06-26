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
import 'analytics_dashboard_screen.dart';
import 'payment_tracking_screen.dart';
import 'enhanced_analytics_dashboard_screen.dart';
import 'financial_reports_screen.dart';
import 'invoice_management_screen.dart';
import 'enhanced_features_summary_screen.dart';
import '../widgets/theme_selector.dart';

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

  Future<void> _removeAgentProfilePicture(String agentId) async {
    try {
      await DatabaseService().removeAgentProfilePicture(agentId);
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                    if (isEditing && agent.id == currentUserId) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickAndUpdateProfilePicture(agent.id),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Change Picture'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: agent.profilePicture != null
                                ? () => _removeAgentProfilePicture(agent.id)
                                : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                  color: agent.profilePicture != null
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                ),
                              ),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          : _errorMessage != null
              ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      floating: false,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.primaryColor,
                                theme.primaryColor.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                      ),
                      actions: const [
                        ThemeToggleButton(),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Analytics Overview Section
                            Text(
                              'Analytics Overview',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Stats Cards Grid
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.9,
                              children: [
                                _buildModernStatCard(
                                  'Pending',
                                  _pendingCount,
                                  Icons.pending_actions,
                                  Colors.orange,
                                  theme,
                                ),
                                _buildModernStatCard(
                                  'In Transit',
                                  _inTransitCount,
                                  Icons.local_shipping,
                                  Colors.blue,
                                  theme,
                                ),
                                _buildModernStatCard(
                                  'Delivered',
                                  _deliveredCount,
                                  Icons.check_circle,
                                  Colors.green,
                                  theme,
                                ),
                              ],
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
                                      title: Text(
                                        agent.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            agent.email,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            agent.mobile,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                leading: const Icon(Icons.analytics, color: Color(0xFF1976D2)),
                                title: const Text('Analytics Dashboard'),
                                subtitle: const Text('View comprehensive business analytics'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AnalyticsDashboardScreen(
                                        agent: Agent(
                                          id: '1',
                                          name: 'Admin User',
                                          email: 'admin@zipbus2.com',
                                          password: 'admin123',
                                          mobile: '1234567890',
                                          isAdmin: true,
                                          isFrozen: false,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.payment, color: Color(0xFF1976D2)),
                                title: const Text('Payment Tracking'),
                                subtitle: const Text('Track and monitor all payments (Admin Only)'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentTrackingScreen(
                                        agent: Agent(
                                          id: '1',
                                          name: 'Admin User',
                                          email: 'admin@zipbus2.com',
                                          password: 'admin123',
                                          mobile: '1234567890',
                                          isAdmin: true,
                                          isFrozen: false,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.rocket_launch, color: Color(0xFF1976D2)),
                                title: const Text('Enhanced Features Overview'),
                                subtitle: const Text('View all new business intelligence features'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EnhancedFeaturesSummaryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.analytics_outlined, color: Color(0xFF1976D2)),
                                title: const Text('Enhanced Analytics'),
                                subtitle: const Text('Customer analytics, satisfaction scores & business intelligence'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EnhancedAnalyticsDashboardScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.attach_money, color: Color(0xFF1976D2)),
                                title: const Text('Financial Reports'),
                                subtitle: const Text('Daily/monthly revenue summaries & profit analysis'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FinancialReportsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.receipt_long, color: Color(0xFF1976D2)),
                                title: const Text('Invoice Management'),
                                subtitle: const Text('Generate & manage automated PDF invoices'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const InvoiceManagementScreen(),
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
                                leading: const Icon(Icons.palette, color: Color(0xFF1976D2)),
                                title: const Text('Theme Settings'),
                                subtitle: const Text('Change app appearance'),
                                onTap: () {
                                  ThemeSelector.showThemeBottomSheet(context);
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
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAgentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }



  Widget _buildModernStatCard(String title, int count, IconData icon, Color color, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
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