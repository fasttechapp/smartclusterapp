import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_cluster_app/core/utils/input_formatters.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/logger.dart';
import '../../../widgets/standard_button.dart';
import '../../../widgets/showokdialog.dart';
import 'package:smart_cluster_app/core/utils/usersesion.dart';

class MasterIuranScreen extends StatefulWidget {
  const MasterIuranScreen({super.key});

  @override
  State<MasterIuranScreen> createState() => _MasterIuranScreenState();
}

class _MasterIuranScreenState extends State<MasterIuranScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _residentialId;
  String _jenisIuran = '';
  String _nominal = '';
  final TextEditingController _nominalController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedRW;
  int? _selectedRT;

  List<Map<String, dynamic>> _iuranList = [];
  List<Map<String, dynamic>> _perumahanList = [];
  List<int> _rwOptions = [];
  List<int> _rtOptions = [];

  @override
  void initState() {
    super.initState();
    _loadPerumahan();
  }

  Future<void> _loadPerumahan() async {
    try {
      final response = await ApiService.get('residential-areas');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _perumahanList = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading perumahan: $e');
    }
  }

  void _loadRWOptions() async {
    if (_residentialId == null) return;
    log.info('Memuat RW untuk residential_id=$_residentialId');
    final response = await ApiService.get(
      'area-zones/rw?residential_id=$_residentialId',
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _rwOptions = data.map<int>((e) => e['rw'] as int).toList();
        _selectedRW = null;
        _selectedRT = null;
        _rtOptions = [];
      });
    }
  }

  void _loadRTOptions() async {
    if (_residentialId == null || _selectedRW == null) return;
    log.info(
      'Memuat RT untuk residential_id=$_residentialId dan RW=$_selectedRW',
    );
    final response = await ApiService.get(
      'area-zones/rt?residential_id=$_residentialId&rw=$_selectedRW',
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _rtOptions = data.map<int>((e) => e['rt'] as int).toList();
        _selectedRT = null;
      });
    }
  }

  Future<void> _loadIuranList() async {
    if (_residentialId == null || _selectedRW == null || _selectedRT == null) {
      setState(() {
        _iuranList = [];
      });
      return;
    }
    log.info(
      'Memuat data untuk residential_id=$_residentialId dan RW=$_selectedRW dan RT=$_selectedRT',
    );
    final response = await ApiService.get(
      'master-iuran?residential_id=$_residentialId&rw=$_selectedRW&rt=$_selectedRT',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List data = List.from(jsonDecode(response.body));
      setState(() {
        _iuranList = data
            .map(
              (e) => {
                'id': e['id'], // <-- Tambahkan ini
                'jenis_iuran': e['jenis_iuran'],
                'nominal': e['nominal'],
                'periode': '${e['start_date']} s.d. ${e['end_date']}',
              },
            )
            .toList();
      });
    }
  }

  Future<void> _deleteIuran(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.delete('/master-iuran/$id');
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        if (!mounted) return;
        await showSuccessDialog(context, 'Data berhasil dihapus');
        _loadIuranList(); // Refresh list
      } else {
        if (!mounted) return;
        await showErrorDialog(context, 'Gagal menghapus: ${result['message']}');
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text('Terjadi kesalahan saat menghapus data'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _submit() async {
    final dateFormat = DateFormat('yyyy-MM-dd');

    final data = {
      'residential_id': _residentialId,
      'rw': _selectedRW,
      'rt': _selectedRT,
      'jenis_iuran': _jenisIuran,
      'nominal': _nominal,
      'start_date': dateFormat.format(_startDate!),
      'end_date': dateFormat.format(_endDate!),
      'addby': UserSession().email,
    };

    final response = await ApiService.post('/master-iuran', data);
    final res = jsonDecode(response.body);
    if (!mounted) return;
    if (response.statusCode == 201) {
      showSuccessDialog(context, res['message'] ?? "Data berhasil disimpan.");
      _loadIuranList();
      _jenisIuran = "";
      _nominal = "";
    } else if (response.statusCode == 409) {
      showErrorDialog(
        context,
        res['message'] ?? "Data sudah ada dengan periode yang aktif.",
      );
    } else {
      showErrorDialog(context, res['message'] ?? "Gagal menyimpan data.");
    }
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");
    log.info('hasil simpan =$data');
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 2,
        title: const Text('Master Iuran'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _residentialId,
                            decoration: InputDecoration(
                              // ← jangan pakai const
                              labelText: 'Pilih Perumahan',
                              filled: true,
                              fillColor:
                                  Colors.blue.shade50, // ← ini ditambahkan
                              prefixIcon: const Icon(Icons.home_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            items: _perumahanList
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item['id'].toString(),
                                    child: Text(item['nama_perumahan']),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                log.info(
                                  'Dropdown changed: $val',
                                ); // Langsung dari val
                                _residentialId = val;
                                _selectedRT = null;
                                _iuranList = [];
                              });
                              _loadRWOptions();
                            },
                            validator: (val) =>
                                val == null ? 'Wajib pilih perumahan' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedRW,
                            decoration: InputDecoration(
                              labelText: "Pilih RW",
                              prefixIcon: const Icon(Icons.people_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            items: _rwOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('RW $e'),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedRW = val;
                                _loadRTOptions();
                                // _houses.clear();
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Dropdown RT dengan icon
                          DropdownButtonFormField<int>(
                            value: _selectedRT,
                            decoration: InputDecoration(
                              labelText: "Pilih RT",
                              prefixIcon: const Icon(Icons.group_add_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            items: _rtOptions
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text('RT $e'),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedRT = val;
                                _loadIuranList();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 16),
                          TextFormField(
                            inputFormatters: getUpperCaseFormatter(),
                            decoration: InputDecoration(
                              labelText: 'Jenis Iuran',
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              prefixIcon: const Icon(Icons.category),
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (val) => _jenisIuran = val,
                            validator: (val) => val == null || val.isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nominalController,
                            decoration: InputDecoration(
                              labelText: 'Nominal',
                              filled: true,
                              fillColor: Colors.blue.shade50,
                              prefixIcon: const Icon(Icons.monetization_on),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              // Ambil angka saja (hilangkan karakter bukan digit)
                              String unformatted = val.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );

                              if (unformatted.isEmpty) {
                                _nominalController.clear();
                                _nominal = '';
                                return;
                              }

                              // Format dengan fungsi formatRupiah kamu
                              final formatted = formatRupiah(unformatted);

                              // Set ulang controller dengan teks terformat
                              _nominalController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );

                              // Simpan nominal asli tanpa format
                              _nominal = unformatted;
                            },
                            validator: (val) => val == null || val.isEmpty
                                ? 'Wajib diisi'
                                : null,
                          ),

                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickDate(isStart: true),
                                icon: const Icon(Icons.date_range),
                                label: Text(
                                  _startDate == null
                                      ? 'Pilih Tanggal Mulai'
                                      : 'Mulai: ${DateFormat('yyyy-MM-dd').format(_startDate!)}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _pickDate(isStart: false),
                                icon: const Icon(Icons.event_available),
                                label: Text(
                                  _endDate == null
                                      ? 'Pilih Tanggal Selesai'
                                      : 'Selesai: ${DateFormat('yyyy-MM-dd').format(_endDate!)}',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Daftar Iuran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_iuranList.isEmpty)
                    const Center(child: Text('Belum ada data')),
                  ..._iuranList.map(
                    (e) => Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment
                              .center, // ini diubah dari start ke center
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              color: Colors.blue,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['jenis_iuran'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Nominal: Rp ${formatRupiah(e['nominal'].toString())}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Berlaku: ${e['periode']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                // Ganti ini dengan fungsi hapus yang kamu punya
                                _deleteIuran(e['id'].toString());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: StandardButton(
                  label: 'Simpan',
                  icon: Icons.save_alt,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) _submit();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
