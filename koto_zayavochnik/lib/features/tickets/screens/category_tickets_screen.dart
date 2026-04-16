import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koto_zayavochnik/features/tickets/bloc/tickets_bloc.dart';

class CategoryTicketsScreen extends StatefulWidget {
  final String category;
  const CategoryTicketsScreen({super.key, required this.category});

  @override
  State<CategoryTicketsScreen> createState() => _CategoryTicketsScreenState();
}

class _CategoryTicketsScreenState extends State<CategoryTicketsScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    context.read<TicketsBloc>().add(LoadTickets(status: 'all'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<TicketsBloc, TicketsState>(
        listener: (context, state) {
          if (state is TicketsLoaded) {
            setState(() {
              _tickets = state.tickets
                  .where((t) => t['category'] == widget.category)
                  .toList();
              _isLoading = false;
            });
          }
          if (state is TicketsError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<TicketsBloc, TicketsState>(
          builder: (context, state) {
            if (state is TicketsLoading || _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_tickets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Нет заявок в категории "${widget.category}"',
                      style: const TextStyle(fontSize: 16, color: Colors.black45),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.push('/new-task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Создать заявку'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return _TicketCard(
                  ticket: ticket,
                  onTap: () => context.push('/task/${ticket['id']}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
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

  String _getStatusText(String status) {
    switch (status) {
      case 'open': return 'Открыта';
      case 'in_progress': return 'В работе';
      case 'closed': return 'Закрыта';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(ticket['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPriorityText(ticket['priority']),
                      style: TextStyle(
                        color: _getPriorityColor(ticket['priority']),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(ticket['status']),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket['title'] ?? 'Без названия',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (ticket['description'] != null && ticket['description'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ticket['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(ticket['created_at']),
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays} дн. назад';
      if (diff.inHours > 0) return '${diff.inHours} ч. назад';
      if (diff.inMinutes > 0) return '${diff.inMinutes} мин. назад';
      return 'Только что';
    } catch (e) {
      return '';
    }
  }
}