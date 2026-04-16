import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:koto_zayavochnik/features/tickets/bloc/tickets_bloc.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'medium';
  String _selectedCategory = 'Другое';
  bool _isLoading = false;

  final List<String> _priorities = [
    'low',
    'medium',
    'high',
  ];
  
  final List<String> _categories = [
    'Аккаунты и доступ',
    'Софт',
    'Железо',
    'Связь',
    'Другое',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название заявки')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ticketData = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'priority': _selectedPriority,
      'category': _selectedCategory,
    };

    context.read<TicketsBloc>().add(CreateTicket(ticketData));
    
    // Даем время на создание
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заявка создана!')),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Новая заявка'),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isLoading ? null : _createTicket,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Название', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Краткое описание проблемы',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Описание', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Подробное описание...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Приоритет', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'low', label: Text('Низкий')),
                ButtonSegment(value: 'medium', label: Text('Средний')),
                ButtonSegment(value: 'high', label: Text('Высокий')),
              ],
              selected: {_selectedPriority},
              onSelectionChanged: (Set<String> selection) {
                setState(() => _selectedPriority = selection.first);
              },
            ),
            const SizedBox(height: 16),
            const Text('Категория', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
            ),
            const SizedBox(height: 24),
            // Подсказка о категориях
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Категории помогают сортировать заявки на главном экране',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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