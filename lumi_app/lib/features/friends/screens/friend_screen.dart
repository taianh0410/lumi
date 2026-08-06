import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/friend_provider.dart';

final _friendInputProvider = StateProvider<String>((ref) => '');

class FriendScreen extends ConsumerWidget {
  const FriendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendProvider);
    final notifier = ref.read(friendProvider.notifier);
    final targetInput = ref.watch(_friendInputProvider);

    if (!state.hasLoadedData && !state.isLoading) {
      Future.microtask(notifier.loadInitialData);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A192F),
          foregroundColor: Colors.white,
          title: const Text('Bạn bè'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFF94A3B8),
            indicatorColor: Color(0xFF22D3EE),
            tabs: [
              Tab(text: 'Danh sách'),
              Tab(text: 'Lời mời'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _FriendsTab(
                ref: ref,
                friends: state.friends,
                isLoading: state.isLoading && !state.hasLoadedData,
                onRefresh: notifier.loadInitialData,
              ),
              _InvitesTab(
                state: state,
                notifier: notifier,
                targetInput: targetInput,
                onInputChanged: (value) =>
                    ref.read(_friendInputProvider.notifier).state = value,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({
    required this.ref,
    required this.friends,
    required this.isLoading,
    required this.onRefresh,
  });

  final WidgetRef ref;
  final List<UserModel> friends;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: friends.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Text(
                    'Chưa có bạn bè nào.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final displayName = friend.username.isNotEmpty ? friend.username : friend.id;

                return Card(
                  color: const Color(0xFF111827),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white10),
                  ),
                  child: ListTile(
                    title: Text(
                      displayName,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      friend.role,
                      style: const TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.message, color: Color(0xFF22D3EE)),
                      onPressed: () async {
                        try {
                          final group = await ref.read(groupProvider.notifier).openDirectChat(friend.id);

                          if (!context.mounted) {
                            return;
                          }

                          context.push('/chat/${group.id}', extra: friend.username);
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.toString()),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.red.shade700,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({
    required this.state,
    required this.notifier,
    required this.targetInput,
    required this.onInputChanged,
  });

  final FriendState state;
  final FriendNotifier notifier;
  final String targetInput;
  final ValueChanged<String> onInputChanged;

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = state.isLoading && !state.hasLoadedData;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập ID hoặc username',
                      hintStyle: const TextStyle(color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF0B1220),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF22D3EE)),
                      ),
                    ),
                    onChanged: onInputChanged,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading || targetInput.trim().isEmpty
                        ? null
                        : () async {
                            await notifier.sendRequest(targetInput.trim());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF334155),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kết bạn'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if ((state.errorMessage ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
              ),
            ),
          if ((state.lastActionMessage ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                state.lastActionMessage!,
                style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12),
              ),
            ),
          const Text(
            'Danh sách chờ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
                  )
                : RefreshIndicator(
                    onRefresh: notifier.loadInitialData,
                    child: state.pendingRequests.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 40),
                              Center(
                                child: Text(
                                  'Chưa có lời mời kết bạn nào.',
                                  style: TextStyle(color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            itemCount: state.pendingRequests.length,
                            itemBuilder: (context, index) {
                              final requester = state.pendingRequests[index];
                              final title = requester.username.isNotEmpty
                                  ? requester.username
                                  : requester.id;
                              final subtitle = requester.id.isNotEmpty
                                  ? 'ID: ${requester.id}'
                                  : 'ID chưa xác định';
                              final avatarText = title.isNotEmpty
                                  ? title.substring(0, 1).toUpperCase()
                                  : '?';

                              return Card(
                                color: const Color(0xFF111827),
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Colors.white10),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF1E293B),
                                    child: Text(
                                      avatarText,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    subtitle,
                                    style: const TextStyle(color: Color(0xFF94A3B8)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: state.isLoading
                                        ? null
                                        : () async {
                                            await notifier.acceptRequest(requester.id);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Chấp nhận'),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}