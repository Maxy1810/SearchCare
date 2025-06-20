import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class ViewDoctorsPage extends StatefulWidget {
  const ViewDoctorsPage({super.key});

  @override
  State<ViewDoctorsPage> createState() => _ViewDoctorsPageState();
}

class _ViewDoctorsPageState extends State<ViewDoctorsPage> {
  Future<void> _updateDoctorStatus(String doctorId, String status, String email) async {
    await FirebaseFirestore.instance.collection('doctors').doc(doctorId).update({
      'status': status,
    });

    _sendEmailNotification(email, status);
  }

  Future<void> _sendEmailNotification(String email, String status) async {
    String subject = 'Doctor Registration Status';
    String body = status == 'accepted'
        ? 'Congratulations! Your doctor registration has been accepted. You can now log in and access your dashboard.'
        : 'We regret to inform you that your doctor registration has been rejected.';

    final smtpServer = gmail('your.email@gmail.com', 'your_app_password');

    final message = Message()
      ..from = Address('your.email@gmail.com', 'SearchCare Admin')
      ..recipients.add(email)
      ..subject = subject
      ..text = body;

    try {
      await send(message, smtpServer);
    } catch (e) {
      print('Email send error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review New Doctors')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No pending doctor requests.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(data['fullName'] ?? 'Unknown'),
                  subtitle: Text('${data['workplace']}\n${data['expertise']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Accept',
                        onPressed: () => _updateDoctorStatus(doc.id, 'accepted', data['email']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Reject',
                        onPressed: () => _updateDoctorStatus(doc.id, 'rejected', data['email']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
