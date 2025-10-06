import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tagtoyota/screen/signin_screen.dart';
import 'setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  String? _photoBase64;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        _photoBase64 = doc.data()?['photoBase64'];
      });
    } catch (e) {
      debugPrint("❌ Gagal memuat foto profil: $e");
    }
  }

  /// 🔹 Pilih & simpan gambar sebagai Base64 ke Firestore
  Future<void> _pickAndSaveImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null || user == null) return;

      final file = File(pickedFile.path);
      setState(() => _imageFile = file);

      // Konversi gambar ke Base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Simpan ke Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'photoBase64': base64Image}, SetOptions(merge: true));

      setState(() {
        _photoBase64 = base64Image;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui!',selectionColor: Colors.green,)),
      );
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui foto: $e')),
      );
    }
  }


      Future<void> _logout() async {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SignInScreen()),
        );
      }


  @override
  Widget build(BuildContext context) {
    final username = user?.displayName ?? "Nama Pengguna";
    final email = user?.email ?? "email@domain.com";

    ImageProvider<Object> profileImage;
    if (_imageFile != null) {
      profileImage = FileImage(_imageFile!);
    } else if (_photoBase64 != null) {
      profileImage = MemoryImage(base64Decode(_photoBase64!));
    } else {
      profileImage = const NetworkImage(
        "https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png",
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _pickAndSaveImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profileImage,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            _buildMenuItem(Icons.settings, "Pengaturan", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }),
            _buildMenuItem(Icons.people, "Isi Data Customer", () {}),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}
