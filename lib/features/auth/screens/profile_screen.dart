import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_cluster_app/core/services/api_service.dart';
import 'package:smart_cluster_app/widgets/showokdialog.dart';
import 'package:smart_cluster_app/widgets/standard_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedVillage;
  String? _selectedResidential;
  String? _selectedHouse;

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _villages = [];
  List<Map<String, dynamic>> _residentials = [];
  List<Map<String, dynamic>> _houses = [];

  final _pemilikController = TextEditingController();
  final _penghuniController = TextEditingController();
  final _noKtpController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    try {
      final response = await ApiService.get('location-profile/provinces');
      debugPrint('Status code: ${response.statusCode}');
      // debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _provinces = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
  }

  Future<void> _loadCities(String provinceCode) async {
    try {
      final response = await ApiService.get(
        'location-profile/cities?province_code=$provinceCode',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _cities = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
    }
  }

  Future<void> _loadDistricts(String cityCode) async {
    try {
      final response = await ApiService.get(
        'location-profile/districts?city_code=$cityCode',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _districts = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading districts: $e');
    }
  }

  Future<void> _loadVillages(String districtCode) async {
    try {
      final response = await ApiService.get(
        'location-profile/villages?district_code=$districtCode',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _villages = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading villages: $e');
    }
  }

  Future<void> _loadResidential(String villageCode) async {
    try {
      final response = await ApiService.get(
        'residential_areas?desa_code=$villageCode&is_active=1',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _residentials = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading residential areas: $e');
    }
  }

  Future<void> _loadHouses(String residentialId) async {
    try {
      final response = await ApiService.get(
        'houses?residential_id=$residentialId',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _houses = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading houses: $e');
    }
  }

  Future<void> _loadHouseDetail(String houseId) async {
    try {
      // Cari rumah yang dipilih dari _houses, ambil pemilik & penghuni
      final selectedHouse = _houses.firstWhere(
        (e) => e['id'].toString() == houseId,
        orElse: () => {},
      );
      if (selectedHouse.isNotEmpty) {
        _pemilikController.text = selectedHouse['pemilik'] ?? '';
        _penghuniController.text = selectedHouse['penghuni'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading house detail: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final body = {
      "province": _selectedProvince,
      "city": _selectedCity,
      "district": _selectedDistrict,
      "village": _selectedVillage,
      "residential_id": _selectedResidential,
      "house_id": _selectedHouse,
      "pemilik": _pemilikController.text.trim(),
      "penghuni": _penghuniController.text.trim(),
      "no_ktp": _noKtpController.text.trim(),
    };

    try {
      final response = await ApiService.post('profile/update', body);
      if (!mounted) return;
      if (response.statusCode == 200) {
        await showSuccessDialog(context, 'Data berhasil disimpan!');
      } else {
        await showErrorDialog(
          context,
          'Gagal menyimpan data: ${response.body}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorDialog(context, 'Error: $e');
    }
  }

  Future<void> _pickAndUploadImageFromGallery() async {
    final status = await Permission.photos.request();
    if (!mounted) return;

    if (status.isGranted) {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        final imageFile = File(picked.path);
        setState(() => _selectedImage = imageFile);
        await _uploadImage(imageFile);
      }
    } else {
      await showErrorDialog(context, 'Izin galeri ditolak!');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    final response = await ApiService.multipartRequest(
      endpoint: 'profile/upload-photo',
      fieldName: 'photo',
      file: imageFile,
      fields: {'user_id': '123'},
    );

    setState(() => _isUploading = false);

    final responseBody = await response.stream.bytesToString();
    if (!mounted) return;

    if (response.statusCode == 200) {
      await showSuccessDialog(context, 'Foto berhasil diupload!');
    } else {
      await showErrorDialog(context, 'Upload gagal: $responseBody');
    }
  }

  @override
  void dispose() {
    _pemilikController.dispose();
    _penghuniController.dispose();
    _noKtpController.dispose();
    super.dispose();
  }

  Widget _buildIconDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<Map<String, dynamic>> items,
    required String valueField,
    required String displayField,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item[valueField] as T,
              child: Text(item[displayField].toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Wajib pilih $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : const AssetImage(
                                      'assets/icon/user_placeholder.png',
                                    )
                                    as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAndUploadImageFromGallery,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.teal,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isUploading) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 16),
                ],
              ),

              _buildIconDropdown(
                label: 'Provinsi',
                icon: Icons.map_outlined,
                value: _selectedProvince,
                items: _provinces,
                valueField: 'code',
                displayField: 'name',
                onChanged: (val) {
                  if (val == _selectedProvince) return;
                  setState(() {
                    _selectedProvince = val;
                    _selectedCity = null;
                    _selectedDistrict = null;
                    _selectedVillage = null;
                    _selectedResidential = null;
                    _selectedHouse = null;
                    _cities = [];
                    _districts = [];
                    _villages = [];
                    _residentials = [];
                    _houses = [];
                  });
                  if (val != null) _loadCities(val);
                },
              ),
              const SizedBox(height: 16),
              _buildIconDropdown(
                label: 'Kabupaten',
                icon: Icons.location_city_outlined,
                value: _selectedCity,
                items: _cities,
                valueField: 'code',
                displayField: 'name',
                onChanged: (val) {
                  if (val == _selectedCity) return;
                  setState(() {
                    _selectedCity = val;
                    _selectedDistrict = null;
                    _selectedVillage = null;
                    _selectedResidential = null;
                    _selectedHouse = null;
                    _districts = [];
                    _villages = [];
                    _residentials = [];
                    _houses = [];
                  });
                  if (val != null) _loadDistricts(val);
                },
              ),
              const SizedBox(height: 16),
              _buildIconDropdown(
                label: 'Kecamatan',
                icon: Icons.location_on_outlined,
                value: _selectedDistrict,
                items: _districts,
                valueField: 'code',
                displayField: 'name',
                onChanged: (val) {
                  if (val == _selectedDistrict) return;
                  setState(() {
                    _selectedDistrict = val;
                    _selectedVillage = null;
                    _selectedResidential = null;
                    _selectedHouse = null;
                    _villages = [];
                    _residentials = [];
                    _houses = [];
                  });
                  if (val != null) _loadVillages(val);
                },
              ),
              const SizedBox(height: 16),
              _buildIconDropdown(
                label: 'Desa',
                icon: Icons.home_work_outlined,
                value: _selectedVillage,
                items: _villages,
                valueField: 'code',
                displayField: 'name',
                onChanged: (val) {
                  if (val == _selectedVillage) return;
                  setState(() {
                    _selectedVillage = val;
                    _selectedResidential = null;
                    _selectedHouse = null;
                    _residentials = [];
                    _houses = [];
                  });
                  if (val != null) _loadResidential(val);
                },
              ),
              const SizedBox(height: 16),
              _buildIconDropdown(
                label: 'Nama Perumahan',
                icon: Icons.apartment_outlined,
                value: _selectedResidential,
                items: _residentials,
                valueField: 'id',
                displayField: 'nama_perumahan',
                onChanged: (val) {
                  if (val == _selectedResidential) return;
                  setState(() {
                    _selectedResidential = val;
                    _selectedHouse = null;
                    _houses = [];
                  });
                  if (val != null) _loadHouses(val);
                },
              ),
              const SizedBox(height: 16),
              _buildIconDropdown(
                label: 'No Rumah',
                icon: Icons.house_outlined,
                value: _selectedHouse,
                items: _houses,
                valueField: 'id',
                displayField: 'no_rumah',
                onChanged: (val) {
                  if (val == _selectedHouse) return;
                  setState(() {
                    _selectedHouse = val;
                  });
                  if (val != null) _loadHouseDetail(val);
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _pemilikController,
                decoration: const InputDecoration(
                  labelText: 'Pemilik',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Pemilik wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _penghuniController,
                decoration: const InputDecoration(
                  labelText: 'Penghuni',
                  prefixIcon: Icon(Icons.group_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Penghuni wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noKtpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'No KTP',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLength: 20,
                validator: (val) =>
                    val == null || val.isEmpty ? 'No KTP wajib diisi' : null,
              ),
              const SizedBox(height: 30),
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
      ),
    );
  }
}
