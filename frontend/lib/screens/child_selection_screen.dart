import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/auth_provider.dart';
import 'child_management_screen.dart'; // Reuse for adding child (Fixed path)
import 'game_hub_screen.dart';
import 'profile/report_screen.dart';

class ChildSelectionScreen extends StatefulWidget {
  final bool isForReport;

  const ChildSelectionScreen({super.key, this.isForReport = false});

  @override
  State<ChildSelectionScreen> createState() => _ChildSelectionScreenState();
}

class _ChildSelectionScreenState extends State<ChildSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch children on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ChildProvider>().fetchChildren(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Who is playing?"),
      ),
      body: Consumer<ChildProvider>(
        builder: (context, childProvider, child) {
          if (childProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (childProvider.error != null) {
            return Center(child: Text("Error: ${childProvider.error}"));
          }

          final children = childProvider.children;

          if (children.isEmpty) {
            // Should technically be redirected before this, but safe fallback
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text("No children added yet."),
                   ElevatedButton(
                     onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildManagementScreen()));
                     },
                     child: const Text("Add Child"),
                   )
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: children.length + 1, // +1 for "Add New Child" card
            itemBuilder: (context, index) {
              if (index == children.length) {
                return _buildAddChildCard(context);
              }

              final childData = children[index];
              return _buildChildCard(context, childData);
            },
          );
        },
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, dynamic childData) {
    return GestureDetector(
      onTap: () {
        if (widget.isForReport) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportScreen(
                childId: childData['id'],
                childName: childData['nickname'] ?? 'Child',
              ),
            ),
          );
        } else {
          // Navigate to Game Hub with selected child context
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameHubScreen(
                childId: childData['id'].toString(), // Adjust based on actual API response key
                childName: childData['nickname'] ?? 'Child',
                childAge: childData['age_in_months'] ?? 0,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.face, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              childData['nickname'] ?? "Unknown",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(
                  childId: childData['id'],
                  childName: childData['nickname'] ?? 'Child',
                )));
              },
              icon: const Icon(Icons.analytics, size: 16),
              label: const Text("Report"),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddChildCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildManagementScreen()))
             .then((_) {
               // Refresh list after returning from add screen
                final token = context.read<AuthProvider>().token;
                if (token != null) context.read<ChildProvider>().fetchChildren(token);
             });
      },
      child: Card(
        elevation: 2,
        color: Theme.of(context).cardColor.withOpacity(0.8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 1, style: BorderStyle.solid) // Dashed border ideal but complex
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(
              "Add Child",
              style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
