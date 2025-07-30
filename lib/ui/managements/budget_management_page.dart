import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BudgetManagementPage extends StatefulWidget {
  const BudgetManagementPage({super.key});

  @override
  State<BudgetManagementPage> createState() => _BudgetManagementPageState();
}

class _BudgetManagementPageState extends State<BudgetManagementPage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  late Future<List<dynamic>> _budgetsFuture;
  late Future<Map<String, double>> _usageFuture;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Gıda', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'name': 'Ulaşım', 'icon': Icons.directions_bus, 'color': Colors.blue},
    {'name': 'Kira', 'icon': Icons.home, 'color': Colors.purple},
    {'name': 'Eğlence', 'icon': Icons.movie, 'color': Colors.red},
    {'name': 'Sağlık', 'icon': Icons.local_hospital, 'color': Colors.green},
    {'name': 'Fatura', 'icon': Icons.receipt_long, 'color': Colors.teal},
    {'name': 'Alışveriş', 'icon': Icons.shopping_cart, 'color': Colors.pink},
    {'name': 'Diğer', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _refreshBudgets();
  }

  void _refreshBudgets() {
    final database = Provider.of<AppDatabase>(context, listen: false);
    setState(() {
      _budgetsFuture = database.getBudgetsByMonth(selectedMonth, selectedYear);
      _usageFuture = database.getBudgetUsage(selectedMonth, selectedYear);
    });
  }

  void _addBudgetForm() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Bütçe Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Bütçe Adı',
                  hintText: 'Örn: Ocak Bütçesi',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  hintText: '1000',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori (Opsiyonel)',
                  hintText: 'Genel bütçe için boş bırakın',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Genel Bütçe')),
                  ...categories.map((c) => DropdownMenuItem(
                    value: c['name'],
                    child: Text(c['name']),
                  )),
                ],
                onChanged: (value) => setDialogState(() => selectedCategory = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    final database = Provider.of<AppDatabase>(context, listen: false);
                    final budget = BudgetsCompanion(
                      name: drift.Value(nameController.text),
                      amount: drift.Value(amount),
                      category: drift.Value(selectedCategory),
                      month: drift.Value(selectedMonth),
                      year: drift.Value(selectedYear),
                    );
                    await database.insertBudget(budget);
                    if (mounted) {
                      Navigator.of(ctx).pop();
                      _refreshBudgets();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bütçe başarıyla eklendi!')),
                      );
                    }
                  }
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.budgetManagement),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Ay/Yıl seçici
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: List.generate(12, (i) => i + 1).map((month) {
                      final monthNames = [
                        'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
                      ];
                      return DropdownMenuItem(
                        value: month,
                        child: Text(monthNames[month - 1]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                          _refreshBudgets();
                        });
                      }
                    },
                  ),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                        .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                          _refreshBudgets();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Bütçe kullanımı
          FutureBuilder<Map<String, double>>(
            future: _usageFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bütçe Kullanımı',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...snapshot.data!.entries.map((entry) {
                          final percentage = entry.value;
                          final color = percentage > 100 ? Colors.red : 
                                      percentage > 80 ? Colors.orange : Colors.green;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(entry.key == 'general' ? 'Genel' : entry.key),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Bütçe listesi
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _budgetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                
                final budgets = snapshot.data ?? [];
                
                if (budgets.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Henüz bütçe eklenmemiş',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          budget.category == null ? Icons.account_balance_wallet : Icons.category,
                          color: budget.category == null ? Colors.blue : 
                                categories.firstWhere((c) => c['name'] == budget.category)['color'],
                        ),
                        title: Text(budget.name),
                        subtitle: Text(
                          budget.category == null ? 'Genel Bütçe' : '${budget.category} Kategorisi',
                        ),
                        trailing: Text(
                          '${budget.amount.toStringAsFixed(2)}₺',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onLongPress: () => _deleteBudget(budget.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBudgetForm,
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteBudget(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bütçe Sil'),
        content: const Text('Bu bütçeyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final database = Provider.of<AppDatabase>(context, listen: false);
      await database.deleteBudget(id);
      _refreshBudgets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bütçe silindi!')),
        );
      }
    }
  }
} 