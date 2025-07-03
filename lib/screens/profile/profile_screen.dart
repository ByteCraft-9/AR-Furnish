// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

const Color primaryColor = Color(0xFF854836);

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({Key? key, required this.onLogout}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  User? user;
  String name = '';
  String email = '';
  String phone = '';
  String avatarUrl = '';
  bool isLoading = true;
// Set to 3 for Profile tab

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    setState(() {
      isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        user = currentUser;
        email = user?.email ?? 'No Email';
      });

      try {
        var docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (docSnapshot.exists) {
          setState(() {
            name = docSnapshot['name'] ?? 'Guest User';
            phone = docSnapshot['phone'] ?? '';
            avatarUrl = docSnapshot['avatar'] ?? '';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Sign Out',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          content:
              const Text('Are you sure you want to sign out of your account?'),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onLogout();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : CustomScrollView(
              slivers: [
                // App Bar with Profile Header
                SliverAppBar(
                  expandedHeight: 220.0,
                  pinned: true,
                  backgroundColor: primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF9D6E5A),
                            primaryColor,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 50.0,
                              backgroundColor:
                                  Theme.of(context).cardColor.withOpacity(0.9),
                              child: avatarUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.network(
                                        avatarUrl,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'G',
                                      style: const TextStyle(
                                        fontSize: 45.0,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Profile Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Account Section
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .shadowColor
                                    .withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSectionHeader('Account'),
                              _buildMenuItem(
                                icon: Icons.shopping_bag_outlined,
                                title: 'My Orders',
                                subtitle:
                                    'View order history and track current orders',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/orders'),
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              _buildMenuItem(
                                icon: Icons.favorite_border,
                                title: 'Wishlist',
                                subtitle: 'Products you have saved for later',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/wishlist'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Settings Section
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .shadowColor
                                    .withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSectionHeader('User Settings'),
                              _buildMenuItem(
                                icon: Icons.location_on_outlined,
                                title: 'Addresses',
                                subtitle: 'Manage your delivery addresses',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/address'),
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              _buildMenuItem(
                                icon: Icons.payment_outlined,
                                title: 'Payment Methods',
                                subtitle: 'Manage your payment options',
                                onTap: () => Navigator.pushNamed(
                                    context, '/payment-method'),
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              _buildMenuItem(
                                icon: Icons.notifications_outlined,
                                title: 'Notification Settings',
                                subtitle:
                                    'Control what notifications you receive',
                                onTap: () => Navigator.pushNamed(
                                    context, '/notifications'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // App Settings Section
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .shadowColor
                                    .withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSectionHeader('Application'),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                title: 'Settings',
                                subtitle: 'App preferences and configuration',
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              _buildMenuItem(
                                icon: Icons.info_outline,
                                title: 'About',
                                subtitle: 'App information and legal details',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('AR Furnish v1.0.0')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
