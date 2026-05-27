import 'package:flutter/material.dart';
import 'AgentLineGuideScreen.dart';
import 'SendMoneyScreen.dart';
import 'TransactionsScreen.dart';
import 'UploadProofGuideScreen.dart';
import '../../services/storage/storage_service.dart';

class GuideScreen extends StatefulWidget {
  GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String userRole = 'client';

  final List<Map<String, dynamic>> guides = [
    {
      'title': 'Upload Proof',
      'image': 'assets/images/uploadProof.png',
      'screen': UploadProofGuideScreen(),
    },
    {
      'title': 'Contact Info',
      'image': 'assets/images/agentLine.png',
      'screen': AgentLineGuideScreen(),
    },
    {
      'title': 'Transactions',
      'image': 'assets/images/sendMoney.png',
      'screen': TransactionsScreen(),
      'role': 'client',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await StorageService.getUserDetails();
    if (user != null && mounted) {
      setState(() {
        userRole = user['role']?.toString() ?? 'client';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Guide"),
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: guides.where((guide) {
            // Only show card if 'role' is not set or matches the userRole
            // if (guide.containsKey('role')) {
            //   return guide['role'] == userRole;
            // }
            return true; // show cards with no 'role' key for everyone
          }).map((guide) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              child: GuideCard(
                title: guide['title'] ?? 'No Title',
                imagePath: guide['image'] ?? 'assets/images/logo.jpg',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => guide['screen'],
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class GuideCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const GuideCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.1 : 0.25),
              blurRadius: _pressed ? 4 : 12,
              offset: Offset(0, _pressed ? 2 : 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              widget.imagePath,
              height: 80,
              width: 80,
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
