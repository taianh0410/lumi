import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _kMaxWidth = 1200.0;
const _kPrimary = Color(0xFF22D3EE);
const _kBg = Color(0xFF0A192F);
const _kSurface = Color(0xFF112240);
const _kBorder = Color(0xFF1E3A5F);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Ambient glow background
          Positioned(
            top: -120,
            left: -80,
            child: _GlowCircle(color: _kPrimary.withValues(alpha: 0.07), size: 600),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _GlowCircle(color: const Color(0xFF6366F1).withValues(alpha: 0.06), size: 500),
          ),
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: const [
                _Navbar(),
                _HeroSection(),
                _FeaturesSection(),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

Widget _centered({required Widget child}) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxWidth),
        child: child,
      ),
    );

// ── Navbar ────────────────────────────────────────────────────────────────────

class _Navbar extends StatelessWidget {
  const _Navbar();

  @override
  Widget build(BuildContext context) {
    return _centered(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        child: Row(
          children: [
            // Logo
            Image.asset(
              'assets/images/lumi_logo.png',
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: _kPrimary, size: 32),
                  SizedBox(width: 8),
                  Text(
                    'LUMI AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/login'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              child: const Text('Đăng nhập'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => context.push('/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
                elevation: 0,
              ),
              child: const Text('Đăng ký'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return _centered(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Column(
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Next-Gen AI Education Platform',
                style: TextStyle(
                    color: _kPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0),

            SizedBox(height: 32),

            // Headline — plain white, no ShaderMask
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const Text(
                'LUMI AI — Khởi nguồn\ntri thức vô tận',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -1,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms)
                .slideY(begin: 0.25, end: 0),

            SizedBox(height: 24),

            // Subtitle
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const Text(
                'Trải nghiệm học tập thế hệ mới. Phân tích tài liệu chuyên sâu, giải đáp tức thì với công nghệ lõi tiên tiến. Đừng chỉ học, hãy làm chủ kiến thức.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 18,
                  height: 1.75,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 350.ms, duration: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 44),

            // CTA
            _PulseCta(onTap: () => context.push('/register'))
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms)
                .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}

// Pulse animation on CTA
class _PulseCta extends StatefulWidget {
  const _PulseCta({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PulseCta> createState() => _PulseCtaState();
}

class _PulseCtaState extends State<_PulseCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPrimary, Color(0xFF0EA5E9)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.4),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Text(
            'Bắt đầu trải nghiệm ngay →',
            style: TextStyle(
              color: _kBg,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Features ──────────────────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _cards = [
    (
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Socratic Chat',
      desc:
          'Phương pháp hỏi đáp gợi mở giúp hiểu sâu bản chất vấn đề thay vì nhận đáp án có sẵn.',
    ),
    (
      icon: Icons.picture_as_pdf_outlined,
      title: 'Đọc hiểu thông minh',
      desc:
          'Trích xuất và phân tích dữ liệu từ mọi tài liệu phức tạp nhất chỉ trong vài giây.',
    ),
    (
      icon: Icons.group_outlined,
      title: 'Học tập cộng tác',
      desc:
          'Kết nối, thảo luận và chinh phục đỉnh cao tri thức cùng bạn bè trong không gian chung.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kSurface.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: _centered(
        child: Column(
          children: [
            const Text(
              'Tính năng nổi bật',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            const Text(
              'Mọi thứ bạn cần để học hiệu quả hơn, tất cả trong một nền tảng.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 500.ms),
            const SizedBox(height: 52),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _cards.length; i++)
                  _FeatureCard(
                    icon: _cards[i].icon,
                    title: _cards[i].title,
                    desc: _cards[i].desc,
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 150 + i * 120), duration: 500.ms)
                      .slideY(begin: 0.3, end: 0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final String title;
  final String desc;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 320,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: _hovered ? _kSurface : _kBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? _kPrimary.withValues(alpha: 0.5) : _kBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? _kPrimary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: _hovered ? 32 : 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _hovered
                    ? _kPrimary.withValues(alpha: 0.18)
                    : _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: _kPrimary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.desc,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  static final _fbUri =
      Uri.parse('https://www.facebook.com/tai.anh.luong.922191');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      color: const Color(0xFF060F1E),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.facebook, size: 40, color: Colors.blue),
            tooltip: 'Facebook: Lương Anh Tài',
            onPressed: () =>
                launchUrl(_fbUri, mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 12),
          const Text(
            '© 2025 LUMI AI. All rights reserved.',
            style: TextStyle(color: Color(0xFF334155), fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }
}
