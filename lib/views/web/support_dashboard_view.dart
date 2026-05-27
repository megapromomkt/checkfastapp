import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../core/constants/premium_theme.dart';
import 'dart:async';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Channel metadata (mirrors the provider app channels)
// ─────────────────────────────────────────────────────────────────────────────
const _kChannels = [
  {'id': 'financeiro',      'title': 'Financeiro',              'role': 'financeiro'},
  {'id': 'operacional',     'title': 'Operacional',             'role': 'operacional'},
  {'id': 'rh',              'title': 'Recursos Humanos (RH)',   'role': 'rh'},
  {'id': 'suporte_tecnico', 'title': 'Suporte Técnico',         'role': 'suporte'},
];

class SupportDashboardView extends StatefulWidget {
  final String? initialChatCpf;
  const SupportDashboardView({super.key, this.initialChatCpf});

  @override
  State<SupportDashboardView> createState() => _SupportDashboardViewState();
}

class _SupportDashboardViewState extends State<SupportDashboardView> {
  String _userRole = 'Master Access';
  String _userName = 'Admin Central';

  String? _selectedChatId;
  String? _selectedChatCpf;
  String? _selectedChatName;
  String? _selectedTopic;
  String? _selectedChannelId; // canal do chat selecionado (id: financeiro, operacional...)

  String _activeFilter = 'Todos';
  String _searchQuery = '';

  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  StreamSubscription? _messagesSubscription;
  List<Map<String, dynamic>> _currentChatMessages = [];

