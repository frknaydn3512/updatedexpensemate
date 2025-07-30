import 'package:drift/drift.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 50)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()();
  TextColumn get currency => text().withDefault(const Constant('TRY'))(); // Para birimi alanı
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get amount => real()();
  TextColumn get category => text().nullable()(); // null ise genel bütçe, değilse kategori bütçesi
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get currency => text().withDefault(const Constant('TRY'))(); // Para birimi alanı
} 