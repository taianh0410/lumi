import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../chat/presentation/socratic_chat_screen.dart';
import '../../classes/screens/class_screen.dart';
import '../../friends/screens/friend_screen.dart';
import '../../groups/screens/group_screen.dart';

enum _NavItem {
  chat('/dashboard', 'Socratic Chat', Icons.chat_bubble_outline, Icons.chat_bubble),
  classes('/classes', 'Lớp học', Icons.school_outlined, Icons.school),
  groups('/groups', 'Nhóm học tập', Icons.group_work, Icons.group_work),
  friends('/friends', 'Bạn bè', Icons.person_add, Icons.person_add_alt_1);

  const _NavItem(this.route, this.label, this.icon, this.activeIcon);

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key, required this.currentPath});

  final String currentPath;

  _NavItem get _selectedItem {
    for (final item in _NavItem.values) {
      if (item.route == currentPath) {
        return item;
      }
    }
    return _NavItem.chat;
  }

  Widget _buildBody() {
    switch (_selectedItem) {
      case _NavItem.chat:
        return const SocraticChatScreen();
      case _NavItem.groups:
        return const GroupScreen();
      case _NavItem.friends:
        return const FriendScreen();
      case _NavItem.classes:
        return const ClassScreen();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final selected = _selectedItem;
    final isWide = MediaQuery.of(context).size.width >= 720;

    return isWide
        ? _WideLayout(
            selected: selected,
            user: user,
            body: _buildBody(),
            onSelect: (item) {
              if (item.route != currentPath) {
                context.go(item.route);
              }
            },
            onLogout: () => ref.read(authProvider.notifier).logout(),
          )
        : _NarrowLayout(
            selected: selected,
            user: user,
            body: _buildBody(),
            onSelect: (item) {
              if (item.route != currentPath) {
                context.go(item.route);
              }
            },
            onLogout: () => ref.read(authProvider.notifier).logout(),
          );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.selected,
    required this.user,
    required this.body,
    required this.onSelect,
    required this.onLogout,
  });

  final _NavItem selected;
  final dynamic user;
  final Widget body;
  final ValueChanged<_NavItem> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: const Color(0xFF0A192F),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const _Logo(),
                const SizedBox(height: 32),
                const Divider(color: Colors.white12, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _NavItem.values
                        .map(
                          (item) => _SidebarItem(
                            item: item,
                            isSelected: item == selected,
                            onTap: () => onSelect(item),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _UserTile(user: user, onLogout: onLogout),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.selected,
    required this.user,
    required this.body,
    required this.onSelect,
    required this.onLogout,
  });

  final _NavItem selected;
  final dynamic user;
  final Widget body;
  final ValueChanged<_NavItem> onSelect;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: Colors.white,
        title: const _Logo(horizontal: true),
        actions: [
          _AvatarButton(user: user, onLogout: onLogout),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A192F),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const _Logo(),
              const SizedBox(height: 24),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _NavItem.values
                      .map(
                        (item) => _SidebarItem(
                          item: item,
                          isSelected: item == selected,
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelect(item);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              _UserTile(user: user, onLogout: onLogout),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: body,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected ? const Color(0xFF1E3A5F) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: isSelected ? const Color(0xFF22D3EE) : Colors.white54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onLogout});

  final dynamic user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final username = user?.username as String? ?? '---';
    final role = user?.role as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF22D3EE),
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A192F),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    username,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white38, size: 18),
              tooltip: 'Đăng xuất',
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.user, required this.onLogout});

  final dynamic user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final username = user?.username as String? ?? '?';
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFF22D3EE),
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF0A192F),
          ),
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Đăng xuất'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        }
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.auto_awesome, color: Color(0xFF22D3EE), size: 28);
    const label = Text(
      'LUMI AI',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );

    if (horizontal) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, SizedBox(width: 8), label],
      );
    }

    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [icon, SizedBox(height: 6), label],
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            '$label - Tính năng đang phát triển',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
