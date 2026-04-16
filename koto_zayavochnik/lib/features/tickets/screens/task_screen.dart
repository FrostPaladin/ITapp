import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:koto_zayavochnik/core/api/api_client.dart';
import 'package:koto_zayavochnik/features/tickets/bloc/tickets_bloc.dart';

class TaskScreen extends StatefulWidget {
  final String id;
  const TaskScreen({super.key, required this.id});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  Map<String, dynamic>? _ticket;
  bool _isLoading = true;
  final _commentController = TextEditingController();
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    try {
      final ticket = await _api.getTicketById(widget.id);
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final comment = _commentController.text.trim();
    _commentController.clear();
    
    context.read<TicketsBloc>().add(AddComment(widget.id, comment));
    await _loadTicket(); // Обновляем данные
  }

  Future<void> _updateStatus(String newStatus) async {
    context.read<TicketsBloc>().add(UpdateTicket(widget.id, {'status': newStatus}));
    await _loadTicket();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Статус обновлен на "${_getStatusText(newStatus)}"')),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open': return 'Открыта';
      case 'in_progress': return 'В работе';
      case 'closed': return 'Закрыта';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high': return 'Высокий';
      case 'medium': return 'Средний';
      default: return 'Низкий';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket?['title'] ?? 'Заявка'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _updateStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'open', child: Text('Открыть')),
              const PopupMenuItem(value: 'in_progress', child: Text('В работе')),
              const PopupMenuItem(value: 'closed', child: Text('Закрыть')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? const Center(child: Text('Заявка не найдена'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_ticket!['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStatusText(_ticket!['status']),
                                style: TextStyle(color: _getStatusColor(_ticket!['status'])),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Title
                            Text(
                              _ticket!['title'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            // Metadata
                            Row(
                              children: [
                                Icon(Icons.priority_high, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(_getPriorityText(_ticket!['priority'])),
                                const SizedBox(width: 16),
                                Icon(Icons.category, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(_ticket!['category'] ?? 'Другое'),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(_formatDate(_ticket!['created_at'])),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            // Description
                            const Text('Описание', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(_ticket!['description'] ?? 'Нет описания'),
                            const SizedBox(height: 24),
                            // Comments
                            const Text('Комментарии', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ..._buildComments(),
                          ],
                        ),
                      ),
                    ),
                    // Comment input
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: 'Написать комментарий...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _addComment,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildComments() {
    final comments = _ticket!['comments'] as List? ?? [];
    if (comments.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Нет комментариев')),
        ),
      ];
    }
    
    return comments.map((comment) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment['nickname'] ?? 'Пользователь',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(comment['created_at']),
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(comment['text']),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}