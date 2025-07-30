// lib/ui/widgets/home_page.dart (Lütfen bu dosyanın içeriğinin en son sana verdiğimle aynı olduğunu DOĞRULA)
import 'package:drift/drift.dart' show Value;
import 'widgets/expense_summary_card.dart';
import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';

import 'settings_page.dart';
import 'managements/alarm_management_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:expensemate2/services/notification_service.dart'; // Bildirim servisini ekle
import 'package:shared_preferences/shared_preferences.dart'; // Alarmı kaydetmek için ekle

import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';
import 'widgets/expense_form.dart';
import 'widgets/expense_list.dart';
import 'widgets/expense_filters.dart';
import 'charts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Kategori listesi (isim, ikon, renk)
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
  int? selectedDay; // Gün filtresi için
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  
  // Gelişmiş filtreleme için yeni değişkenler
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
    final database = Provider.of<AppDatabase>(context, listen: false);
    setState(() {
      _expensesFuture = database.getExpensesByMonth(selectedMonth, selectedYear, selectedCategory);
    });
  }

  // Gelişmiş filtreleme dialogu
  void _showAdvancedFiltersDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(localizations.advancedFilters),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arama
                                  TextField(
                    decoration: InputDecoration(
                      labelText: localizations.search,
                    hintText: 'Başlık veya kategori ara...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setDialogState(() => searchQuery = value),
                ),
                const SizedBox(height: 16),

                // Tarih aralığı
                Text(localizations.dateRange, style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(startDate?.toString().split(' ')[0] ?? 'Başlangıç'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(endDate?.toString().split(' ')[0] ?? 'Bitiş'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tutar aralığı
                Text(localizations.amountRange, style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min Tutar',
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setDialogState(() => minAmount = double.tryParse(value)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Max Tutar',
                          hintText: '1000',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => setDialogState(() => maxAmount = double.tryParse(value)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Çoklu kategori seçimi
                Text(localizations.categories, style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategories.contains(cat['name']);
                    return FilterChip(
                      label: Text(cat['name']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedCategories.add(cat['name']);
                          } else {
                            selectedCategories.remove(cat['name']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  startDate = null;
                  endDate = null;
                  minAmount = null;
                  maxAmount = null;
                  selectedCategories.clear();
                  searchQuery = '';
                });
              },
              child: const Text('Temizle'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _refreshExpenses();
              },
              child: Text(localizations.applyFilters),
            ),
          ],
        ),
      ),
    );
  }

  // Bütçe uyarılarını kontrol et
  Future<void> _checkBudgetWarnings() async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final usage = await database.getBudgetUsage(selectedMonth, selectedYear);
    
    for (final entry in usage.entries) {
      if (entry.value > 100) {
        // Bütçe aşımı uyarısı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${entry.key == 'general' ? 'Genel' : entry.key} bütçesi %${entry.value.toStringAsFixed(1)} aşıldı!'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else if (entry.value > 80) {
        // Bütçe yaklaşım uyarısı
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${entry.key == 'general' ? 'Genel' : entry.key} bütçesi %${entry.value.toStringAsFixed(1)} kullanıldı!'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }



  // Gelişmiş filtreleme fonksiyonu
  List<Expense> _applyAdvancedFilters(List<Expense> expenses) {
    return expenses.where((expense) {
      // Arama sorgusu
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!expense.title.toLowerCase().contains(query) &&
            !expense.category.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Tarih aralığı
      if (startDate != null && expense.date.isBefore(startDate!)) {
        return false;
      }
      if (endDate != null && expense.date.isAfter(endDate!)) {
        return false;
      }

      // Tutar aralığı
      if (minAmount != null && expense.amount < minAmount!) {
        return false;
      }
      if (maxAmount != null && expense.amount > maxAmount!) {
        return false;
      }

      // Çoklu kategori
      if (selectedCategories.isNotEmpty && !selectedCategories.contains(expense.category)) {
        return false;
      }

      return true;
    }).toList();
  }

  void _deleteExpense(Expense expense) async {
    final database = Provider.of<AppDatabase>(context, listen: false);
    await database.deleteExpense(expense.id);
    _refreshExpenses();
  }

  void _editExpenseForm(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ExpenseForm(
          expense: expense,
          categories: categories,
          currency: _currency,
          defaultAlarmTime: _defaultAlarmTime,
          defaultCategory: _defaultCategory,
          onExpenseSaved: () {
            Navigator.pop(context);
            _refreshExpenses();
          },
        ),
      ),
    );
  }

  void _showExpenseForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ExpenseForm(
          categories: categories,
          currency: _currency,
          defaultAlarmTime: _defaultAlarmTime,
          defaultCategory: _defaultCategory,
          onExpenseSaved: () {
            Navigator.pop(context);
            _refreshExpenses();
            _checkBudgetWarnings();
          },
        ),
      ),
    );
  }

  void _addExpenseForm() {
    _showExpenseForm();
  }

  // Bildirim planlandıktan hemen sonra SharedPreferences'a kaydet
  Future<void> _saveAlarmToPrefs(int id, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList('alarms') ?? [];
    alarmList.add("$id:$hour:$minute");
    await prefs.setStringList('alarms', alarmList);
  }

  // Harcama eklenince başarı animasyonu göster
  // _addExpenseForm ve _editExpenseForm içindeki harcama ekleme/güncelleme işlemi başarılı olduğunda
  // Navigator.pop(context); _refreshExpenses();
  // yerine önce başarı animasyonu göster, sonra kapat
  // Bunu bir helper fonksiyon ile yap:
  Future<void> _showSuccessAnimation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: SizedBox(
          width: 360,
          height: 360,
          child: Lottie.asset('assets/lottie/success.json', repeat: false),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (context.mounted) Navigator.of(context).pop();
  }

  // Harcama eklenince başarı banner'ı göster
  void _showSuccessBanner(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.green.shade600,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: Text('Kapat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false, // Başlığı sola yasla
        title: const Text('Cüzdanım', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.alarm),
            tooltip: 'Alarm Yönetimi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlarmManagementPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: localizations.advancedFilters,
            onPressed: _showAdvancedFiltersDialog,
          ),
          IconButton(
            icon: Icon(showPieChart ? Icons.bar_chart : Icons.pie_chart),
            tooltip: showPieChart ? localizations.barChart : localizations.pieChart,
            onPressed: () {
              setState(() {
                showPieChart = !showPieChart;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: localizations.settingsTooltip,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SettingsPage(),
                ),
              );
              await _loadPrefs();
              _refreshExpenses();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(localizations.error(snapshot.error.toString())));
          }

          final expenses = snapshot.data ?? [];
          // Gelişmiş filtreleme uygula
          final filteredExpenses = _applyAdvancedFilters(
            selectedDay != null
                ? expenses.where((e) => e.date.day == selectedDay).toList()
                : expenses
          );
          final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);



          return SingleChildScrollView(
            child: Column(
              children: [
                // Toplam harcama kartı
                ExpenseSummaryCard(
                  totalAmount: totalAmount,
                  currency: _currency,
                ),
                // Grafik ile üstteki widget'lar arasına boşluk
                const SizedBox(height: 10),
                // Analiz kartları ve grafik
                Container(
                  
                  height: 400,
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
                // Grafik ile kategori seçme alanı arasına boşluk
                const SizedBox(height: 20),
              // Filtreleme
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
              if (expenses.isEmpty)
                Container(
                  height: 300,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Lottie.asset('assets/lottie/empty.json', repeat: true),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.noExpenses,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hadi ilk harcamanı ekle!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 300,
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


 