import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koto_zayavochnik/features/tickets/bloc/tickets_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0 - открытые, 1 - в работе, 2 - закрытые

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Аккаунты и доступ', 'icon': Icons.person_outline, 'color': Color(0xFF2196F3), 'category': 'Аккаунты и доступ'},
    {'title': 'Софт', 'icon': Icons.computer_outlined, 'color': Color(0xFF4CAF50), 'category': 'Софт'},
    {'title': 'Железо', 'icon': Icons.build_outlined, 'color': Color(0xFFF44336), 'category': 'Железо'},
    {'title': 'Связь', 'icon': Icons.wifi_outlined, 'color': Color(0xFF9C27B0), 'category': 'Связь'},
    {'title': 'Другое', 'icon': Icons.more_horiz, 'color': Color(0xFF607D8B), 'category': 'Другое'},
  ];

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Открытые', 'status': 'open'},
    {'label': 'В работе', 'status': 'in_progress'},
    {'label': 'Закрытые', 'status': 'closed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  void _loadTickets() {
    final status = _tabs[_selectedTab]['status'] as String;
    context.read<TicketsBloc>().add(LoadTickets(status: status));
  }

  int _getCategoryCount(String category) {
    return _tickets.where((t) => t['category'] == category).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/new-task'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: BlocBuilder<TicketsBloc, TicketsState>(
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
                    onPressed: _loadTickets,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          
          if (state is TicketsLoaded) {
            _tickets = state.tickets;
            _isLoading = false;
          }
          
          return Column(
            children: [
              // Tab bar с тремя вкладками
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      return _TabButton(
                        label: _tabs[index]['label'] as String,
                        selected: _selectedTab == index,
                        onTap: () {
                          setState(() => _selectedTab = index);
                          _loadTickets();
                        },
                      );
                    }),
                  ),
                ),
              ),
              // Category list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final count = _getCategoryCount(cat['category']);
                          return _CategoryTile(
                            title: cat['title'],
                            icon: cat['icon'],
                            color: cat['color'],
                            count: count,
                            onTap: () => context.push('/task-list/${cat['category']}'),
                          );
                        },
                      ),
              ),
              // View all button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/all-tickets'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: const Text(
                      'Просмотреть все категории',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? 'У вас нет заявок'
                        : 'У вас $count заявк${count == 1 ? 'а' : 'и'}',
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}