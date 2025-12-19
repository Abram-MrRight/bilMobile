import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Models/agent.dart';
import '../../services/api/api_repository.dart';


class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  late Future<List<Agent>> _agentsFuture;

  @override
  void initState() {
    super.initState();
    _agentsFuture = ApiRepository().getAgents(); // implement getAgents()
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot place call')));
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open email client')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Money Info"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.green],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Agent>>(
        future: _agentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No agents found'));
          }

          final agents = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF64FFDA), Color(0xFF00C1B3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          "Send money safely and securely!\nUse the contacts below to transfer funds directly.",
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                      Icon(Icons.send, color: Colors.white, size: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ...agents.map((agent) {
                  final imageUrl = agent.fullLogoUrl;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade100,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: imageUrl.contains('assets/')
                                    ? Image.asset(imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                                    : Image.network(
                                  imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, st) => Image.asset('assets/images/logo.jpg', width: 56, height: 56, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(agent.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (agent.accountName != null) Text('Account Name: ${agent.accountName}', style: const TextStyle(fontSize: 14)),
                                  if (agent.phone != null) Text('Phone: ${agent.phone}', style: const TextStyle(fontSize: 14)),
                                  if (agent.email != null) Text('Email: ${agent.email}', style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.green),
                                  onPressed: () {
                                    _copyToClipboard(agent.accountName ?? agent.phone ?? '', 'Account');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.blue),
                                  onPressed: () {
                                    if (agent.phone != null) _callNumber(agent.phone!);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.email, color: Colors.orange),
                                  onPressed: () {
                                    if (agent.email != null) _sendEmail(agent.email!);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
