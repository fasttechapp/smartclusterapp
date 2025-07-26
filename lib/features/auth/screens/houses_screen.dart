import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/core/utils/input_formatters.dart';
import 'package:smart_cluster_app/core/utils/logger.dart' show log;
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/widgets/standard_button.dart';

class HousesScreen extends StatefulWidget {
  const HousesScreen({super.key});

  @override
  State<HousesScreen> createState() => _HousesScreenState();
}

class _HousesScreenState extends State<HousesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noRumahController = TextEditingController();
  final _pemilikController = TextEditingController();
  final _penghuniController = TextEditingController();

  String? _residentialId;
  int? _selectedRW;
  int? _selectedRT;
  String? _selectedKodeGang;
  List<Map<String, dynamic>> _gangList = [];
  // List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _perumahanList = [];
  List<int> _rwOptions = [];
  List<int> _rtOptions = [];

  @override
  void initState() {
    super.initState();
    _loadPerumahan();
  }

  @override
  void dispose() {
    _noRumahController.dispose();
    _pemilikController.dispose();
    _penghuniController.dispose();
    super.dispose();
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
        _selectedKodeGang = null;
        _rtOptions = [];
        _gangList = [];
      });
    }
  }

  void _loadRTOptions() async {
    if (_residentialId == null || _selectedRW == null) return;
    final response = await ApiService.get(
      'area-zones/rt?residential_id=$_residentialId&rw=$_selectedRW',
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _rtOptions = data.map<int>((e) => e['rt'] as int).toList();
        _selectedRT = null;
        _selectedKodeGang = null;
        _gangList = [];
      });
    }
  }

  void _loadGangOptions() async {
    if (_residentialId == null || _selectedRW == null || _selectedRT == null) {
      return;
    }
    final response = await ApiService.get(
      'gangs?residential_id=$_residentialId&rw=$_selectedRW&rt=$_selectedRT',
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _gangList = List<Map<String, dynamic>>.from(data);
      });
    }
  }

  // void _loadHouses() async {
  //   if (_residentialId == null || _selectedKodeGang == null) return;
  //   final response = await ApiService.get(
  //     'houses?residential_id=$_residentialId&kode_gang=$_selectedKodeGang',
  //   );
  //   if (response.statusCode == 200) {
  //     final List data = jsonDecode(response.body);
  //     setState(() {
  //       _houses = data.cast<Map<String, dynamic>>();
  //     });
  //   }
  // }

  void _submit() async {
    final noRumah = _noRumahController.text.trim().toUpperCase();
    final pemilik = _pemilikController.text.trim();
    final penghuni = _penghuniController.text.trim();

    if (_residentialId == null || _selectedKodeGang == null) return;

    final body = {
      'residential_id': _residentialId,
      'kode_gang': _selectedKodeGang,
      'no_rumah': noRumah,
      'pemilik': pemilik,
      'penghuni': penghuni,
      'add_user': 'admin', // ubah sesuai login user
    };

    final response = await ApiService.post('houses', body);
    final res = jsonDecode(response.body);
    if (!mounted) return;
    if (response.statusCode == 200 || response.statusCode == 201) {
      showSuccessDialog(
        context,
        res['message'] ?? "Data rumah berhasil disimpan.",
      );
      // _loadHouses();
      _noRumahController.clear();
      _pemilikController.clear();
      _penghuniController.clear();
    } else {
      showErrorDialog(context, res['message'] ?? "Gagal menyimpan data rumah.");
    }
    debugPrint("Status Code: ${response.statusCode}");
    debugPrint("Response Body: ${response.body}");
    log.info('hasil simpan =$body');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Rumah'),
        elevation: 2,
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
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
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Dropdown Perumahan dengan icon
              DropdownButtonFormField<String>(
                value: _residentialId,
                decoration: InputDecoration(
                  labelText: "Pilih Perumahan",
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
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
                  log.info('Dropdown changed: $val'); // Langsung dari val
                  setState(() {
                    _residentialId = val;
                    _loadRWOptions();
                    // _houses.clear();
                  });
                },
                validator: (val) =>
                    val == null ? 'Wajib pilih perumahan' : null,
              ),
              const SizedBox(height: 16),

              // Dropdown RW dengan icon
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
                      (e) => DropdownMenuItem(value: e, child: Text('RW $e')),
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
                      (e) => DropdownMenuItem(value: e, child: Text('RT $e')),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRT = val;
                    _loadGangOptions();
                    // _houses.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Dropdown Kode Gang dengan icon
              DropdownButtonFormField<String>(
                value: _selectedKodeGang,
                decoration: InputDecoration(
                  labelText: "Pilih Gang",
                  prefixIcon: const Icon(Icons.pin_drop_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                items: _gangList.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['kode_gang'], // value yang disimpan (String)
                    child: Text(item['nama_gang']), // yang ditampilkan
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedKodeGang = val;
                  });
                },
                validator: (val) => val == null ? 'Wajib pilih gang' : null,
              ),

              const SizedBox(height: 16),

              // TextFormField Nomor Rumah dengan icon
              TextFormField(
                inputFormatters: getUpperCaseFormatter(),
                controller: _noRumahController,
                decoration: InputDecoration(
                  labelText: "Nomor Rumah",
                  prefixIcon: const Icon(Icons.home_work_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  counterText: "",
                ),
                maxLength: 5,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // TextFormField Pemilik dengan icon
              TextFormField(
                inputFormatters: getUpperCaseFormatter(),
                controller: _pemilikController,
                decoration: InputDecoration(
                  labelText: "Pemilik",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  counterText: "",
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),

              // TextFormField Penghuni dengan icon
              TextFormField(
                inputFormatters: getUpperCaseFormatter(),
                controller: _penghuniController,
                decoration: InputDecoration(
                  labelText: "Penghuni",
                  prefixIcon: const Icon(Icons.people_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  counterText: "",
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 24),

              // const Text(
              //   "Daftar Rumah:",
              //   style: TextStyle(
              //     fontWeight: FontWeight.bold,
              //     fontSize: 18,
              //     color: Colors.teal,
              //   ),
              // ),
              // const Divider(thickness: 2, color: Colors.teal),

              // if (_houses.isEmpty)
              //   Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 24),
              //     child: Center(
              //       child: Text(
              //         "Belum ada data rumah.",
              //         style: TextStyle(color: Colors.grey.shade600),
              //       ),
              //     ),
              //   ),

              // ..._houses.map(
              //   (e) => Card(
              //     elevation: 3,
              //     shadowColor: Colors.teal.shade200,
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     margin: const EdgeInsets.symmetric(vertical: 6),
              //     child: ListTile(
              //       leading: CircleAvatar(
              //         backgroundColor: Colors.teal.shade100,
              //         child: const Icon(Icons.house, color: Colors.teal),
              //       ),
              //       title: Text(
              //         "Rumah ${e['no_rumah']}",
              //         style: const TextStyle(fontWeight: FontWeight.bold),
              //       ),
              //       subtitle: Text(
              //         "Pemilik: ${e['pemilik']}  |  Penghuni: ${e['penghuni']}",
              //         style: TextStyle(color: Colors.grey.shade700),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
