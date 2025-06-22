import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../models/agent.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Agent agent;

  const ProfileScreen({super.key, required this.agent});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Agent _currentAgent;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentAgent = widget.agent;
  }

  Future<void> _fetchCurrentAgent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agent = await DatabaseService().getAgentById(widget.agent.id);
      if (agent != null && mounted) {
        setState(() {
          _currentAgent = agent;
          _isLoading = false;
        });
      } else {
        throw Exception('Agent not found');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to refresh profile: $e';
          _isLoading = false;
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
        await _fetchCurrentAgent();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // Blue theme
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(
                    agent: _currentAgent,
                    onUpdate: _fetchCurrentAgent,
                  ),
                ),
              );
            },
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
                        onPressed: _fetchCurrentAgent,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _currentAgent.profilePicture != null
                            ? NetworkImage(_currentAgent.profilePicture!)
                            : null,
                        child: _currentAgent.profilePicture == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _pickAndUpdateProfilePicture(_currentAgent.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF57C00), // Orange theme
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Change Profile Picture'),
                      ),
                      const SizedBox(height: 24),
                      // Profile Details
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2), // Blue theme
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildProfileField('Name', _currentAgent.name),
                              _buildProfileField('Email', _currentAgent.email),
                              _buildProfileField('Mobile', _currentAgent.mobile),
                              _buildProfileField('Role', _currentAgent.isAdmin ? 'Admin' : 'Agent'),
                              _buildProfileField('Status', _currentAgent.isFrozen ? 'Frozen' : 'Active'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFFF57C00), // Orange theme
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}