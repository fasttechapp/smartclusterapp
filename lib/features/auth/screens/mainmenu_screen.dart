import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_cluster_app/core/utils/usersesion.dart';
import 'package:smart_cluster_app/features/auth/screens/area_zones_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/gangs_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/houses_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/masteriuran_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/profile_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/residential_area_form.dart';
import 'package:smart_cluster_app/widgets/menu_components.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;
  String? userName;
  List<Widget> get _pages => [
    HomeTab(userName: userName ?? '-'),
    const TaskTab(),
    const SettingTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await UserSession().loadFromPreferences();
    setState(() {
      userName = UserSession().userName;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // hapus semua data login
    if (!mounted) return;
    // ganti route ke login (sesuaikan route-nya)
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goToProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // jangan tampilkan tombol back otomatis
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _goToProfile,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _logout();
              }
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}

//Mulai Tab Home

class HomeTab extends StatelessWidget {
  final String userName;
  const HomeTab({super.key, required this.userName});
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.blueAccent,
          expandedHeight: 40,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.only(top: 20, left: 16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hai warga, $userName !',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Iuran Warga'),
                const SizedBox(height: 8),
                GridMenuSection(
                  items: [
                    MenuItemData(
                      icon: Icons.list,
                      title: 'Iuran',
                      description: 'Daftar jenis iuran.',
                    ),
                    MenuItemData(
                      icon: Icons.payment,
                      title: 'Pembayaran',
                      description: 'Status pembayaran Anda.',
                    ),
                    MenuItemData(
                      icon: Icons.bar_chart,
                      title: 'Laporan Iuran',
                      description: 'Rekap pemasukan warga.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionTitle(title: 'Keamanan'),
                const SizedBox(height: 8),
                GridMenuSection(
                  items: [
                    MenuItemData(
                      icon: Icons.shield,
                      title: 'Tugas Piket',
                      description: 'Petugas keamanan hari ini.',
                    ),
                    MenuItemData(
                      icon: Icons.directions_walk,
                      title: 'Patroli',
                      description: 'Kegiatan patroli hari ini.',
                    ),
                    MenuItemData(
                      icon: Icons.reviews,
                      title: 'Review',
                      description: 'Ulasan petugas keamanan.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

//Akhir Tab Home

class TaskTab extends StatelessWidget {
  const TaskTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Here are your Tasks',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
    );
  }
}

//Awal Tab Setting
class SettingTab extends StatelessWidget {
  const SettingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionTitle(title: 'Config Master'),
        MenuCard(
          icon: Icons.location_city,
          title: 'Residential Areas',
          description: 'Kelola nama perumahan yang terdaftar di sistem.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ResidentialAreaForm()),
            );
          },
        ),
        MenuCard(
          icon: Icons.map,
          title: 'Area Zones',
          description:
              'Input data RT/RW dari perumahan yang sudah didaftarkan.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AreaZoneScreen()),
            );
          },
        ),
        MenuCard(
          icon: Icons.streetview,
          title: 'Gangs',
          description: 'Daftarkan nama gang atau jalan yang ada di perumahan.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GangsScreen()),
            );
          },
        ),
        MenuCard(
          icon: Icons.house,
          title: 'Houses',
          description:
              'Masukkan daftar rumah yang tersedia di lingkungan perumahan.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HousesScreen()),
            );
          },
        ),
        MenuCard(
          icon: Icons.list,
          title: 'Jenis Iuran',
          description:
              'Masukan jenis iuran apa saja dan sampai kapan berlakunya.',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MasterIuranScreen()),
            );
          },
        ),
        const SizedBox(height: 24),
        SectionTitle(title: 'User'),
        MenuCard(
          icon: Icons.verified_user,
          title: 'Approval',
          description:
              'Proses persetujuan akun atau perubahan data oleh admin.',
        ),
        MenuCard(
          icon: Icons.people,
          title: 'Data User',
          description: 'Kelola daftar pengguna dan perannya di sistem.',
        ),
        MenuCard(
          icon: Icons.accessibility,
          title: 'Role User',
          description: 'Kelola akses pengguna.',
        ),
      ],
    );
  }
}
// Ahir Tab Setting