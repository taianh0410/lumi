import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../chat/presentation/socratic_chat_screen.dart';

// ── Nav destinations ──────────────────────────────────────────────────────────

enum _NavItem {
  chat('Socratic Chat', Icons.chat_bubble_outline, Icons.chat_bubble),
  classes('Lớp học', Icons.school_outlined, Icons.school),
  groups('Nhóm học tập', Icons.group_outlined, Icons.group),
  friends('Bạn bè', Icons.people_outline, Icons.people);

  const _NavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// ── Main Layout ───────────────────────────────────────────────────────────────

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  _NavItem _selected = _NavItem.chat;

  Widget _buildBody() {
    switch (_selected) {
      case _NavItem.chat:
        return const SocraticChatScreen();
      case _NavItem.classes:
      case _NavItem.groups:
      case _NavItem.friends:
        return _ComingSoon(label: _selected.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isWide = MediaQuery.of(context).size.width >= 720;

    // Wide (web/tablet): NavigationRail + body side by side — no AppBar needed
    // Narrow (mobile): AppBar + NavigationDrawer
    return isWide ? _WideLayout(
      selected: _selected,
      user: user,
      body: _buildBody(),
      onSelect: (item) => setState(() => _selected = item),
      onLogout: () => ref.read(authProvider.notifier).logout(),
    ) : _NarrowLayout(
      selected: _selected,
      user: user,
      body: _buildBody(),
      onSelect: (item) => setState(() => _selected = item),
      onLogout: () => ref.read(authProvider.notifier).logout(),
    );
  }
}

// ── Wide layout (Web / Tablet) ────────────────────────────────────────────────

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
          // ── Sidebar ──────────────────────────────────────────────────────
          Container(
            width: 220,
            color: const Color(0xFF0A192F),
            child: Column(
              children: [
                // Logo
                const SizedBox(height: 32),
                const _Logo(),
                const SizedBox(height: 32),
                const Divider(color: Colors.white12, indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _NavItem.values
                        .map((item) => _SidebarItem(
                              item: item,
                              isSelected: item == selected,
                              onTap: () => onSelect(item),
                            ))
                        .toList(),
                  ),
                ),
                // User + logout
                _UserTile(user: user, onLogout: onLogout),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // ── Body ─────────────────────────────────────────────────────────
          Expanded(child: body),
        ],
      ),
    );
  }
}

// ── Narrow layout (Mobile) ────────────────────────────────────────────────────

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
                      .map((item) => _SidebarItem(
                            item: item,
                            isSelected: item == selected,
                            onTap: () {
                              onSelect(item);
                              Navigator.of(context).pop();
                            },
                          ))
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

// ── Sidebar item ──────────────────────────────────────────────────────────────

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
        color: isSelected
            ? const Color(0xFF1E3A5F)
            : Colors.transparent,
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
                  color: isSelected
                      ? const Color(0xFF22D3EE)
                      : Colors.white54,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected ? Colors.white : Colors.white70,
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

// ── User tile ─────────────────────────────────────────────────────────────────

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
                    fontWeight: FontWeight.bold, color: Color(0xFF0A192F)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(username,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  if (role.isNotEmpty)
                    Text(role,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
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

// ── Avatar button (narrow AppBar) ─────────────────────────────────────────────

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
              color: Color(0xFF0A192F)),
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'logout',
          child: const Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('Đăng xuất'),
            ],
          ),
        ),
      ],
      onSelected: (v) { if (v == 'logout') onLogout(); },
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

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

// ── Coming soon placeholder ───────────────────────────────────────────────────

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
            '$label — Tính năng đang phát triển',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