  // ── Quick replies loaded for the current chat channel ─────────────────────
  List<String> _quickReplies = [];
  bool _isUploadingChatFile = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    if (widget.initialChatCpf != null) {
      _selectChatByCpf(widget.initialChatCpf!);
    }
  }

  @override
  void didUpdateWidget(SupportDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialChatCpf != oldWidget.initialChatCpf &&
        widget.initialChatCpf != null) {
      _selectChatByCpf(widget.initialChatCpf!);
    }
  }

  void _selectChatByCpf(String cpf) async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(cpf)
          .get();
      if (chatDoc.exists) {
        final data = chatDoc.data()!;
        _selectChat(
          chatDoc.id,
          cpf,
          data['promoterName'] ?? data['name'] ?? 'Promotor',
          data['topic'] ?? 'Operacional',
        );
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(cpf)
            .get();
        String name = 'Promotor';
        if (userDoc.exists) {
          name = userDoc.data()?['name'] ?? 'Promotor';
        }
        final now = DateTime.now().toIso8601String();
        await FirebaseFirestore.instance
            .collection('support_chats')
            .doc(cpf)
            .set({
          'id': cpf,
          'promoterCpf': cpf,
          'promoterName': name,
          'topic': 'Operacional',
          'lastMessage': 'Conversa iniciada pela gerência.',
          'lastMessageTime': now,
          'unreadCountAdmin': 0,
          'unreadCountPromoter': 0,
          'createdAt': now,
          'updatedAt': now,
        });
        _selectChat(cpf, cpf, name, 'Operacional');
      }
    } catch (e) {
      debugPrint('Erro ao selecionar chat por CPF: $e');
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _replyController.dispose();
    _searchController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('admin_user_role') ?? 'Master Access';
    final name = prefs.getString('admin_user_name') ?? 'Admin Central';

    String defaultFilter = 'Todos';
    final roleLower = role.toLowerCase();
    if (roleLower.contains('financeiro'))        defaultFilter = 'Financeiro';
    else if (roleLower.contains('operacional') || roleLower.contains('campo')) defaultFilter = 'Operacional';
    else if (roleLower.contains('rh') || roleLower.contains('recursos') || roleLower.contains('humanos')) defaultFilter = 'RH';
    else if (roleLower.contains('suporte') || roleLower.contains('tecnico') || roleLower.contains('técnico')) defaultFilter = 'Suporte Técnico';

    if (mounted) {
      setState(() {
        _userRole = role;
        _userName = name;
        _activeFilter = defaultFilter;
      });
    }
  }

  // ── Role / topic access helpers ────────────────────────────────────────────

  bool _canAccessTopic(String? topic, String userRole) {
    final roleLower = userRole.toLowerCase();
    if (roleLower.contains('master') || roleLower.contains('admin') ||
        roleLower.contains('diretor') || roleLower.contains('gerente')) {
      return true;
    }
    final topicLower = (topic ?? '').toLowerCase();
    if (roleLower.contains('financeiro'))  return topicLower.contains('financeiro');
    if (roleLower.contains('operacional') || roleLower.contains('campo')) return topicLower.contains('operacional');
    if (roleLower.contains('rh') || roleLower.contains('recursos') || roleLower.contains('humanos')) {
      return topicLower.contains('rh') || topicLower.contains('recursos') || topicLower.contains('humanos');
    }
    if (roleLower.contains('suporte') || roleLower.contains('tecnico') || roleLower.contains('técnico')) {
      return topicLower.contains('suporte') || topicLower.contains('tecnico') || topicLower.contains('técnico');
    }
    return true;
  }

  List<String> _getAvailableFilters() {
    final roleLower = _userRole.toLowerCase();
    if (roleLower.contains('master') || roleLower.contains('admin') ||
        roleLower.contains('diretor') || roleLower.contains('gerente')) {
      return ['Todos', 'Financeiro', 'Operacional', 'RH', 'Suporte Técnico', 'Não Lidas'];
    }
    List<String> filters = [];
    if (roleLower.contains('financeiro')) filters.add('Financeiro');
    else if (roleLower.contains('operacional') || roleLower.contains('campo')) filters.add('Operacional');
    else if (roleLower.contains('rh') || roleLower.contains('recursos') || roleLower.contains('humanos')) filters.add('RH');
    else if (roleLower.contains('suporte') || roleLower.contains('tecnico') || roleLower.contains('técnico')) filters.add('Suporte Técnico');
    else return ['Todos', 'Financeiro', 'Operacional', 'RH', 'Suporte Técnico', 'Não Lidas'];
    filters.add('Não Lidas');
    return filters;
  }

  // ── Channel id helper (topic string → channel id) ─────────────────────────
  String? _channelIdFromTopic(String? topic) {
    if (topic == null) return null;
    final t = topic.toLowerCase();
    if (t.contains('financeiro')) return 'financeiro';
    if (t.contains('operacional')) return 'operacional';
    if (t.contains('rh') || t.contains('recursos')) return 'rh';
    if (t.contains('suporte') || t.contains('tecnico') || t.contains('técnico')) return 'suporte_tecnico';
    return null;
  }

  // ── Load quick replies for the channel the admin is looking at ─────────────
  Future<void> _loadQuickReplies(String? channelId) async {
    if (channelId == null) {
      setState(() => _quickReplies = []);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chat_settings')
          .doc(channelId)
          .get();
      if (doc.exists) {
        final list = doc.data()?['quickReplies'];
        setState(() {
          _quickReplies =
              list is List ? List<String>.from(list.map((e) => e.toString())) : [];
        });
      } else {
        setState(() => _quickReplies = []);
      }
    } catch (_) {
      setState(() => _quickReplies = []);
    }
  }

  // ── Select chat ────────────────────────────────────────────────────────────
  void _selectChat(String chatId, String cpf, String name, String? topic) {
    final channelId = _channelIdFromTopic(topic);
    setState(() {
      _selectedChatId = chatId;
      _selectedChatCpf = cpf;
      _selectedChatName = name;
      _selectedTopic = topic;
      _selectedChannelId = channelId;
      _currentChatMessages = [];
    });

    FirebaseFirestore.instance
        .collection('support_chats')
        .doc(chatId)
        .update({'unreadCountAdmin': 0}).catchError((_) {});

    _loadQuickReplies(channelId);

    _messagesSubscription?.cancel();
    _messagesSubscription = FirebaseFirestore.instance
        .collection('support_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
      final msgs = snapshot.docs.map((d) => d.data()).toList();
      if (mounted) {
        setState(() => _currentChatMessages = msgs);
        _scrollToBottom();
      }
    });
  }

  void _pickAndSendFile() async {
    if (_isUploadingChatFile || _selectedChatId == null) return;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Não foi possível ler os dados do arquivo.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isUploadingChatFile = true);

      final chatId = _selectedChatId!;
      final fileName = file.name;
      final fileExtension = fileName.split('.').last.toLowerCase();
      
      String contentType = 'application/octet-stream';
      String type = 'file';
      if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
        type = 'pdf';
      } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
        type = 'image';
      } else if (fileExtension == 'png') {
        contentType = 'image/png';
        type = 'image';
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pathRef = 'support_attachments/$chatId/${timestamp}_$fileName';

      final storageRef = FirebaseStorage.instance.ref().child(pathRef);
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final now = DateTime.now().toIso8601String();
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'admin',
        'senderName': _userName.isNotEmpty ? _userName : 'Suporte CheckFast',
        'senderRole': 'admin',
        'text': 'Anexo: $fileName',
        'createdAt': now,
        'read': false,
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'type': type,
      });

      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(chatId)
          .set({
        'lastMessage': '📄 [Anexo] $fileName',
        'lastMessageTime': now,
        'lastSenderRole': 'admin',
        'unreadCountPromoter': FieldValue.increment(1),
        'updatedAt': now,
      }, SetOptions(merge: true));

      _scrollToBottom();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ Arquivo "$fileName" enviado com sucesso!'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      print('Erro ao enviar arquivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro ao enviar arquivo: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingChatFile = false);
      }
    }
  }

  // ── Send reply ─────────────────────────────────────────────────────────────
  void _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _selectedChatId == null) return;
    _replyController.clear();
    final now = DateTime.now().toIso8601String();
    final chatId = _selectedChatId!;
    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'admin',
        'senderName': _userName.isNotEmpty ? _userName : 'Suporte CheckFast',
        'senderRole': 'admin',
        'text': text,
        'createdAt': now,
        'read': false,
      });
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(chatId)
          .set({
        'lastMessage': text,
        'lastMessageTime': now,
        'lastSenderRole': 'admin',
        'unreadCountPromoter': FieldValue.increment(1),
        'updatedAt': now,
      }, SetOptions(merge: true));
      _scrollToBottom();
    } catch (e) {
      debugPrint('Erro ao responder chat: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_messagesScrollController.hasClients) {
        _messagesScrollController.animateTo(
          _messagesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
        return '$hour:$minute';
      }
      final diff = now.difference(dateTime).inDays;
      if (diff == 1 || (now.day - dateTime.day == 1 && now.month == dateTime.month)) {
        return 'Ontem';
      }
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SETTINGS DIALOG
  // ─────────────────────────────────────────────────────────────────────────
  void _openSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ChatSettingsDialog(userRole: _userRole),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    Widget bodyContent;
    if (isMobile) {
      bodyContent = _selectedChatId != null
          ? _buildChatDetailSection(isMobile: true)
          : _buildChatListSection(true);
    } else {
      bodyContent = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 380, child: _buildChatListSection(false)),
          VerticalDivider(width: 1, color: AppColors.cardBorder.withOpacity(0.8), thickness: 1),
          Expanded(child: _buildChatDetailSection(isMobile: false)),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isMobile),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(16), child: bodyContent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suporte em Tempo Real',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Centralize a comunicação e esclareça dúvidas dos prestadores.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
        Row(
          children: [
            if (!isMobile) _buildRoleTag(),
            const SizedBox(width: 12),
            // ── Settings button ──
            Tooltip(
              message: 'Configurar mensagens automáticas e respostas rápidas',
              child: OutlinedButton.icon(
                onPressed: _openSettingsDialog,
                icon: const Icon(IconsaxPlusLinear.setting_2, size: 16),
                label: const Text('Configurar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleTag() {
    Color tagColor = AppColors.primaryBlue;
    String tagLabel = _userRole;
    final roleLower = _userRole.toLowerCase();
    if (roleLower.contains('master') || roleLower.contains('admin')) {
      tagColor = AppColors.primaryBlue; tagLabel = 'Acesso Master';
    } else if (roleLower.contains('financeiro')) {
      tagColor = Colors.green;
    } else if (roleLower.contains('operacional') || roleLower.contains('campo')) {
      tagColor = Colors.blueAccent;
    } else if (roleLower.contains('rh') || roleLower.contains('recursos') || roleLower.contains('humanos')) {
      tagColor = Colors.purpleAccent;
    } else if (roleLower.contains('suporte') || roleLower.contains('tecnico') || roleLower.contains('técnico')) {
      tagColor = Colors.orangeAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: tagColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: tagColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(tagLabel, style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Chat list ──────────────────────────────────────────────────────────────
  Widget _buildChatListSection(bool isMobile) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Buscar prestador ou mensagem...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                              onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilterPills(),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.cardBorder.withOpacity(0.5)),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('support_chats')
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
                }
                final allDocs = snapshot.data?.docs ?? [];

                final roleFiltered = allDocs.where((doc) {
                  final topic = doc.data()['topic'] ?? '';
                  return _canAccessTopic(topic, _userRole);
                }).toList();

                final tabFiltered = roleFiltered.where((doc) {
                  final d = doc.data();
                  final topic = (d['topic'] ?? '').toString();
                  final unreadCount = d['unreadCountAdmin'] ?? 0;
                  if (_activeFilter == 'Todos') return true;
                  if (_activeFilter == 'Não Lidas') return unreadCount > 0;
                  final topicLower = topic.toLowerCase();
                  if (_activeFilter == 'Financeiro')    return topicLower.contains('financeiro');
                  if (_activeFilter == 'Operacional')   return topicLower.contains('operacional');
                  if (_activeFilter == 'RH')            return topicLower.contains('rh') || topicLower.contains('recursos') || topicLower.contains('humanos');
                  if (_activeFilter == 'Suporte Técnico') return topicLower.contains('suporte') || topicLower.contains('tecnico') || topicLower.contains('técnico');
                  return false;
                }).toList();

                final searched = tabFiltered.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final d = doc.data();
                  final name = (d['promoterName'] ?? '').toString().toLowerCase();
                  final cpf = (d['promoterCpf'] ?? '').toString().toLowerCase();
                  final lastMsg = (d['lastMessage'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      cpf.contains(_searchQuery.toLowerCase()) ||
                      lastMsg.contains(_searchQuery.toLowerCase());
                }).toList();

                if (searched.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'Nenhum resultado encontrado' : 'Nenhuma conversa neste canal',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty ? 'Verifique a digitação ou tente outro filtro' : 'Os chats abertos por promotores aparecerão aqui',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: searched.length,
                  itemBuilder: (context, index) {
                    final doc = searched[index];
                    final d = doc.data();
                    final chatId = doc.id;
                    final cpf = d['promoterCpf'] ?? '';
                    final name = d['promoterName'] ?? 'Prestador Sem Nome';
                    final lastMsg = d['lastMessage'] ?? '';
                    final topic = d['topic'] ?? 'Geral';
                    final unreadCount = d['unreadCountAdmin'] ?? 0;
                    final timeIso = d['lastMessageTime'] ?? '';
                    final isSelected = chatId == _selectedChatId;
                    return _buildChatItem(d, chatId, cpf, name, lastMsg, topic, unreadCount, _formatMessageTime(timeIso), isSelected, isMobile);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = _getAvailableFilters();
    if (filters.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _activeFilter = filter),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder),
                ),
                child: Center(
                  child: Text(filter, style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> data, String chatId, String cpf, String name, String lastMsg, String topic, int unreadCount, String timeStr, bool isSelected, bool isMobile) {
    Color topicColor = AppColors.primaryBlue;
    final topicLower = topic.toLowerCase();
    if (topicLower.contains('financeiro'))  topicColor = Colors.green;
    else if (topicLower.contains('operacional')) topicColor = Colors.blueAccent;
    else if (topicLower.contains('rh') || topicLower.contains('recursos')) topicColor = Colors.purpleAccent;
    else if (topicLower.contains('suporte') || topicLower.contains('tecnico')) topicColor = Colors.orangeAccent;

    return InkWell(
      onTap: () => _selectChat(chatId, cpf, name, topic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : (unreadCount > 0 ? AppColors.primaryBlue.withOpacity(0.015) : Colors.transparent),
          border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.5))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? AppColors.primaryBlue : AppColors.background,
              child: Text(
                name.isNotEmpty ? name.substring(0, min(name.length, 2)).toUpperCase() : 'P',
                style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(name, style: TextStyle(color: AppColors.textPrimary, fontWeight: unreadCount > 0 ? FontWeight.w800 : FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text(timeStr, style: TextStyle(color: unreadCount > 0 ? AppColors.primaryBlue : AppColors.textSecondary, fontSize: 11, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: topicColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                        child: Text(topic, style: TextStyle(color: topicColor, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(lastMsg, style: TextStyle(color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(10)),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> data, bool isMe) {
    final text = data['text'] ?? '';
    final fileUrl = data['fileUrl'] as String?;
    final fileName = data['fileName'] as String?;
    final type = data['type'] as String?;

    if (fileUrl != null && fileUrl.isNotEmpty) {
      if (type == 'image') {
        return Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 150,
                          color: isMe ? AppColors.primaryBlue.withOpacity(0.2) : Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.primaryBlue),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (text.isNotEmpty && text != 'Anexo: $fileName' && text != fileName) ...[
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ],
        );
      } else {
        final isPdf = type == 'pdf' || (fileName != null && fileName.toLowerCase().endsWith('.pdf'));
        return InkWell(
          onTap: () => launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? Colors.white.withOpacity(0.15) : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isMe ? Colors.white24 : AppColors.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
                  color: isMe ? Colors.white : (isPdf ? Colors.redAccent : AppColors.primaryBlue),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? 'Documento',
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visualizar arquivo',
                        style: TextStyle(
                          color: isMe ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Text(
      text,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 13,
        height: 1.3,
      ),
    );
  }

  // ── Chat detail ────────────────────────────────────────────────────────────
  Widget _buildChatDetailSection({required bool isMobile}) {
    if (_selectedChatId == null) {
      return Container(
        color: AppColors.background.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder)),
                child: const Icon(IconsaxPlusLinear.message_2, size: 40, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Nenhuma conversa selecionada', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Selecione um chat ao lado para visualizar as mensagens.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Detail header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.8)))),
          child: Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => setState(() {
                    _selectedChatId = null;
                    _selectedChatCpf = null;
                    _selectedChatName = null;
                    _selectedTopic = null;
                    _selectedChannelId = null;
                    _currentChatMessages = [];
                    _quickReplies = [];
                  }),
                ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.08),
                child: Text(
                  _selectedChatName != null && _selectedChatName!.isNotEmpty
                      ? _selectedChatName!.substring(0, min(_selectedChatName!.length, 2)).toUpperCase()
                      : 'P',
                  style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedChatName ?? 'Prestador', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Tópico: ${_selectedTopic ?? "Geral"}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: Container(
            color: AppColors.background.withOpacity(0.3),
            child: _currentChatMessages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : ListView.builder(
                    controller: _messagesScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _currentChatMessages.length,
                    itemBuilder: (context, index) {
                      final m = _currentChatMessages[index];
                      final role = m['senderRole'] ?? '';
                      final text = m['text'] ?? '';
                      final isSystem = role == 'system';
                      final isMe = role == 'admin';

                      if (isSystem) {
                        return Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.cardBorder.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                            child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                          ),
                        );
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isMobile ? 0.7 : 0.45)),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                            border: isMe ? null : Border.all(color: AppColors.cardBorder),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: _buildMessageContent(m, isMe),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Typing area with quick replies button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.cardBorder.withOpacity(0.8)))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick replies row (only if there are any loaded)
              if (_quickReplies.isNotEmpty) ...[
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickReplies.length,
                    itemBuilder: (context, idx) {
                      final reply = _quickReplies[idx];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            _replyController.text = reply;
                            _replyController.selection = TextSelection.fromPosition(TextPosition(offset: reply.length));
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 12, color: AppColors.primaryBlue),
                                const SizedBox(width: 4),
                                Text(
                                  reply.length > 40 ? '${reply.substring(0, 40)}...' : reply,
                                  style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Text input + send
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder)),
                      child: Row(
                        children: [
                          _isUploadingChatFile
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary),
                                  onPressed: _pickAndSendFile,
                                ),
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              maxLines: null,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendReply(),
                              decoration: const InputDecoration(
                                hintText: 'Digite uma resposta...',
                                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(left: 4, right: 16, top: 10, bottom: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendReply,
                    backgroundColor: AppColors.primaryBlue,
                    mini: true,
                    elevation: 0,
                    hoverElevation: 2,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS DIALOG — Configure welcome messages and quick replies per channel
// ─────────────────────────────────────────────────────────────────────────────
class _ChatSettingsDialog extends StatefulWidget {
  final String userRole;
  const _ChatSettingsDialog({required this.userRole});

  @override
  State<_ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<_ChatSettingsDialog> {
  int _selectedChannelIndex = 0;
  bool _loading = true;
  bool _saving = false;

  // Per-channel state: channelId → {welcomeMessage, quickReplies[]}
  final Map<String, TextEditingController> _welcomeControllers = {};
  final Map<String, List<TextEditingController>> _quickReplyControllers = {};

  // Which channels this role can configure
  late List<Map<String, String>> _accessibleChannels;

  @override
  void initState() {
    super.initState();
    _accessibleChannels = _buildAccessibleChannels();
    for (final ch in _accessibleChannels) {
      _welcomeControllers[ch['id']!] = TextEditingController();
      _quickReplyControllers[ch['id']!] = [];
    }
    _loadAll();
  }

  List<Map<String, String>> _buildAccessibleChannels() {
    final roleLower = widget.userRole.toLowerCase();
    final isMaster = roleLower.contains('master') || roleLower.contains('admin') ||
        roleLower.contains('diretor') || roleLower.contains('gerente');
    if (isMaster) {
      return _kChannels.map((c) => {'id': c['id']!, 'title': c['title']!}).toList();
    }
    // Role-specific
    return _kChannels.where((c) {
      final roleKey = c['role']!;
      if (roleLower.contains('financeiro') && roleKey == 'financeiro') return true;
      if ((roleLower.contains('operacional') || roleLower.contains('campo')) && roleKey == 'operacional') return true;
      if ((roleLower.contains('rh') || roleLower.contains('recursos') || roleLower.contains('humanos')) && roleKey == 'rh') return true;
      if ((roleLower.contains('suporte') || roleLower.contains('tecnico') || roleLower.contains('técnico')) && roleKey == 'suporte') return true;
      return false;
    }).map((c) => {'id': c['id']!, 'title': c['title']!}).toList();
  }

  Future<void> _loadAll() async {
    for (final ch in _accessibleChannels) {
      final id = ch['id']!;
      try {
        final doc = await FirebaseFirestore.instance.collection('chat_settings').doc(id).get();
        if (doc.exists) {
          final data = doc.data()!;
          _welcomeControllers[id]!.text = data['welcomeMessage'] ?? '';
          final replies = data['quickReplies'];
          if (replies is List) {
            _quickReplyControllers[id] = replies.map((r) => TextEditingController(text: r.toString())).toList();
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveCurrentChannel() async {
    if (_saving || _accessibleChannels.isEmpty) return;
    setState(() => _saving = true);
    final channelId = _accessibleChannels[_selectedChannelIndex]['id']!;
    final welcome = _welcomeControllers[channelId]!.text.trim();
    final replies = (_quickReplyControllers[channelId] ?? []).map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    try {
      await FirebaseFirestore.instance.collection('chat_settings').doc(channelId).set({
        'welcomeMessage': welcome,
        'quickReplies': replies,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso! ✓'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    for (final c in _welcomeControllers.values) { c.dispose(); }
    for (final list in _quickReplyControllers.values) { for (final c in list) { c.dispose(); } }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(IconsaxPlusLinear.setting_2, color: AppColors.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Configurações de Mensagens', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
                        SizedBox(height: 2),
                        Text('Personalize mensagens automáticas e respostas rápidas por canal de atendimento.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))
            else if (_accessibleChannels.isEmpty)
              const Expanded(child: Center(child: Text('Sem canais disponíveis para o seu perfil.', style: TextStyle(color: AppColors.textSecondary))))
            else
              Expanded(
                child: Row(
                  children: [
                    // Left: channel tabs
                    Container(
                      width: 200,
                      color: Colors.white,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text('CANAIS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                          ),
                          ..._accessibleChannels.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ch = entry.value;
                            final isSelected = _selectedChannelIndex == idx;
                            Color channelColor = AppColors.primaryBlue;
                            final id = ch['id']!;
                            if (id == 'financeiro')      channelColor = Colors.green;
                            else if (id == 'operacional') channelColor = Colors.blueAccent;
                            else if (id == 'rh')          channelColor = Colors.purpleAccent;
                            else if (id == 'suporte_tecnico') channelColor = Colors.orangeAccent;
                            return InkWell(
                              onTap: () => setState(() => _selectedChannelIndex = idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? channelColor.withOpacity(0.08) : Colors.transparent,
                                  border: Border(
                                    left: BorderSide(color: isSelected ? channelColor : Colors.transparent, width: 3),
                                    bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.4)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: channelColor, shape: BoxShape.circle)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ch['title']!,
                                        style: TextStyle(
                                          color: isSelected ? channelColor : AppColors.textPrimary,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    VerticalDivider(width: 1, color: AppColors.cardBorder.withOpacity(0.8)),
                    // Right: channel config
                    Expanded(
                      child: _buildChannelConfig(_accessibleChannels[_selectedChannelIndex]['id']!),
                    ),
                  ],
                ),
              ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Fechar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _saveCurrentChannel,
                    icon: _saving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 16),
                    label: Text(_saving ? 'Salvando...' : 'Salvar Canal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelConfig(String channelId) {
    final welcomeCtrl = _welcomeControllers[channelId]!;
    final replyCtrlList = _quickReplyControllers[channelId] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          _buildSectionLabel('💬 MENSAGEM AUTOMÁTICA DE BOAS-VINDAS'),
          const SizedBox(height: 6),
          const Text(
            'Esta mensagem é enviada automaticamente quando o prestador abre este canal pela primeira vez.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: welcomeCtrl,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'Ex: Olá! Seja bem-vindo ao canal de Financeiro. Como posso ajudar?',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Quick replies
          Row(
            children: [
              Expanded(child: _buildSectionLabel('⚡ RESPOSTAS RÁPIDAS DO CANAL')),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _quickReplyControllers[channelId]!.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primaryBlue),
                label: const Text('Adicionar', style: TextStyle(color: AppColors.primaryBlue, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Respostas rápidas aparecem como chips na área de digitação durante o atendimento.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),

          if (replyCtrlList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
              ),
              child: const Center(
                child: Text('Nenhuma resposta rápida cadastrada. Clique em "+ Adicionar".', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else
            ...replyCtrlList.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.06),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                      ),
                      child: Text('${idx + 1}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Digite a resposta rápida...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          ctrl.dispose();
                          _quickReplyControllers[channelId]!.removeAt(idx);
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      tooltip: 'Remover',
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
    );
  }
}
