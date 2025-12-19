import 'package:flutter/material.dart';

import '../../Models/ProofStepGuide.dart';
import '../../services/api/api_repository.dart';

class UploadProofGuideScreen extends StatelessWidget {
   UploadProofGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = ApiRepository();

    return Scaffold(
      appBar: AppBar(
        title:  Text("Upload Proof Guide"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<ProofStep>>(
        future: repo.getUploadProofSteps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No proof steps available'));
          }

          final steps = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return StepCard(
                title: step.title,
                description: step.description,
                icon: _getIconFromString(step.icon),
                color: _hexToColor(step.color),
                stepNumber: step.stepNumber,
              );
            },
          );
        },
      ),
    );
  }

  // Convert string from backend to IconData
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'info_outline':
        return Icons.info_outline;
      case 'check_circle':
        return Icons.check_circle;
      case 'attach_file':
        return Icons.attach_file;
      case 'image':
        return Icons.image;
      case 'chat':
        return Icons.chat;
      case 'send':
        return Icons.send;
      default:
        return Icons.help_outline;
    }
  }

  // Convert hex color string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // add alpha if missing
    return Color(int.parse(hex, radix: 16));
  }
}

class StepCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int stepNumber;

  const StepCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step $stepNumber: $title",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
