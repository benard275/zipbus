import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent.dart';
import '../services/database_service.dart';
import 'admin_screen.dart';
import 'parcel_form_screen.dart';
import 'parcel_list_screen.dart';
import 'profile_screen.dart';
import 'delivery_schedule_screen.dart';
import 'qr_scanner_screen.dart';
import 'chat_list_screen.dart';
import '../widgets/theme_selector.dart';

class HomeScreen extends StatefulWidget {
  final Agent agent;

  const HomeScreen({super.key, required this.agent});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Agent _agent;
  final DatabaseService _databaseService = DatabaseService();
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _agent = widget.agent;
    _loadUnreadMessageCount();

    // Debug: Print admin status on initialization
    debugPrint('ZipBus Home Init: User ${_agent.name} (${_agent.email}) - Admin: ${_agent.isAdmin}');
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final count = await _databaseService.getUnreadMessageCount(_agent.id);
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      // Silently handle error - not critical for home screen
      debugPrint('Error loading unread message count: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Yes, Log Out
            child: const Text('Yes, Log Out'),
          ),
        ],
      ),
    );

    // Proceed with logout only if confirmed
    if (confirmLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_agent_email');
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'ZipBus Dashboard',
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
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(agent: _agent),
                    ),
                  );
                },
                tooltip: 'Profile',
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: () => _logout(context),
                tooltip: 'Logout',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.1),
                          theme.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                            backgroundImage: _agent.profilePicture != null &&
                                    File(_agent.profilePicture!).existsSync()
                                ? FileImage(File(_agent.profilePicture!))
                                : null,
                            child: _agent.profilePicture == null ||
                                    !File(_agent.profilePicture!).existsSync()
                                ? Icon(
                                    Icons.person,
                                    size: 32,
                                    color: theme.primaryColor,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.primaryColor.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _agent.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 16,
                                    color: theme.primaryColor.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _agent.email,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.primaryColor.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: theme.primaryColor.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _agent.mobile,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.primaryColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Quick Actions Section
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Cards Grid
                  _buildActionCardsGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCardsGrid() {
    // Build list of all cards that should be displayed
    List<Widget> cards = [
      // 1. Create Parcel - Available to ALL users
      _buildCard(
        context,
        icon: Icons.add_box,
        label: 'Create Parcel',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParcelFormScreen(agent: _agent),
            ),
          );
        },
      ),
      // 2. View Parcels - Available to ALL users
      _buildCard(
        context,
        icon: Icons.list,
        label: 'View Parcels',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParcelListScreen(agent: _agent),
            ),
          );
        },
      ),
      // 3. Delivery Schedule - Available to ALL users
      _buildCard(
        context,
        icon: Icons.schedule,
        label: 'Delivery Schedule',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryScheduleScreen(agent: _agent),
            ),
          );
        },
      ),
      // 4. Scan QR Code - Available to ALL users
      _buildCard(
        context,
        icon: Icons.qr_code_scanner,
        label: 'Scan QR Code',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRScannerScreen(),
            ),
          );
        },
      ),
      // 5. Messages - Available to ALL users
      _buildChatCard(
        context,
        icon: Icons.chat,
        label: 'Messages',
        unreadCount: _unreadMessageCount,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatListScreen(currentUser: _agent),
            ),
          );
          // Refresh unread count when returning from chat
          _loadUnreadMessageCount();
        },
      ),
    ];

    // 6. Admin Panel - ONLY for Admin users
    if (_agent.isAdmin) {
      cards.add(
        _buildCard(
          context,
          icon: Icons.admin_panel_settings,
          label: 'Admin Panel',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminScreen(),
              ),
            );
          },
        ),
      );
    }

    // Debug: Print card count and admin status
    debugPrint('ZipBus Home: Displaying ${cards.length} cards for ${_agent.isAdmin ? "ADMIN" : "AGENT"} user: ${_agent.name}');

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: cards,
    );
  }

  Widget _buildCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required int unreadCount,
    required VoidCallback onTap
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: theme.primaryColor,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade500,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}