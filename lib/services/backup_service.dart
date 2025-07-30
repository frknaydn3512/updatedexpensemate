import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // Yedekleme oluştur
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final database = AppDatabase();
      final expenses = await database.getAllExpenses();
      final budgets = await database.getAllBudgets();
      final prefs = await SharedPreferences.getInstance();

      // Kullanıcı ayarlarını al
      final settings = {
        'currency': prefs.getString('currency'),
        'default_category': prefs.getString('default_category'),
        'default_alarm_time': prefs.getString('default_alarm_time'),
        'theme_mode': prefs.getString('theme_mode'),
        'language': prefs.getString('language'),
        'alarms': prefs.getStringList('alarms'),
      };

      final backup = {
        'version': '1.0',
        'created_at': DateTime.now().toIso8601String(),
        'expenses': expenses.map((e) => {
          'id': e.id,
          'title': e.title,
          'amount': e.amount,
          'category': e.category,
          'date': e.date.toIso8601String(),
        }).toList(),
        'budgets': budgets.map((b) => {
          'id': b.id,
          'name': b.name,
          'amount': b.amount,
          'category': b.category,
          'month': b.month,
          'year': b.year,
          'isActive': b.isActive,
          'createdAt': b.createdAt.toIso8601String(),
        }).toList(),
        'settings': settings,
      };

      return backup;
    } catch (e) {
      throw Exception('Yedekleme oluşturulamadı: $e');
    }
  }

  // Yedeklemeyi dosyaya kaydet
  Future<String> saveBackupToFile(Map<String, dynamic> backup) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'expensemate_backup_$timestamp.json';
      final file = File('${backupDir.path}/$fileName');

      final jsonString = JsonEncoder.withIndent('  ').convert(backup);
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Yedekleme dosyası kaydedilemedi: $e');
    }
  }

  // Yedeklemeyi Downloads klasörüne kaydet
  Future<String> saveBackupToDownloads(Map<String, dynamic> backup) async {
    try {
      final directory = await getExternalStorageDirectory();
      final downloadsDir = Directory("${directory!.parent.parent.parent.parent.path}/Download");
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'expensemate_backup_$timestamp.json';
      final file = File('${downloadsDir.path}/$fileName');

      final jsonString = JsonEncoder.withIndent('  ').convert(backup);
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Yedekleme Downloads klasörüne kaydedilemedi: $e');
    }
  }

  // Yedekleme dosyasını oku
  Future<Map<String, dynamic>> loadBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Yedekleme dosyası bulunamadı');
      }

      final jsonString = await file.readAsString();
      final backup = json.decode(jsonString) as Map<String, dynamic>;

      // Versiyon kontrolü
      final version = backup['version'] as String?;
      if (version == null || !version.startsWith('1.')) {
        throw Exception('Desteklenmeyen yedekleme formatı');
      }

      return backup;
    } catch (e) {
      throw Exception('Yedekleme dosyası okunamadı: $e');
    }
  }

  // Yedeklemeyi geri yükle
  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    try {
      final database = AppDatabase();
      final prefs = await SharedPreferences.getInstance();

      // Mevcut verileri temizle
      final expenses = await database.getAllExpenses();
      final budgets = await database.getAllBudgets();

      for (final expense in expenses) {
        await database.deleteExpense(expense.id);
      }

      for (final budget in budgets) {
        await database.deleteBudget(budget.id);
      }

      // Yedeklemeden verileri geri yükle
      final expensesData = backup['expenses'] as List<dynamic>;
      for (final expenseData in expensesData) {
        final expense = ExpensesCompanion(
          title: drift.Value(expenseData['title'] as String),
          amount: drift.Value(expenseData['amount'] as double),
          category: drift.Value(expenseData['category'] as String),
          date: drift.Value(DateTime.parse(expenseData['date'] as String)),
        );
        await database.insertExpense(expense);
      }

      final budgetsData = backup['budgets'] as List<dynamic>;
      for (final budgetData in budgetsData) {
        final budget = BudgetsCompanion(
          name: drift.Value(budgetData['name'] as String),
          amount: drift.Value(budgetData['amount'] as double),
          category: drift.Value(budgetData['category'] as String?),
          month: drift.Value(budgetData['month'] as int),
          year: drift.Value(budgetData['year'] as int),
          isActive: drift.Value(budgetData['isActive'] as bool),
          createdAt: drift.Value(DateTime.parse(budgetData['createdAt'] as String)),
        );
        await database.insertBudget(budget);
      }

      // Ayarları geri yükle
      final settings = backup['settings'] as Map<String, dynamic>;
      if (settings['currency'] != null) {
        await prefs.setString('currency', settings['currency']);
      }
      if (settings['default_category'] != null) {
        await prefs.setString('default_category', settings['default_category']);
      }
      if (settings['default_alarm_time'] != null) {
        await prefs.setString('default_alarm_time', settings['default_alarm_time']);
      }
      if (settings['theme_mode'] != null) {
        await prefs.setString('theme_mode', settings['theme_mode']);
      }
      if (settings['language'] != null) {
        await prefs.setString('language', settings['language']);
      }
      if (settings['alarms'] != null) {
        await prefs.setStringList('alarms', List<String>.from(settings['alarms']));
      }
    } catch (e) {
      throw Exception('Yedekleme geri yüklenemedi: $e');
    }
  }

  // Yedekleme geçmişini al
  Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!backupDir.existsSync()) {
        return [];
      }

      final files = backupDir.listSync().whereType<File>().toList();
      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final backup = json.decode(jsonString) as Map<String, dynamic>;
            
            backups.add({
              'path': file.path,
              'name': file.path.split('/').last,
              'created_at': backup['created_at'],
              'expense_count': (backup['expenses'] as List).length,
              'budget_count': (backup['budgets'] as List).length,
              'size': await file.length(),
            });
          } catch (e) {
            // Bozuk dosyaları atla
            continue;
          }
        }
      }

      // Tarihe göre sırala (en yeni önce)
      backups.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      
      return backups;
    } catch (e) {
      return [];
    }
  }

  // Yedekleme dosyasını sil
  Future<void> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Yedekleme dosyası silinemedi: $e');
    }
  }
} 