import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import '../data/database/app_database.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_providers.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'managements/budget_management_page.dart';
import 'managements/backup_management_page.dart';
import 'package:file_selector/file_selector.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _currency = '₺';
  String _defaultCategory = '';
  TimeOfDay? _defaultAlarmTime;
  bool _isLoading = true;
  final List<String> _currencies = ['₺', '\$', '€', '£'];
  final List<String> categories = [
    'Gıda',
    'Ulaşım',
    'Kira',
    'Eğlence',
    'Sağlık',
    'Fatura',
    'Alışveriş',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currency = prefs.getString('currency') ?? '₺';
      final savedCategory = prefs.getString('default_category');
      _defaultCategory = savedCategory != null && categories.contains(savedCategory) 
          ? savedCategory 
          : categories.first;
      final alarmStr = prefs.getString('default_alarm_time');
      if (alarmStr != null) {
        final parts = alarmStr.split(':');
        if (parts.length == 2) {
          _defaultAlarmTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _saveCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
    setState(() => _currency = value);
  }

  Future<void> _saveDefaultCategory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_category', value);
    setState(() => _defaultCategory = value);
  }

  Future<void> _saveDefaultAlarmTime(TimeOfDay value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_alarm_time', '${value.hour}:${value.minute}');
    setState(() => _defaultAlarmTime = value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.language, style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<Locale>(
                  value: languageProvider.locale ?? const Locale('tr'),
                  items: const [
                    DropdownMenuItem(child: Text('Türkçe'), value: Locale('tr')),
                    DropdownMenuItem(child: Text('English'), value: Locale('en')),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      languageProvider.setLocale(locale);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              localizations.themeSelect,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          RadioListTile<ThemeModeOption>(
            title: Text(localizations.systemDefault),
            value: ThemeModeOption.system,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeModeOption? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeModeOption>(
            title: Text(localizations.lightTheme),
            value: ThemeModeOption.light,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeModeOption? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          RadioListTile<ThemeModeOption>(
            title: Text(localizations.darkTheme),
            value: ThemeModeOption.dark,
            groupValue: themeProvider.themeMode,
            onChanged: (ThemeModeOption? value) {
              if (value != null) {
                themeProvider.setThemeMode(value);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.currency, style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                  value: _currency,
                  items: _currencies.toSet().map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(c)
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) _saveCurrency(val);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.defaultCategory, style: Theme.of(context).textTheme.titleMedium),
                DropdownButton<String>(
                  value: _defaultCategory,
                  items: categories.toSet().map((c) => DropdownMenuItem(
                    value: c, 
                    child: Text(c)
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) _saveDefaultCategory(val);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(localizations.defaultAlarmTime, style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _defaultAlarmTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      _saveDefaultAlarmTime(time);
                    }
                  },
                  child: Text(_defaultAlarmTime?.format(context) ?? 'Seç'),
                ),
              ],
            ),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: Text(localizations.budgetManagement),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetManagementPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(localizations.backupManagement),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupManagementPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: Text(localizations.exportCSV),
            onTap: () => _exportToCSV(),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(localizations.exportPDF),
            onTap: () => _exportToPDF(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(localizations.pinChange),
            onTap: () => _showPinDialog(),
          ),
        ],
      ),
    );
}

  Future<void> _exportToCSV() async {
  try {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final expenses = await database.getAllExpenses();

      final csvData = [
        ['Başlık', 'Tutar', 'Kategori', 'Tarih'],
      ...expenses.map((e) => [
        e.title,
          e.amount.toString(),
        e.category,
        e.date.toIso8601String(),
      ]),
    ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);
      
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV dosyası kaydedildi: ${file.path}')),
      );
    }
  } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV dışa aktarma hatası: $e')),
      );
    }
  }
}

  Future<void> _exportToPDF() async {
  try {
    final database = Provider.of<AppDatabase>(context, listen: false);
    final expenses = await database.getAllExpenses();

    final pdf = pw.Document();
      final tableHeaders = ['Başlık', 'Tutar', 'Kategori', 'Tarih'];
      final tableData = expenses.map((e) => [
        e.title,
        e.amount.toString(),
        e.category,
        e.date.toIso8601String(),
      ]).toList();
      
    pdf.addPage(
      pw.Page(
          build: (context) => pw.Column(
            children: [
              pw.Text('Harcama Raporu', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: tableHeaders,
                data: tableData,
              ),
            ],
          ),
        ),
      );
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF dosyası kaydedildi: ${file.path}')),
      );
    }
  } catch (e) {
      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF dışa aktarma hatası: $e')),
      );
    }
  }
}

  void _showPinDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.pinChange),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              decoration: InputDecoration(labelText: localizations.pinOld),
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
            const SizedBox(height: 16),
          TextField(
              decoration: InputDecoration(labelText: localizations.pinNew),
            obscureText: true,
            keyboardType: TextInputType.number,
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
        ),
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.pinChanged)),
              );
            },
            child: Text(localizations.change),
          ),
        ],
      ),
    );
  }
}