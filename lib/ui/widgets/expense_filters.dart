import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/database/app_database.dart';

class ExpenseFilters extends StatelessWidget {
  final String? selectedCategory;
  final int? selectedDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final Set<String> selectedCategories;
  final String searchQuery;
  final List<Map<String, dynamic>> categories;
  final Function(String?) onCategoryChanged;
  final Function(int?) onDayChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(double?) onMinAmountChanged;
  final Function(double?) onMaxAmountChanged;
  final Function(Set<String>) onSelectedCategoriesChanged;
  final Function(String) onSearchQueryChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onShowAdvancedFilters;

  const ExpenseFilters({
    super.key,
    this.selectedCategory,
    this.selectedDay,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    required this.selectedCategories,
    required this.searchQuery,
    required this.categories,
    required this.onCategoryChanged,
    required this.onDayChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onMinAmountChanged,
    required this.onMaxAmountChanged,
    required this.onSelectedCategoriesChanged,
    required this.onSearchQueryChanged,
    required this.onClearFilters,
    required this.onShowAdvancedFilters,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final hasActiveFilters = selectedCategory != null || 
                           selectedDay != null || 
                           startDate != null || 
                           endDate != null || 
                           minAmount != null || 
                           maxAmount != null || 
                           selectedCategories.isNotEmpty || 
                           searchQuery.isNotEmpty;

    return Column(
      children: [
        // Kategori dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  icon: const SizedBox.shrink(),
                  isExpanded: true,
                  hint: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 8),
                      Text(localizations.category),
                    ],
                  ),
                  value: selectedCategory,
                  onChanged: onCategoryChanged,
                  items: [
                    DropdownMenuItem(value: null, child: Center(child: Text(localizations.category))),
                    ...categories
                        .map((cat) => cat['name'])
                        .toSet()
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(categories.firstWhere((c) => c['name'] == cat)['icon'], size: 18),
                                    const SizedBox(width: 6),
                                    Text(cat),
                                  ],
                                ),
                              ),
                            )),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Aktif filtreler
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    if (selectedCategory != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            localizations.categoryFilter(selectedCategory!),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: const Color(0xFF6366F1),
                          deleteIcon: const Icon(Icons.close, color: Colors.white, size: 16),
                          onDeleted: () => onCategoryChanged(null),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    if (selectedDay != null)
                      Chip(
                        label: Text('Gün: $selectedDay'),
                        onDeleted: () => onDayChanged(null),
                      ),
                    if (startDate != null)
                      Chip(
                        label: Text('Başlangıç: ${startDate!.toString().split(' ')[0]}'),
                        onDeleted: () => onStartDateChanged(null),
                      ),
                    if (endDate != null)
                      Chip(
                        label: Text('Bitiş: ${endDate!.toString().split(' ')[0]}'),
                        onDeleted: () => onEndDateChanged(null),
                      ),
                    if (minAmount != null)
                      Chip(
                        label: Text('Min: ${minAmount!.toStringAsFixed(2)}'),
                        onDeleted: () => onMinAmountChanged(null),
                      ),
                    if (maxAmount != null)
                      Chip(
                        label: Text('Max: ${maxAmount!.toStringAsFixed(2)}'),
                        onDeleted: () => onMaxAmountChanged(null),
                      ),
                    if (selectedCategories.isNotEmpty)
                      Chip(
                        label: Text(localizations.categoriesFilter(selectedCategories.length)),
                        onDeleted: () => onSelectedCategoriesChanged({}),
                      ),
                    if (searchQuery.isNotEmpty)
                      Chip(
                        label: Text(localizations.searchFilter(searchQuery)),
                        onDeleted: () => onSearchQueryChanged(''),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear),
                  label: Text(localizations.clearAllFilters),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade400, 
                    foregroundColor: Colors.black
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AdvancedFiltersDialog extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final Set<String> selectedCategories;
  final String searchQuery;
  final List<Map<String, dynamic>> categories;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(double?) onMinAmountChanged;
  final Function(double?) onMaxAmountChanged;
  final Function(Set<String>) onSelectedCategoriesChanged;
  final Function(String) onSearchQueryChanged;

  const AdvancedFiltersDialog({
    super.key,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    required this.selectedCategories,
    required this.searchQuery,
    required this.categories,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onMinAmountChanged,
    required this.onMaxAmountChanged,
    required this.onSelectedCategoriesChanged,
    required this.onSearchQueryChanged,
  });

  @override
  State<AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<AdvancedFiltersDialog> {
  late DateTime? startDate;
  late DateTime? endDate;
  late double? minAmount;
  late double? maxAmount;
  late Set<String> selectedCategories;
  late String searchQuery;

  @override
  void initState() {
    super.initState();
    startDate = widget.startDate;
    endDate = widget.endDate;
    minAmount = widget.minAmount;
    maxAmount = widget.maxAmount;
    selectedCategories = Set.from(widget.selectedCategories);
    searchQuery = widget.searchQuery;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return StatefulBuilder(
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
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setDialogState(() => searchQuery = value),
              ),
              const SizedBox(height: 16),

              // Tarih aralığı
              Text(localizations.dateRange, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text(localizations.amountRange, style: const TextStyle(fontWeight: FontWeight.bold)),
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
              Text(localizations.categories, style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: widget.categories.map((cat) {
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onStartDateChanged(startDate);
              widget.onEndDateChanged(endDate);
              widget.onMinAmountChanged(minAmount);
              widget.onMaxAmountChanged(maxAmount);
              widget.onSelectedCategoriesChanged(selectedCategories);
              widget.onSearchQueryChanged(searchQuery);
              Navigator.of(context).pop();
            },
            child: Text(localizations.applyFilters),
          ),
        ],
      ),
    );
  }
} 