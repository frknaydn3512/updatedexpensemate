import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
//import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Expenses, Budgets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Bütçe tablosunu ekle
        await m.createTable(budgets);
      }
      if (from < 3) {
        // Para birimi alanlarını ekle
        await m.addColumn(expenses, expenses.currency);
        await m.addColumn(budgets, budgets.currency);
      }
    },
  );

  // Veritabanı işlemleri
Future<List<Expense>> getExpensesByMonth(int month, int year, [String? category]) {
  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 1);

  final query = select(expenses)..where((e) => e.date.isBetweenValues(start, end));

  if (category != null) {
    query.where((e) => e.category.equals(category));
  }

  return query.get();
}

  // Tüm harcamaları döndüren fonksiyon
  Future<List<Expense>> getAllExpenses() {
    return select(expenses).get();
  }

  Future insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future deleteExpense(int id) =>
      (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();

  Future updateExpense(Expense expense) => 
      update(expenses).replace(expense);

  // Bütçe işlemleri
  Future<List<Budget>> getBudgetsByMonth(int month, int year) {
    return (select(budgets)
          ..where((b) => b.month.equals(month) & b.year.equals(year) & b.isActive.equals(true)))
        .get();
  }

  Future<List<Budget>> getAllBudgets() {
    return select(budgets).get();
  }

  Future insertBudget(BudgetsCompanion budget) =>
      into(budgets).insert(budget);

  Future deleteBudget(int id) =>
      (delete(budgets)..where((tbl) => tbl.id.equals(id))).go();

  Future updateBudget(Budget budget) =>
      update(budgets).replace(budget);

  // Bütçe kullanımını hesapla
  Future<Map<String, double>> getBudgetUsage(int month, int year) async {
    final budgets = await getBudgetsByMonth(month, year);
    final expenses = await getExpensesByMonth(month, year);
    
    final usage = <String, double>{};
    
    // Genel bütçe kullanımı
    final generalBudget = budgets.where((b) => b.category == null).firstOrNull;
    if (generalBudget != null) {
      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      usage['general'] = (totalExpenses / generalBudget.amount) * 100;
    }
    
    // Kategori bütçesi kullanımı
    for (final budget in budgets.where((b) => b.category != null)) {
      final categoryExpenses = expenses.where((e) => e.category == budget.category);
      final categoryTotal = categoryExpenses.fold<double>(0, (sum, e) => sum + e.amount);
      usage[budget.category!] = (categoryTotal / budget.amount) * 100;
    }
    
    return usage;
  }

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expensemate.sqlite'));
    return NativeDatabase(file);
  });
}
