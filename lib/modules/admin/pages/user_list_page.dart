import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/user_card.dart';
import 'user_detail_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  static const routeName = '/admin/users';

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserService _service = UserService.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Kullanıcı ara (isim / e-posta / rol)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _service.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kullanıcılar yüklenirken hata oluştu.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? <UserModel>[];
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? users
                    : users
                          .where((user) {
                            final name = user.displayName.toLowerCase();
                            final email = user.email.toLowerCase();
                            final role = user.role.toLowerCase();
                            return name.contains(query) ||
                                email.contains(query) ||
                                role.contains(query);
                          })
                          .toList(growable: false);

                if (filtered.isEmpty) {
                  return const Center(child: Text('Kullanıcı bulunamadı.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final user = filtered[index];
                    return UserCard(
                      user: user,
                      onTap: () => _openDetail(user.uid),
                      onEdit: () => _openDetail(user.uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(String uid) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => UserDetailPage(uid: uid)));
  }
}
