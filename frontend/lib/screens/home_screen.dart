import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart'; // Import
import '../../theme/app_theme.dart';
import 'child_management_screen.dart'; // Import (Fixed path)
import 'child_selection_screen.dart'; // Import
import 'games/star_tracer_screen.dart'; // Placeholder for "Analyze"
import 'profile/user_profile_screen.dart';
import 'profile/settings_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Pre-fetch children so the Analyze button logic works immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ChildProvider>().fetchChildren(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      // Background color handled by Theme (Light Grey / Dark Grey)
      appBar: AppBar(
        title: const Text(
          "Sahayak",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen()));
                  break;
                case 'children':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildManagementScreen()));
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  break;
                case 'logout':
                  await context.read<AuthProvider>().logout();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person), title: Text('My Profile'))),
              const PopupMenuItem(value: 'children', child: ListTile(leading: Icon(Icons.child_care), title: Text('My Children'))),
              const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Logout', style: TextStyle(color: Colors.red)))),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.account_circle),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView( // Changed to ScrollView for vertical layout
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${auth.user?.firstName ?? 'Parent'}",
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Your partner in early learning development.",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 25),

            // Educational / Info Section
            _buildInfoSection(theme),

            const SizedBox(height: 20),
            
            // Critical Info Cards (Prevention & Stats)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildInfoCard(
                    theme,
                    title: "Why Early?",
                    content: "Early intervention utilizes neuroplasticity to improve outcomes.",
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 15),
                  _buildInfoCard(
                    theme,
                    title: "Global Impact",
                    content: "Affects 1 in 5 children globally. Early detection is key.",
                    icon: Icons.public,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Main Actions Header
            Text(
              "Start Screening",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Action Cards
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: "Analyze",
                    subtitle: "Start Assessment",
                    icon: Icons.psychology,
                    color: theme.primaryColor,
                    onTap: () {
                       final childProvider = context.read<ChildProvider>();
                       if (childProvider.children.isEmpty) {
                         // No children -> Add Child Screen
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChildManagementScreen()),
                        ).then((_) {
                           // Refresh after returning (just in case they added one)
                            final token = context.read<AuthProvider>().token;
                            if (token != null) childProvider.fetchChildren(token);
                        });
                       } else {
                         // Has children -> Selection Screen
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChildSelectionScreen()),
                        );
                       }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionCard(
                    context,
                    title: "Reports",
                    subtitle: "View Progress",
                    icon: Icons.analytics_outlined,
                    color: theme.colorScheme.secondary,
                    onTap: () {
                      final childProvider = context.read<ChildProvider>();
                      if (childProvider.children.isEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChildManagementScreen()),
                        ).then((_) {
                          final token = context.read<AuthProvider>().token;
                          if (token != null) childProvider.fetchChildren(token);
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChildSelectionScreen(isForReport: true)),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Detailed Disabilities Section
            Text(
              "Understanding Disabilities",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildExpansionTile(theme, "Dyslexia (Reading)", "Difficulty with reading, spelling, and decoding words. It affects the brain's ability to process language."),
            _buildExpansionTile(theme, "Dysgraphia (Writing)", "Challenges with handwriting, typing, and spelling. It impacts fine motor skills and spatial planning."),
            _buildExpansionTile(theme, "Dyscalculia (Math)", "Difficulty understanding numbers, learning math facts, and calculating. It affects number sense and reasoning."),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 5),
                Text(content, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(ThemeData theme, String title, String content) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(Icons.help_outline, color: theme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(content, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons. verified_user_outlined, color: theme.primaryColor), // Changed Icon
              const SizedBox(width: 10),
              Text(
                "Why Early Screening Matters?", // Updated Title
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "Early identification of learning differences is crucial because the brain's neuroplasticity is highest in childhood.",
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 15),
          _buildBulletPoint(theme, "Prevent academic regression & low self-esteem."),
          const SizedBox(height: 8),
          _buildBulletPoint(theme, "Enable timely, targeted interventions."),
          const SizedBox(height: 8),
          _buildBulletPoint(theme, "Transform 'struggle' into 'strategy' for success."),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Icon(Icons.circle, size: 6, color: theme.colorScheme.secondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
