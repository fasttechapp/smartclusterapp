import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/core/utils/input_formatters.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/widgets/standard_button.dart';

class ResidentialAreaForm extends StatefulWidget {
  const ResidentialAreaForm({super.key});

  @override
  State<ResidentialAreaForm> createState() => _ResidentialAreaFormState();
}

class _ResidentialAreaFormState extends State<ResidentialAreaForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaPerumahanController =
      TextEditingController();
  final TextEditingController _desaController = TextEditingController();
  final TextEditingController _kecamatanController = TextEditingController();
  final TextEditingController _kabupatenController = TextEditingController();
  final TextEditingController _provinsiController = TextEditingController();

  String? _selectedProvinceCode;
  String? _selectedCityCode;
  String? _selectedDistrictCode;

  @override
  void dispose() {
    _namaPerumahanController.dispose();
    _desaController.dispose();
    _kecamatanController.dispose();
    _kabupatenController.dispose();
    _provinsiController.dispose();
    super.dispose();
  }

  Future<void> submitResidentialArea() async {
    final body = {
      'nama_perumahan': _namaPerumahanController.text.trim(),
      'desa': _desaController.text.trim(),
      'kecamatan': _kecamatanController.text.trim(),
      'kabupaten': _kabupatenController.text.trim(),
      'provinsi': _provinsiController.text.trim(),
      'add_user': 'username_dummy',
    };

    try {
      final response = await ApiService.post('/residential-areas', body);
      debugPrint(response.toString());

      if (!mounted) return;
      if (response.statusCode == 201 || response.statusCode == 200) {
        await showSuccessDialog(context, 'Data berhasil disimpan');
        _formKey.currentState!.reset();
        _namaPerumahanController.clear();
        _desaController.clear();
        _kecamatanController.clear();
        _kabupatenController.clear();
        _provinsiController.clear();
      } else {
        final responseData = jsonDecode(response.body);
        final errorMsg = responseData['message'] ?? 'Gagal menyimpan data';
        await showErrorDialog(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> _getSuggestions(
    String apiPath,
    String pattern, {
    String? filterCode,
  }) async {
    try {
      String queryParams = '';
      if (filterCode != null && filterCode.isNotEmpty) {
        if (apiPath == 'cities') {
          queryParams = '&province_code=$filterCode';
        } else if (apiPath == 'districts') {
          queryParams = '&city_code=$filterCode';
        } else if (apiPath == 'villages') {
          queryParams = '&district_code=$filterCode';
        }
      }

      final url = 'location/$apiPath?q=$pattern$queryParams';
      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    return [];
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon,
    String? hint,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.blue.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 2.5),
      ),
    );
  }

  Widget _buildSuggestionField({
    required String label,
    required TextEditingController controller,
    required String apiUrl,
    required IconData icon,
    String? hint,
    String? filterCode,
    required Function(String name, String code) onSuggestionSelected,
  }) {
    return TypeAheadFormField<Map<String, dynamic>>(
      textFieldConfiguration: TextFieldConfiguration(
        inputFormatters: getUpperCaseFormatter(),
        controller: controller,
        decoration: _buildInputDecoration(label, icon, hint),
      ),
      suggestionsCallback: (pattern) {
        return _getSuggestions(apiUrl, pattern, filterCode: filterCode);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(title: Text(suggestion['name']));
      },
      onSuggestionSelected: (suggestion) {
        onSuggestionSelected(suggestion['name'], suggestion['code']);
      },
      validator: (value) => value!.isEmpty ? '$label harus diisi' : null,
      noItemsFoundBuilder: (context) => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Data tidak ditemukan'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Residential Area'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaPerumahanController,
                decoration: _buildInputDecoration(
                  'Nama Perumahan',
                  Icons.home,
                  'Masukkan nama perumahan',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Nama perumahan tidak boleh kosong' : null,
                inputFormatters: getUpperCaseFormatter(),
              ),
              const SizedBox(height: 20),

              _buildSuggestionField(
                label: 'Provinsi',
                controller: _provinsiController,
                apiUrl: 'provinces',
                icon: Icons.map,
                hint: 'Pilih Provinsi',
                onSuggestionSelected: (name, code) {
                  setState(() {
                    _provinsiController.text = name;
                    _selectedProvinceCode = code;
                    _kabupatenController.clear();
                    _kecamatanController.clear();
                    _desaController.clear();
                    _selectedCityCode = null;
                    _selectedDistrictCode = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildSuggestionField(
                label: 'Kabupaten',
                controller: _kabupatenController,
                apiUrl: 'cities',
                icon: Icons.location_city,
                hint: 'Pilih Kabupaten',
                filterCode: _selectedProvinceCode,
                onSuggestionSelected: (name, code) {
                  setState(() {
                    _kabupatenController.text = name;
                    _selectedCityCode = code;
                    _kecamatanController.clear();
                    _desaController.clear();
                    _selectedDistrictCode = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildSuggestionField(
                label: 'Kecamatan',
                controller: _kecamatanController,
                apiUrl: 'districts',
                icon: Icons.map_rounded,
                hint: 'Pilih Kecamatan',
                filterCode: _selectedCityCode,
                onSuggestionSelected: (name, code) {
                  setState(() {
                    _kecamatanController.text = name;
                    _selectedDistrictCode = code;
                    _desaController.clear();
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildSuggestionField(
                label: 'Desa',
                controller: _desaController,
                apiUrl: 'villages',
                icon: Icons.location_on,
                hint: 'Pilih Desa',
                filterCode: _selectedDistrictCode,
                onSuggestionSelected: (name, code) {
                  setState(() {
                    _desaController.text = name;
                  });
                },
              ),
              const SizedBox(
                height: 100,
              ), // spasi supaya tidak ketutupan tombol
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: StandardButton(
          label: 'Simpan',
          icon: Icons.save,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              submitResidentialArea();
            }
          },
        ),
      ),
    );
  }
}
