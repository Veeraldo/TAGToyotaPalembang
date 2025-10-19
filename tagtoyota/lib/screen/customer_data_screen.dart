import 'dart:io';
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
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  /// Fungsi konversi angka Excel menjadi DateTime
  DateTime? excelDateToDateTime(dynamic value) {
    const gsDateBase = 2209161600 / 86400;
    const gsDateFactor = 86400000;

    if (value == null) return null;

    double? dateNumber;
    if (value is double) {
      dateNumber = value;
    } else if (value is String) {
      dateNumber = double.tryParse(value);
    }

    if (dateNumber == null) return null;

    final millis = (dateNumber - gsDateBase) * gsDateFactor;
    return DateTime.fromMillisecondsSinceEpoch(millis.toInt(), isUtc: true);
  }

  Future<void> _pickExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);

        List<Map<String, dynamic>> tempData = [];

        for (var table in excel.tables.keys) {
          for (var i = 1; i < excel.tables[table]!.rows.length; i++) {
            var row = excel.tables[table]!.rows[i];

            final birthDate = excelDateToDateTime(row[2]?.value);
            final spkDate = excelDateToDateTime(row[4]?.value);

            tempData.add({
              'No_Rangka': row[0]?.value ?? '',
              'Customer_Name': row[1]?.value ?? '',
              'Tanggal_Lahir': birthDate,
              'Model': row[3]?.value ?? '',
              'Tanggal_Spk_Do': spkDate,
              'No_HP': row[5]?.value ?? '',
            });
          }
        }

        setState(() {
          _excelData = tempData;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat file Excel: $e')),
      );
    }
  }

  Future<void> _uploadToFirebase() async {
    if (_excelData.isEmpty) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (var data in _excelData) {
        final docRef = firestore.collection('customers').doc();
        batch.set(docRef, {
          'No_Rangka': data['No_Rangka'],
          'Customer_Name': data['Customer_Name'],
          'Tanggal_Lahir': data['Tanggal_Lahir'] != null
              ? Timestamp.fromDate(data['Tanggal_Lahir'])
              : null,
          'Model': data['Model'],
          'Tanggal_Spk_Do': data['Tanggal_Spk_Do'] != null
              ? Timestamp.fromDate(data['Tanggal_Spk_Do'])
              : null,
          'No_HP': data['No_HP'],
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Data berhasil diunggah ke Firebase!')),
      );

      setState(() {
        _excelData.clear();
      });
    } catch (e) {
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
                      child:
                          Text("Belum ada data. Pilih file Excel terlebih dahulu."),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              border:
                                  TableBorder.all(color: Colors.grey.shade300),
                              columns: const [
                                DataColumn(label: Text('No Rangka')),
                                DataColumn(label: Text('Customer Name')),
                                DataColumn(label: Text('Tanggal Lahir')),
                                DataColumn(label: Text('Model')),
                                DataColumn(label: Text('Tanggal SPK/DO')),
                                DataColumn(label: Text('No HP')),
                              ],
                              rows: _excelData
                                  .map(
                                    (data) => DataRow(
                                      cells: [
                                        DataCell(
                                            Text(data['No_Rangka'].toString())),
                                        DataCell(Text(
                                            data['Customer_Name'].toString())),
                                        DataCell(Text(data['Tanggal_Lahir'] != null
                                            ? _dateFormat
                                                .format(data['Tanggal_Lahir'])
                                            : '')),
                                        DataCell(Text(data['Model'].toString())),
                                        DataCell(Text(data['Tanggal_Spk_Do'] != null
                                            ? _dateFormat
                                                .format(data['Tanggal_Spk_Do'])
                                            : '')),
                                        DataCell(Text(data['No_HP'].toString())),
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
                          label: const Text("Upload ke Firebase"),
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
