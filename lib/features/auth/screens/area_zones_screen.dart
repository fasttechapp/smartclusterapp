import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/core/utils/usersesion.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/widgets/standard_button.dart';

class AreaZoneScreen extends StatefulWidget {
  const AreaZoneScreen({super.key});

  @override
  State<AreaZoneScreen> createState() => _AreaZonesPageState();
}

class _AreaZonesPageState extends State<AreaZoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _perumahanController = TextEditingController();
  final TextEditingController _rwController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();

  String? _selectedResidentialId;
  List<Map<String, dynamic>> _existingZones = [];

  Future<List<Map<String, dynamic>>> _getResidentialSuggestions(
    String pattern,
  ) async {
    try {
      final response = await ApiService.get('residential-areas?q=$pattern');
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Error fetching residential: $e");
    }
    return [];
  }

  Future<void> _loadAreaZones(String residentialId) async {
    try {
      final response = await ApiService.get(
        'area-zones?residential_id=$residentialId',
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _existingZones = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint("Error fetching area zones: $e");
    }
  }

  Future<void> _submit() async {
    final body = {
      'residential_id': _selectedResidentialId,
      'rw': _rwController.text,
      'rt': _rtController.text,
      'add_user': UserSession().email,
    };

    try {
      final response = await ApiService.post('/area-zones', body);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        await showSuccessDialog(context, 'Data RW/RT berhasil disimpan');
        _rwController.clear();
        _rtController.clear();
        _loadAreaZones(_selectedResidentialId!);
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
    _perumahanController.dispose();
    _rwController.dispose();
    _rtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah RW/RT'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TypeAheadFormField<Map<String, dynamic>>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _perumahanController,
                  decoration: InputDecoration(
                    labelText: 'Pilih Perumahan',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
                suggestionsCallback: _getResidentialSuggestions,
                itemBuilder: (context, suggestion) =>
                    ListTile(title: Text(suggestion['nama_perumahan'])),
                onSuggestionSelected: (suggestion) {
                  _perumahanController.text = suggestion['nama_perumahan'];
                  _selectedResidentialId = suggestion['id'];
                  _loadAreaZones(_selectedResidentialId!);
                },
                validator: (value) =>
                    value!.isEmpty ? 'Pilih perumahan dulu' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rwController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'RW',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'RW tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'RT',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'RT tidak boleh kosong' : null,
              ),
              const SizedBox(height: 32),
              const Text(
                "Daftar RW/RT yang sudah terdaftar:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._existingZones.map(
                (zone) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.map),
                    title: Text('RW ${zone['rw']} - RT ${zone['rt']}'),
                  ),
                ),
              ),
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
