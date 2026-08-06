import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/group_provider.dart';

class GroupScreen extends ConsumerWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupProvider);
    final notifier = ref.read(groupProvider.notifier);

    if (!state.hasLoaded && !state.isLoading) {
      Future.microtask(notifier.fetchGroups);
    }

    final isFirstLoad = state.isLoading && !state.hasLoaded;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        onPressed: () => _showCreateGroupDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: isFirstLoad
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhóm học tập',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Quản lý nhóm, thành viên và hoạt động học tập của bạn.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    if ((state.errorMessage ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: notifier.fetchGroups,
                        child: state.groups.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 50),
                                  Center(
                                    child: Text(
                                      'Bạn chưa tham gia nhóm nào.',
                                      style: TextStyle(color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: state.groups.length,
                                itemBuilder: (context, index) {
                                  final group = state.groups[index];

                                  final adminName = group.members
                                      .where((m) => m.id == group.adminId)
                                      .map((m) => m.username)
                                      .where((name) => name.trim().isNotEmpty)
                                      .cast<String?>()
                                      .firstWhere(
                                        (name) => name != null,
                                        orElse: () => null,
                                      );

                                  return Card(
                                    color: const Color(0xFF111827),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Colors.white10),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        context.push(
                                          '/chat/${group.id}',
                                          extra: group.name,
                                        );
                                      },
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        title: Text(
                                          group.name.isNotEmpty
                                              ? group.name
                                              : 'Nhóm chưa đặt tên',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            'Admin: ${adminName ?? group.adminId}\nThành viên: ${group.members.length}',
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  );
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

  Future<void> _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final memberIdsController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: const Text(
            'Tạo nhóm mới',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Tên nhóm',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memberIdsController,
                  style: const TextStyle(color: Colors.white),
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Danh sách ID thành viên (cách nhau bởi dấu phẩy)',
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }

                final ids = memberIdsController.text
                    .split(',')
                    .map((id) => id.trim())
                    .where((id) => id.isNotEmpty)
                    .toList();

                await ref.read(groupProvider.notifier).addGroup(name, ids);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tạo nhóm'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    memberIdsController.dispose();
  }
}