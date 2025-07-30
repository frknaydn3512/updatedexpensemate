import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/database/app_database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/currency_service.dart';


class ExpensePieChart extends StatelessWidget {
  final List<Expense> expenses;
  final String currency;
  final void Function(String category)? onCategoryTap;

  const ExpensePieChart({super.key, required this.expenses, required this.currency, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, double>{};

    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final colors = _generateColors(categoryTotals.length);
    final sections = <PieChartSectionData>[];
    final legendItems = <Widget>[];
    int index = 0;
    final categoryList = categoryTotals.keys.toList();

    categoryTotals.forEach((category, total) {
      final color = colors[index];

      sections.add(
        PieChartSectionData(
          value: total,
          color: color,
          title: "",
          radius: 60,
        ),
      );

      legendItems.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, color: color),
            const SizedBox(width: 6),
            Text(
              "$category: ${CurrencyService.formatAmount(CurrencyService.convertAmount(total, currency), currency)}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );

      index++;
    });

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent && response != null && response.touchedSection != null && onCategoryTap != null) {
                    final idx = response.touchedSection!.touchedSectionIndex;
                    if (idx >= 0 && idx < categoryList.length) {
                      onCategoryTap!(categoryList[idx]);
                    }
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: legendItems,
        ),
      ],
    );
  }

  List<Color> _generateColors(int count) {
    const baseColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.yellow,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
    ];

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      colors.add(baseColors[i % baseColors.length]);
    }
    return colors;
  }
}

class ExpenseBarChart extends StatelessWidget {
  final List<Expense> expenses;
  final String currency;
  final void Function(int day)? onDayTap;

  const ExpenseBarChart({super.key, required this.expenses, required this.currency, this.onDayTap});

  @override
  Widget build(BuildContext context) {
    final dailyTotals = <int, double>{};

    for (final e in expenses) {
      final day = e.date.day;
      dailyTotals.update(day, (value) => value + e.amount,
          ifAbsent: () => e.amount);
    }

    // Maksimum Y değeri, en yüksek harcamaya göre ayarlanır.
    // Etiketlerin daha iyi görünmesi için biraz boşluk ekliyoruz.
    final maxY = (dailyTotals.values.isEmpty)
        ? 100.0 // Harcama yoksa varsayılan bir değer
        : (dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2); // En yüksekten %20 daha fazla

    final dayList = dailyTotals.keys.toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (event, response) {
              if (event is FlTapUpEvent && response != null && response.spot != null && onDayTap != null) {
                final idx = response.spot!.touchedBarGroupIndex;
                if (idx >= 0 && idx < dayList.length) {
                  onDayTap!(dayList[idx]);
                }
              }
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // Etiketler için ayrılan alanı artırdık
                interval: (maxY / 4).ceilToDouble(), // Dört ana etiket gösterecek şekilde aralık belirledik
                getTitlesWidget: (value, meta) {
                  // Etiketlerin nasıl gösterileceğini burada özelleştiriyoruz
                  String text;
                  if (value == 0) {
                    text = '0';
                  } else if (value >= 1000) {
                    text = '${(value / 1000).toStringAsFixed(1)}K'; // Binlik ifadeleri "K" ile göster
                  } else {
                    text = value.toInt().toString(); // Diğer tam sayı değerleri
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 4, // Etiket ile eksen arasındaki boşluk
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white, // Etiket rengi beyaz
                        fontWeight: FontWeight.bold,
                        fontSize: 10, // Font boyutunu küçülttük
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  "${value.toInt()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10, // Alt eksen etiketlerini de biraz küçülttük
                  ),
                ),
                reservedSize: 22,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // Dikey çizgileri kapatıyoruz, yatay çizgiler kalsın
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Color(0xffececec), // Grid çizgisi rengi
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: dayList.map((day) {
            final total = dailyTotals[day]!;
            return BarChartGroupData(
              x: day,
              barRods: [
                BarChartRodData(
                  toY: total,
                  color: const Color(0xFF6366F1),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;
  final bool showPieChart;
  final String currency;
  final Function(String) onCategoryTap;
  final Function(int) onDayTap;

  const ExpenseChart({
    super.key,
    required this.expenses,
    required this.showPieChart,
    required this.currency,
    required this.onCategoryTap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final totalAmount = _getTotalAmount(expenses);
    final categoryTotals = _getCategoryTotals(expenses);
    final dayTotals = _getDayTotals(expenses);
    
    final mostSpentCategory = _getMostSpentCategory(categoryTotals);
    final mostExpensiveDay = _getMostExpensiveDay(dayTotals);

    return Column(
      children: [
        // Analiz kartları
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _AnalysisCard(
                      title: localizations.total,
                      value: CurrencyService.formatAmount(CurrencyService.convertAmount(totalAmount, currency), currency),
                      icon: Icons.summarize,
                      color: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFFDBEAFE),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 100,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _AnalysisCard(
                      title: localizations.mostSpentCategory,
                      value: mostSpentCategory != null 
                          ? '$mostSpentCategory\n${CurrencyService.formatAmount(CurrencyService.convertAmount(categoryTotals[mostSpentCategory]!, currency), currency)}' 
                          : '-',
                      icon: Icons.category,
                      color: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFFFEF3C7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 100,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _AnalysisCard(
                      title: localizations.mostExpensiveDay,
                      value: mostExpensiveDay != null 
                          ? '$mostExpensiveDay\n${CurrencyService.formatAmount(CurrencyService.convertAmount(dayTotals[mostExpensiveDay]!, currency), currency)}' 
                          : '-',
                      icon: Icons.calendar_today,
                      color: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFFFEE2E2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Grafik
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Center(
              child: showPieChart
                  ? ExpensePieChart(
                      expenses: expenses,
                      currency: currency,
                      onCategoryTap: onCategoryTap,
                    )
                  : ExpenseBarChart(
                      expenses: expenses,
                      currency: currency,
                      onDayTap: onDayTap,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  double _getTotalAmount(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> _getCategoryTotals(List<Expense> expenses) {
    final categoryTotals = <String, double>{};
    for (var e in expenses) {
      categoryTotals.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return categoryTotals;
  }

  Map<int, double> _getDayTotals(List<Expense> expenses) {
    final dayTotals = <int, double>{};
    for (var e in expenses) {
      dayTotals.update(e.date.day, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return dayTotals;
  }

  String? _getMostSpentCategory(Map<String, double> categoryTotals) {
    if (categoryTotals.isEmpty) return null;
    final entry = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entry.key;
  }

  int? _getMostExpensiveDay(Map<int, double> dayTotals) {
    if (dayTotals.isEmpty) return null;
    final entry = dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return entry.key;
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _AnalysisCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor.withOpacity(0.9),
            backgroundColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 