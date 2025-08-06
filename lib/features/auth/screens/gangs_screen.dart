import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/core/utils/input_formatters.dart';
import 'package:smart_cluster_app/core/utils/usersesion.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/widgets/standard_button.dart';

class GangsScreen extends StatefulWidget {
  const GangsScreen({super.key});

  @override
  State<GangsScreen> createState() => _GangsPageState();
}

class _GangsPageState extends State<GangsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaGangController = TextEditingController();

  String? _residentialId;
  String? _selectedPerumahanName;
  String? _selectedRW;
  String? _selectedRT;

  List<Map<String, dynamic>> _perumahanList = [];
  List<String> _rwList = [];
  List<String> _rtList = [];
  List<String> _gangList = [];

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
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadRW() async {
    if (_residentialId == null) return;
    try {
      final response = await ApiService.get(
        'area-zones/rw?residential_id=$_residentialId',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _rwList = data.map<String>((e) => e['rw'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Error RW: $e');
    }
  }

  Future<void> _loadRT() async {
    if (_residentialId == null || _selectedRW == null) return;
    try {
      final response = await ApiService.get(
        'area-zones/rt?residential_id=$_residentialId&rw=$_selectedRW',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _rtList = data.map<String>((e) => e['rt'].toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Error RT: $e');
    }
  }

  Future<void> _loadGangs() async {
    if (_residentialId == null || _selectedRW == null || _selectedRT == null) {
      return;
    }
    try {
      final response = await ApiService.get(
        'gangs?residential_id=$_residentialId&rw=$_selectedRW&rt=$_selectedRT',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _gangList = data
              .map<String>((e) => e['nama_gang'].toString())
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error load gangs: $e');
    }
  }

  String _generateKodeGang(String nama) {
    final prefix = nama.split(' ').map((e) => e[0]).join().toUpperCase();
    final randomDigits = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000))
        .toString();
    return '$prefix$randomDigits';
  }

  Future<void> _submit() async {
    final kodeGang = _generateKodeGang(_selectedPerumahanName!);
    final body = {
      'kode_gang': kodeGang,
      'residential_id': _residentialId,
      'rw': _selectedRW,
      'rt': _selectedRT,
      'nama_gang': _namaGangController.text.trim(),
      'add_user': UserSession().email,
    };

    try {
      final response = await ApiService.post('gangs', body);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await showSuccessDialog(context, 'Data gang berhasil disimpan');
        _namaGangController.clear();
        _loadGangs();
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Gagal menyimpan';
        await showErrorDialog(context, msg);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Error: $e');
    }
  }

  @override
  void dispose() {
    _namaGangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Nama Gang'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _residentialId,
                decoration: inputDecoration.copyWith(
                  labelText: 'Pilih Perumahan',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                items: _perumahanList
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['id'],
                        child: Text(item['nama_perumahan']),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _residentialId = val;
                    _selectedPerumahanName = _perumahanList.firstWhere(
                      (e) => e['id'] == val,
                    )['nama_perumahan'];
                    _selectedRW = null;
                    _selectedRT = null;
                    _rtList.clear();
                    _gangList.clear();
                  });
                  _loadRW();
                },
                validator: (val) =>
                    val == null ? 'Wajib pilih perumahan' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRW,
                decoration: inputDecoration.copyWith(
                  labelText: 'Pilih RW',
                  prefixIcon: const Icon(Icons.groups_outlined),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                items: _rwList
                    .map(
                      (rw) => DropdownMenuItem<String>(
                        value: rw,
                        child: Text('RW $rw'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRW = val;
                    _selectedRT = null;
                    _gangList.clear();
                  });
                  _loadRT();
                },
                validator: (val) => val == null ? 'Wajib pilih RW' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRT,
                decoration: inputDecoration.copyWith(
                  labelText: 'Pilih RT',
                  prefixIcon: const Icon(Icons.group_add_outlined),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                items: _rtList
                    .map(
                      (rt) => DropdownMenuItem<String>(
                        value: rt,
                        child: Text('RT $rt'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRT = val;
                  });
                  _loadGangs();
                },
                validator: (val) => val == null ? 'Wajib pilih RT' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _namaGangController,
                maxLength: 50,
                decoration: inputDecoration.copyWith(
                  labelText: 'Nama Gang',
                  prefixIcon: const Icon(Icons.label_outline),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Nama gang tidak boleh kosong'
                    : null,
                inputFormatters: getUpperCaseFormatter(),
              ),
              const SizedBox(height: 32),
              const Text(
                "Daftar Gang yang sudah ada:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 12),
              if (_gangList.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "Belum ada data gang.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ..._gangList.map(
                (nama) => Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  shadowColor: Colors.blueAccent.shade100,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.shade100,
                      child: const Icon(
                        Icons.label_important,
                        color: Colors.blueAccent,
                      ),
                    ),
                    title: Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StandardButton(
            label: 'Simpan',
            icon: Icons.save,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _submit();
              }
            },
          ),
        ),
      ),
    );
  }
}
