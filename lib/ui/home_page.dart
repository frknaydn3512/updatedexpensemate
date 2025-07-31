import 'package:drift/drift.dart' show Value;
import 'widgets/expense_summary_card.dart';
import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

import 'settings_page.dart';
import 'managements/alarm_management_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:expensemate2/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'widgets/expense_form.dart';
import 'widgets/expense_list.dart';
import 'widgets/expense_filters.dart';
import 'little_things/charts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  
  late Future<List<Expense>> _expensesFuture;
  String? selectedCategory;
  int? selectedDay;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  
  DateTime? startDate;
  DateTime? endDate;
  double? minAmount;
  double? maxAmount;
  Set<String> selectedCategories = {};
  String searchQuery = '';
  final months = List.generate(12, (i) => i + 1);
  final years = List.generate(5, (i) => DateTime.now().year - 2 + i);

  bool showPieChart = true;
  String _currency = '₺';
  String _defaultCategory = '';
  TimeOfDay? _defaultAlarmTime;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _refreshExpenses();
    notificationTapExpenseId.addListener(_onNotificationTap);
  }

  @override
  void dispose() {
    notificationTapExpenseId.removeListener(_onNotificationTap);
    super.dispose();
  }

  void _onNotificationTap() async {
    final id = notificationTapExpenseId.value;
    if (id != null) {
      final database = Provider.of<AppDatabase>(context, listen: false);
      final allExpenses = await database.getAllExpenses();
      final expense = allExpenses.where((e) => e.id == id).isNotEmpty ? allExpenses.firstWhere((e) => e.id == id) : null;
      if (expense != null) {
        _editExpenseForm(expense);
      }
      notificationTapExpenseId.value = null;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString('currency') ?? '₺';
      _defaultCategory = prefs.getString('default_category') ?? categories.first['name'];
      final alarmStr = prefs.getString('default_alarm_time');
      if (alarmStr != null) {
        final parts = alarmStr.split(':');
        if (parts.length == 2) {
          _defaultAlarmTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
    });
  }

  void _refreshExpenses() {
    setState(() {
      _expensesFuture = _getFilteredExpenses();
    });
  }

  Future<List<Expense>> _getFilteredExpenses() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    List<Expense> expenses = await database.getAllExpenses();

    // Kategori filtresi
    if (selectedCategory != null) {
      expenses = expenses.where((e) => e.category == selectedCategory).toList();
    }

    // Gün filtresi
    if (selectedDay != null) {
      expenses = expenses.where((e) => e.date.day == selectedDay).toList();
    }

    // Ay ve yıl filtresi
    expenses = expenses.where((e) => e.date.month == selectedMonth && e.date.year == selectedYear).toList();

    // Gelişmiş filtreler
    if (startDate != null) {
      expenses = expenses.where((e) => e.date.isAfter(startDate!.subtract(const Duration(days: 1)))).toList();
    }
    if (endDate != null) {
      expenses = expenses.where((e) => e.date.isBefore(endDate!.add(const Duration(days: 1)))).toList();
    }
    if (minAmount != null) {
      expenses = expenses.where((e) => e.amount >= minAmount!).toList();
    }
    if (maxAmount != null) {
      expenses = expenses.where((e) => e.amount <= maxAmount!).toList();
    }
    if (selectedCategories.isNotEmpty) {
      expenses = expenses.where((e) => selectedCategories.contains(e.category)).toList();
    }
    if (searchQuery.isNotEmpty) {
      expenses = expenses.where((e) => e.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    return expenses;
  }

  void _showExpenseForm({Expense? expense}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseForm(
        expense: expense,
        categories: categories,
        currency: _currency,
        defaultCategory: _defaultCategory,
        defaultAlarmTime: _defaultAlarmTime,
        onExpenseSaved: () {
          _refreshExpenses();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _editExpenseForm(Expense expense) {
    _showExpenseForm(expense: expense);
  }

  void _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harcamayı Sil'),
        content: const Text('Bu harcamayı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final database = Provider.of<AppDatabase>(context, listen: false);
      await database.deleteExpense(expense.id);
      _refreshExpenses();
    }
  }

  void _showAdvancedFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gelişmiş Filtreler'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tarih aralığı
                const Text('Tarih Aralığı'),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => startDate = date);
                          }
                        },
                        child: Text(startDate?.toString().split(' ')[0] ?? 'Başlangıç'),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => endDate = date);
                          }
                        },
                        child: Text(endDate?.toString().split(' ')[0] ?? 'Bitiş'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tutar aralığı
                const Text('Tutar Aralığı'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Min Tutar'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => minAmount = double.tryParse(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Max Tutar'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => maxAmount = double.tryParse(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Kategori seçimi
                const Text('Kategoriler'),
                Wrap(
                  children: categories.map((category) {
                    final isSelected = selectedCategories.contains(category['name']);
                    return FilterChip(
                      label: Text(category['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category['name']);
                          } else {
                            selectedCategories.remove(category['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                startDate = null;
                endDate = null;
                minAmount = null;
                maxAmount = null;
                selectedCategories.clear();
              });
              _refreshExpenses();
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          TextButton(
            onPressed: () {
              _refreshExpenses();
              Navigator.pop(context);
            },
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cüzdanım'),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlarmManagementPage()),
              );
            },
            tooltip: 'Alarm Yönetimi',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showAdvancedFiltersDialog(),
            tooltip: 'Filtreleme',
          ),
          IconButton(
            icon: Icon(showPieChart ? Icons.bar_chart : Icons.pie_chart),
            onPressed: () {
              setState(() {
                showPieChart = !showPieChart;
              });
            },
            tooltip: 'Grafik Türü',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final expenses = snapshot.data ?? [];
          final filteredExpenses = expenses;

                                return SingleChildScrollView(
             child: Column(
               children: [
                                // ExpenseChart her zaman göster (3'lü kartlar için)
               Container(
                 height: expenses.isEmpty ? 150 : 450,
                   child: ExpenseChart(
                     expenses: expenses,
                     showPieChart: showPieChart,
                     currency: _currency,
                     onCategoryTap: (cat) {
                       setState(() {
                         selectedCategory = cat;
                         selectedDay = null;
                         _refreshExpenses();
                       });
                     },
                     onDayTap: (day) {
                       setState(() {
                         selectedDay = day;
                         selectedCategory = null;
                       });
                     },
                   ),
                 ),
                 // Boş olduğunda "No expenses yet" kısmını göster
                 if (expenses.isEmpty)
                   Container(
                     height: 300,
                     child: Center(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           SizedBox(
                             width: 150,
                             height: 150,
                             child: Lottie.asset('assets/lottie/empty.json', repeat: true),
                           ),
                           const SizedBox(height: 24),
                           Text(
                             localizations.noExpenses,
                             style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                               color: Colors.grey[600],
                               fontWeight: FontWeight.w500,
                             ),
                             textAlign: TextAlign.center,
                           ),
                           const SizedBox(height: 8),
                           Text(
                             'Hadi ilk harcamanı ekle!',
                             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                               color: Colors.grey[500],
                             ),
                             textAlign: TextAlign.center,
                           ),
                         ],
                       ),
                     ),
                   ),
                                   // Grafik ile kategori seçme alanı arasına boşluk
                  const SizedBox(height: 0),
                 // Filtreleme - sadece harcama varsa göster
                 if (expenses.isNotEmpty)
                   ExpenseFilters(
                     selectedCategory: selectedCategory,
                     selectedDay: selectedDay,
                     startDate: startDate,
                     endDate: endDate,
                     minAmount: minAmount,
                     maxAmount: maxAmount,
                     selectedCategories: selectedCategories,
                     searchQuery: searchQuery,
                     categories: categories,
                     onCategoryChanged: (value) {
                       setState(() {
                         selectedCategory = value;
                         selectedDay = null;
                         _refreshExpenses();
                       });
                     },
                     onDayChanged: (value) {
                       setState(() {
                         selectedDay = value;
                         selectedCategory = null;
                       });
                     },
                     onStartDateChanged: (value) {
                       setState(() {
                         startDate = value;
                         _refreshExpenses();
                       });
                     },
                     onEndDateChanged: (value) {
                       setState(() {
                         endDate = value;
                         _refreshExpenses();
                       });
                     },
                     onMinAmountChanged: (value) {
                       setState(() {
                         minAmount = value;
                         _refreshExpenses();
                       });
                     },
                     onMaxAmountChanged: (value) {
                       setState(() {
                         maxAmount = value;
                         _refreshExpenses();
                       });
                     },
                     onSelectedCategoriesChanged: (value) {
                       setState(() {
                         selectedCategories = value;
                         _refreshExpenses();
                       });
                     },
                     onSearchQueryChanged: (value) {
                       setState(() {
                         searchQuery = value;
                         _refreshExpenses();
                       });
                     },
                     onClearFilters: () {
                       setState(() {
                         selectedCategory = null;
                         selectedDay = null;
                         startDate = null;
                         endDate = null;
                         minAmount = null;
                         maxAmount = null;
                         selectedCategories.clear();
                         searchQuery = '';
                         _refreshExpenses();
                       });
                     },
                     onShowAdvancedFilters: () => _showAdvancedFiltersDialog(),
                   ),
                 if (expenses.isNotEmpty)
                   Container(
                     height: 400,
                     child: ExpenseList(
                       expenses: filteredExpenses,
                       currency: _currency,
                       onEditExpense: _editExpenseForm,
                       onDeleteExpense: _deleteExpense,
                     ),
                   ),
               ],
             ),
           );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showExpenseForm(),
          child: const Icon(Icons.add, size: 28),
          tooltip: localizations.addExpense,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
} 