import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../purchasing/services/purchasing_dashboard_service.dart';
import '../services/module_access_service.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  static const routeName = '/admin/dashboard';

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_DashboardData> _loadData() async {
    final users = await UserService.instance.getUsersStream().first;
    final roles = await RoleService.instance.getRolesStream().first;
    final modules = await ModuleAccessService.instance.getModulesStream().first;

    final summary = await PurchasingDashboardService.instance.getSummary();

    return _DashboardData(
      totalUsers: users.length,
      activeUsers: users.where((u) => u.isActive).length,
      totalRoles: roles.length,
      activeModules: modules.where((m) => m.isActive).length,
      moduleNames: modules
          .map((m) => '${m.name} (${m.isActive ? 'Açık' : 'Kapalı'})')
          .toList(),
      latestInfo: [
        'Ortalama Teslim Süresi: ${summary.avgLeadTimeDays.toStringAsFixed(1)} gün',
        'Geciken PO: ${summary.delayedPOs}',
      ],
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli')),
      body: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Veriler yüklenirken hata oluştu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('Veri bulunamadı.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yönetim Paneli',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildKpiSection(data),
                  const SizedBox(height: 24),
                  _buildQuickLinks(context),
                  const SizedBox(height: 24),
                  _buildActivityFeed(data),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiSection(_DashboardData data) {
    final cards = [
      _KpiTile(
        title: 'Toplam Kullanıcı',
        value: NumberFormat.decimalPattern('tr_TR').format(data.totalUsers),
      ),
      _KpiTile(
        title: 'Aktif Kullanıcı',
        value: NumberFormat.decimalPattern('tr_TR').format(data.activeUsers),
      ),
      _KpiTile(title: 'Toplam Rol', value: data.totalRoles.toString()),
      _KpiTile(title: 'Aktif Modül', value: data.activeModules.toString()),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: cards
          .map(
            (tile) => SizedBox(
              width: 260,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tile.value,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      _QuickLink(
        icon: Icons.manage_accounts_outlined,
        label: 'Kullanıcılar',
        onTap: () => Navigator.of(context).pushNamed('/admin/users'),
      ),
      _QuickLink(
        icon: Icons.rule_folder_outlined,
        label: 'Roller',
        onTap: () => Navigator.of(context).pushNamed('/admin/roles'),
      ),
      _QuickLink(
        icon: Icons.toggle_on_outlined,
        label: 'Modül Erişimleri',
        onTap: () => Navigator.of(context).pushNamed('/admin/modules'),
      ),
      _QuickLink(
        icon: Icons.settings_outlined,
        label: 'Sistem Ayarları',
        onTap: () => Navigator.of(context).pushNamed('/admin/settings'),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: links
              .map(
                (link) => OutlinedButton.icon(
                  onPressed: link.onTap,
                  icon: Icon(link.icon),
                  label: Text(link.label),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(_DashboardData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktif Modüller',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...data.moduleNames.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.widgets_outlined),
                title: Text(entry),
              ),
            ),
            const Divider(),
            Text(
              'Kısa Notlar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...data.latestInfo.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: Text(item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalRoles,
    required this.activeModules,
    required this.moduleNames,
    required this.latestInfo,
  });

  final int totalUsers;
  final int activeUsers;
  final int totalRoles;
  final int activeModules;
  final List<String> moduleNames;
  final List<String> latestInfo;
}

class _KpiTile {
  const _KpiTile({required this.title, required this.value});

  final String title;
  final String value;
}

class _QuickLink {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
