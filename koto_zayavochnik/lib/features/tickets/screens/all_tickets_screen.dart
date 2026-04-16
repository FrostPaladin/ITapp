import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koto_zayavochnik/features/tickets/bloc/tickets_bloc.dart';

class AllTicketsScreen extends StatefulWidget {
  const AllTicketsScreen({super.key});

  @override
  State<AllTicketsScreen> createState() => _AllTicketsScreenState();
}

class _AllTicketsScreenState extends State<AllTicketsScreen> {
  int _selectedTab = 0; // 0 - все, 1 - открытые, 2 - в работе, 3 - закрытые
  
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Все', 'status': 'all'},
    {'label': 'Открытые', 'status': 'open'},
    {'label': 'В работе', 'status': 'in_progress'},
    {'label': 'Закрытые', 'status': 'closed'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все заявки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/new-task'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_tabs[index]['label'] as String),
                      selected: _selectedTab == index,
                      onSelected: (selected) {
                        setState(() => _selectedTab = index);
                      },
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _selectedTab == index ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Tickets list
          Expanded(
            child: BlocBuilder<TicketsBloc, TicketsState>(
              builder: (context, state) {
                if (state is TicketsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (state is TicketsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ошибка: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TicketsBloc>().add(LoadTickets(status: 'all'));
                          },
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (state is TicketsLoaded) {
                  final status = _tabs[_selectedTab]['status'] as String;
                  final filtered = status == 'all'
                      ? state.tickets
                      : state.tickets.where((t) => t['status'] == status).toList();
                  
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Нет ${_tabs[_selectedTab]['label']} заявок',
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
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ticket = filtered[index];
                      return _TicketCard(
                        ticket: ticket,
                        onTap: () => context.push('/task/${ticket['id']}'),
                      );
                    },
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open': return Colors.green;
      case 'in_progress': return Colors.orange;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
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
                      color: _getStatusColor(ticket['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(ticket['status']),
                      style: TextStyle(
                        color: _getStatusColor(ticket['status']),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ticket['category'] ?? 'Другое',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                      textAlign: TextAlign.right,
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