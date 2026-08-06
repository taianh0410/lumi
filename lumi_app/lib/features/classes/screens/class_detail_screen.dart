import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/class_models.dart';
import '../data/class_service.dart';

// ── Simple chat message model (local to this screen) ─────────────────────────

class _ChatMsg {
  const _ChatMsg({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

// ── Main screen ───────────────────────────────────────────────────────────────

class ClassDetailScreen extends ConsumerStatefulWidget {
  const ClassDetailScreen({super.key, required this.classModel});

  final ClassModel classModel;

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isTeacher = user?.id == widget.classModel.teacherId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A192F),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.classModel.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text(
              'Mã: ${widget.classModel.joinCode}  •  GV: ${widget.classModel.teacherName}',
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFFBFDBFE)),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF22D3EE),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.folder_outlined, size: 18), text: 'Tài liệu'),
            Tab(icon: Icon(Icons.smart_toy_outlined, size: 18), text: 'AI Gia sư'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Phân tích'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MaterialsTab(classModel: widget.classModel, isTeacher: isTeacher),
          _SocraticTab(classId: widget.classModel.id),
          _HeatmapTab(classId: widget.classModel.id),
        ],
      ),
    );
  }
}

// ── Tab 1: Tài liệu ───────────────────────────────────────────────────────────

class _MaterialsTab extends StatefulWidget {
  const _MaterialsTab({required this.classModel, required this.isTeacher});

  final ClassModel classModel;
  final bool isTeacher;

  @override
  State<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<_MaterialsTab> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không đọc được dữ liệu file.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final service = ClassService();
      final tags =
          await service.uploadMaterial(widget.classModel.id, file);
      debugPrint('[UPLOAD] knowledgeTags: $tags');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Upload và phân tích thành công! Tags: ${tags.join(", ")}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ClassException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_outlined,
                  size: 64, color: Color(0xFF94A3B8)),
              SizedBox(height: 12),
              Text(
                'Chưa có tài liệu nào',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B)),
              ),
              SizedBox(height: 6),
              Text(
                'Giáo viên có thể tải lên bài giảng ở đây.',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),

        // Upload FAB — chỉ hiển thị nếu là giáo viên
        if (widget.isTeacher)
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton.extended(
              heroTag: 'upload_fab',
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Đang xử lý...' : 'Tải lên'),
              onPressed: _isUploading ? null : _pickAndUpload,
            ),
          ),
      ],
    );
  }
}

// ── Tab 2: Socratic AI ────────────────────────────────────────────────────────

class _SocraticTab extends StatefulWidget {
  const _SocraticTab({required this.classId});
  final String classId;

  @override
  State<_SocraticTab> createState() => _SocraticTabState();
}

class _SocraticTabState extends State<_SocraticTab> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatMsg>[];
  bool _isSending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_ChatMsg(text: text, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final dio = ApiClient.instance.dio;
      final res = await dio.post<dynamic>(
        '/api/classes/${widget.classId}/socratic',
        data: {'message': text},
      );
      final answer = (res.data as Map)['answer']?.toString() ??
          'Không nhận được phản hồi từ AI.';
      setState(() {
        _messages.add(_ChatMsg(text: answer, isUser: false));
        _isSending = false;
      });
    } on DioException catch (e) {
      final errMsg = (e.response?.data is Map)
          ? (e.response!.data as Map)['message']?.toString() ??
              'Lỗi kết nối AI.'
          : 'Lỗi kết nối AI.';
      setState(() {
        _messages.add(_ChatMsg(text: errMsg, isUser: false));
        _isSending = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(
            const _ChatMsg(text: 'Lỗi không xác định.', isUser: false));
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Message list ────────────────────────────────────────────────
        Expanded(
          child: _messages.isEmpty
              ? const _ChatEmpty()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount:
                      _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (_isSending && i == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _Bubble(msg: _messages[i]);
                  },
                ),
        ),

        // ── Input bar ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Đặt câu hỏi cho AI gia sư...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                            color: Color(0xFF0F766E), width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: _isSending
                        ? Colors.grey.shade300
                        : const Color(0xFF0F766E),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _isSending ? null : _send,
                      child: Center(
                        child: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.send,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _ChatMsg msg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment:
            msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? const Color(0xFF0A192F)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                bottomRight: Radius.circular(msg.isUser ? 4 : 16),
              ),
              border: msg.isUser
                  ? null
                  : Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.isUser ? 'Bạn' : 'LUMI AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: msg.isUser
                        ? Colors.white60
                        : const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: msg.isUser
                        ? Colors.white
                        : const Color(0xFF1E293B),
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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _InlineTyping(),
      ),
    );
  }
}

class _InlineTyping extends StatelessWidget {
  const _InlineTyping();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: const Color(0xFF22D3EE)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('LUMI đang suy nghĩ...',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F766E))),
        ],
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy_outlined,
              size: 56, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text(
            'Đặt câu hỏi để LUMI hướng dẫn bạn!',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: Analytics / Heatmap ────────────────────────────────────────────────

class _HeatmapTab extends StatefulWidget {
  const _HeatmapTab({required this.classId});
  final String classId;

  @override
  State<_HeatmapTab> createState() => _HeatmapTabState();
}

class _HeatmapTabState extends State<_HeatmapTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _heatmapData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHeatmap();
  }

  Future<void> _fetchHeatmap() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ClassService().getHeatmapData(widget.classId);
      setState(() { _heatmapData = data; _isLoading = false; });
    } on ClassException catch (e) {
      setState(() { _error = e.message; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetchHeatmap,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final rawTags = _heatmapData?['tags'];
    final rawStudents = _heatmapData?['students'];
    final rawMatrix = _heatmapData?['matrix'];

    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];
    final students = rawStudents is List
        ? rawStudents
            .whereType<Map>()
            .map((s) => {'id': s['id'].toString(), 'username': s['username'].toString()})
            .toList()
        : <Map<String, String>>[];
    final matrix = rawMatrix is Map ? rawMatrix : {};

    if (tags.isEmpty || students.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu phân tích.\nHãy upload tài liệu và học sinh tham gia lớp.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Legend ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 16,
            children: const [
              _LegendChip(color: Color(0xFFEF4444), label: 'Đỏ: Rất yếu (<50)'),
              _LegendChip(color: Color(0xFFF97316), label: 'Cam: Yếu (50-74)'),
              _LegendChip(color: Color(0xFF22C55E), label: 'Xanh: Tốt (≥75)'),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Matrix ─────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF0A192F)),
                headingTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
                dataRowMinHeight: 48,
                dataRowMaxHeight: 48,
                columnSpacing: 8,
                columns: [
                  const DataColumn(
                    label: Text('Học sinh',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ...tags.map(
                    (tag) => DataColumn(
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 90),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
                rows: students.map((student) {
                  final sid = student['id']!;
                  final studentMatrix =
                      matrix[sid] is Map ? matrix[sid] as Map : {};
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        student['username'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      )),
                      ...tags.map((tag) {
                        final score = (studentMatrix[tag] as num?)?.toInt() ?? 0;
                        return DataCell(_HeatCell(score: score));
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.score});
  final int score;

  Color get _color {
    if (score < 50) return const Color(0xFFEF4444);
    if (score < 75) return const Color(0xFFF97316);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 34,
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
      ],
    );
  }
}
