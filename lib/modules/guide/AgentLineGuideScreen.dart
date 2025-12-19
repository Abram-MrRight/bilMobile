import 'package:flutter/material.dart';

import '../../Models/company_info.dart';
import '../../services/api/api_constants.dart';
import '../../services/api/api_repository.dart';
import 'getMaterialIcon.dart';

class AgentLineGuideScreen extends StatefulWidget {
  const AgentLineGuideScreen({super.key});

  @override
  State<AgentLineGuideScreen> createState() => _AgentLineGuideScreenState();
}

class _AgentLineGuideScreenState extends State<AgentLineGuideScreen> {
  late Future<List<CompanyInfo>> companyInfoFuture;

  @override
  void initState() {
    super.initState();
    companyInfoFuture = ApiRepository().getCompanyInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Info'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<CompanyInfo>>(
        future: companyInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No company info available'));
          }

          final companyInfoList = snapshot.data!;
          final logoInfo = companyInfoList.firstWhere(
                  (info) => info.type == 'logo',
              orElse: () => companyInfoList.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logo
                if (logoInfo.logoImage != null)
                // Logo
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              logoInfo.fullLogoUrl, // ✅ Use fullLogoUrl getter
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/logo.jpg',
                                  height: 120,
                                  fit: BoxFit.contain,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            logoInfo.content,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Other sections
                ...companyInfoList
                    .where((info) => info.type != 'logo')
                    .map((info) => InfoCard(
                  icon: getMaterialIcon(info.icon),
                  title: info.title,
                  content: info.content,
                  color: getHexColor(info.color),
                ))
                    .toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
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
                  Text(title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 8),
                  Text(content,
                      style:
                      const TextStyle(fontSize: 15, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
