import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openWhatsApp(String phone, String message) async {
    final text = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$phone?text=$text");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Tidak dapat membuka WhatsApp');
    }
  }

  void _showWhatsAppChoice(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "Pengguna";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hubungi via WhatsApp"),
        content: const Text("Pilih kontak yang ingin kamu hubungi:"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsApp(
                "6282186291290",
                "Hai Veraldo, saya $username dari PT TAG Toyota Palembang ingin bertanya terkait Aplikasi Reminder Ulang Tahun Customer.",
              );
            },
            icon: const Icon(Icons.person, color: Colors.green),
            label: const Text("Veraldo"),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openWhatsApp(
                "628153900803",
                "Halo Siti Fatimah Az'Zahrah, saya $username dari PT TAG Toyota Palembang ingin bertanya terkait Aplikasi Reminder Ulang Tahun Customer.",
              );
            },
            icon: const Icon(Icons.person, color: Colors.green),
            label: const Text("Siti Fatimah"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Color.fromARGB(255, 255, 17, 0))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 51, 51, 51),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color.fromARGB(255, 255, 17, 0)),
              title: const Text(
                "Tentang Aplikasi",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'TAG Toyota',
                  applicationVersion: 'v1.0.0',
                  applicationIcon: const Icon(Icons.car_rental, size: 40),
                  children: const [
                    Text(
                      'Aplikasi ini dikembangkan oleh Mahasiswa Universitas Multi Data Palembang. Veraldo (2327250001) dan Siti Fatimah Az Zahrah (2327250055).',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text(
                "Butuh Bantuan?",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => _showWhatsAppChoice(context),
            ),
          ),
        ],
      ),
    );
  }
}
