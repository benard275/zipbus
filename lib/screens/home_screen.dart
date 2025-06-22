import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent.dart';
import 'admin_screen.dart';
import 'parcel_form_screen.dart';
import 'parcel_list_screen.dart';
import 'profile_screen.dart';
import 'delivery_schedule_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final Agent agent;

  const HomeScreen({super.key, required this.agent});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Agent _agent;

  @override
  void initState() {
    super.initState();
    _agent = widget.agent;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZipBus Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
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
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _agent.profilePicture != null &&
                              File(_agent.profilePicture!).existsSync()
                          ? FileImage(File(_agent.profilePicture!))
                          : null,
                      child: _agent.profilePicture == null ||
                              !File(_agent.profilePicture!).existsSync()
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _agent.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_agent.email),
                        Text(_agent.mobile),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
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
                  if (_agent.isAdmin)
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF1976D2)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}