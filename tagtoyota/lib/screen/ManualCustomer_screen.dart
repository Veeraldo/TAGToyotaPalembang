import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManualCustomerScreen extends StatefulWidget {
  const ManualCustomerScreen({super.key});

  @override
  State<ManualCustomerScreen> createState() => _ManualCustomerScreenState();
}

class _ManualCustomerScreenState extends State<ManualCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller untuk masing-masing field
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();
  final _modelController = TextEditingController();
  final _spkController = TextEditingController();
  final _noRangkaController = TextEditingController();
  final _phoneController = TextEditingController();

  /// Fungsi untuk memilih tanggal dengan DatePicker
  Future<void> _pickDate(TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(controller.text);
      } catch (_) {}
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('id', 'ID'),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  /// Fungsi untuk menyimpan data customer ke Firestore
  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance.collection('customers').doc().set({
        'Customer_Name': _nameController.text.trim(),
        'Tanggal_Lahir': _birthController.text.trim(),
        'Model': _modelController.text.trim(),
        'Tanggal_Spk_Do': _spkController.text.trim(),
        'No_Rangka': _noRangkaController.text.trim(),
        'No_HP': _phoneController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer berhasil ditambahkan!')),
      );

      _formKey.currentState!.reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Customer Manual"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Customer'),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 10),

                // Tanggal Lahir
                TextFormField(
                  controller: _birthController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(_birthController),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 10),

                // Model
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: 'Model'),
                ),
                const SizedBox(height: 10),

                // Tanggal SPK/DO
                TextFormField(
                  controller: _spkController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal SPK/DO',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _pickDate(_spkController),
                ),
                const SizedBox(height: 10),

                // No Rangka
                TextFormField(
                  controller: _noRangkaController,
                  decoration: const InputDecoration(labelText: 'No Rangka'),
                ),
                const SizedBox(height: 10),

                // No HP
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'No HP (Contoh: 62812345678)',
                  ),
                ),
                const SizedBox(height: 20),

                // Tombol Simpan
                ElevatedButton.icon(
                  onPressed: _saveCustomer,
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
