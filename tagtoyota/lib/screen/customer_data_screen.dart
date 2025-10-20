import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerDataScreen extends StatefulWidget {
  const CustomerDataScreen({super.key});

  @override
  State<CustomerDataScreen> createState() => _CustomerDataScreenState();
}

class _CustomerDataScreenState extends State<CustomerDataScreen> {
  List<Map<String, dynamic>> _excelData = [];
  final DateFormat _excelDateFormat = DateFormat('dd-MM-yyyy');
  bool _isLoading = false;

  // Fungsi parse date tetap sama
  String parseExcelDate(dynamic value) {
    if (value == null) return '';

    if (value is num) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        ((value - 25569) * 86400000).toInt(),
        isUtc: true,
      );
      return _excelDateFormat.format(date);
    }

    if (value is String) {
      try {
        final parsed = DateFormat('M/d/yyyy').parse(value);
        return _excelDateFormat.format(parsed);
      } catch (_) {
        try {
          final parsed = DateFormat('dd/MM/yyyy').parse(value);
          return _excelDateFormat.format(parsed);
        } catch (_) {
          return value;
        }
      }
    }

    return value.toString();
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final path = result.files.single.path!;

        final tempData = await compute(_parseExcelInBackground, {
          'path': path,
          'dateFormat': _excelDateFormat.pattern,
        });

        setState(() {
          _excelData = List<Map<String, dynamic>>.from(tempData);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat file Excel: $e')),
      );
    }
  }

  Future<void> _uploadToFirebase() async {
    if (_excelData.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var data in _excelData) {
        final docRef = firestore.collection('customers').doc();
        batch.set(docRef, data);
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Data berhasil diunggah ke Firebase!')),
      );

      setState(() {
        _excelData.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Isi Data Customer"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickExcelFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Pilih File Excel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 17, 0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _excelData.isEmpty
                        ? const Center(
                            child: Text(
                                "Belum ada data. Pilih file Excel terlebih dahulu."),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    border: TableBorder.all(
                                        color: Colors.grey.shade300),
                                    columns: const [
                                      DataColumn(label: Text('No Rangka')),
                                      DataColumn(label: Text('Customer Name')),
                                      DataColumn(label: Text('Tanggal Lahir')),
                                      DataColumn(label: Text('Model')),
                                      DataColumn(
                                          label: Text('Tanggal SPK/DO')),
                                      DataColumn(label: Text('No HP')),
                                    ],
                                    rows: _excelData
                                        .map(
                                          (data) => DataRow(
                                            cells: [
                                              DataCell(Text(
                                                  data['No_Rangka'] ?? '')),
                                              DataCell(Text(
                                                  data['Customer_Name'] ?? '')),
                                              DataCell(Text(
                                                  data['Tanggal_Lahir'] ?? '')),
                                              DataCell(Text(
                                                  data['Model'] ?? '')),
                                              DataCell(Text(
                                                  data['Tanggal_Spk_Do'] ?? '')),
                                              DataCell(
                                                  Text(data['No_HP'] ?? '')),
                                            ],
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _uploadToFirebase,
                                icon: const Icon(Icons.cloud_upload),
                                label:
                                    const Text("Upload ke Firebase"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
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


List<Map<String, dynamic>> _parseExcelInBackground(Map args) {
  final file = File(args['path']);
  final bytes = file.readAsBytesSync();
  final excel = Excel.decodeBytes(bytes);
  final dateFormat = DateFormat(args['dateFormat']);

  String parse(dynamic value) {
    if (value == null) return '';

    if (value is num) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        ((value - 25569) * 86400000).toInt(),
        isUtc: true,
      );
      return dateFormat.format(date);
    }

    if (value is String) return value;

    return value.toString();
  }

  List<Map<String, dynamic>> tempData = [];

  for (var table in excel.tables.keys) {
    var sheet = excel.tables[table]!;

    for (var i = 1; i < sheet.rows.length; i++) {
      var row = sheet.rows[i];
      tempData.add({
        'No_Rangka': row[0]?.value?.toString() ?? '',
        'Customer_Name': row[1]?.value?.toString() ?? '',
        'Tanggal_Lahir': parse(row[2]?.value),
        'Model': row[3]?.value?.toString() ?? '',
        'Tanggal_Spk_Do': parse(row[4]?.value),
        'No_HP': row[5]?.value?.toString() ?? '',
      });
    }
  }

  return tempData;
}
