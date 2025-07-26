import 'package:flutter/material.dart';
import 'package:smart_cluster_app/features/auth/screens/area_zones_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/gangs_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/houses_screen.dart';
import 'package:smart_cluster_app/features/auth/screens/residential_area_form.dart';
import 'package:smart_cluster_app/widgets/menu_components.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomeTab(), TaskTab(), SettingTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.blueAccent,
          expandedHeight: 120,
          floating: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blueAccent),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Hai, Warga!',
                      style: TextStyle(
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
                      icon: Icons.attach_money,
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
          title: 'Rolse User',
          description: 'Kelola akses pengguna.',
        ),
      ],
    );
  }
}
// Ahir Tab Setting