import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../data/database/app_database.dart';
import '../../services/notification_service.dart';
import '../little_things/pin_lock_screen.dart';

class ExpenseForm extends StatefulWidget {
  final Expense? expense; // null ise yeni harcama, değilse düzenleme
  final List<Map<String, dynamic>> categories;
  final String currency;
  final TimeOfDay? defaultAlarmTime;
  final String defaultCategory;
  final VoidCallback? onExpenseSaved;

  const ExpenseForm({
    super.key,
    this.expense,
    required this.categories,
    required this.currency,
    this.defaultAlarmTime,
    required this.defaultCategory,
    this.onExpenseSaved,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  late String selectedCategory;
  late DateTime selectedDate;
  TimeOfDay? selectedAlarmTime;
  Map<String, dynamic>? pendingAlarmRequest;
  String selectedCurrency = '₺';
  final List<String> availableCurrencies = ['₺', '\$', '€', '£'];
  String _pinCode = '';

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.expense?.title ?? '');
    amountController = TextEditingController(text: widget.expense?.amount.toString() ?? '');
    selectedCategory = widget.expense?.category ?? widget.defaultCategory;
    selectedDate = widget.expense?.date ?? DateTime.now();
    selectedAlarmTime = widget.defaultAlarmTime;
    selectedCurrency = widget.currency;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _addPinDigit(String digit) {
    if (_pinCode.length < 4) {
      setState(() {
        _pinCode += digit;
      });
    }
  }

  void _removePinDigit() {
    if (_pinCode.isNotEmpty) {
      setState(() {
        _pinCode = _pinCode.substring(0, _pinCode.length - 1);
      });
    }
  }

    Widget _buildNumberButton(StateSetter setModalState, String number) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 2,
          minimumSize: const Size(35, 35),
          fixedSize: const Size(35, 35),
        ),
        onPressed: () {
          setModalState(() {
            _pinCode += number;
            amountController.text = _pinCode;
          });
        },
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

    Widget _buildBackspaceButton(StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 2,
          minimumSize: const Size(35, 35),
          fixedSize: const Size(35, 35),
        ),
        onPressed: () {
          if (_pinCode.isNotEmpty) {
            setModalState(() {
              _pinCode = _pinCode.substring(0, _pinCode.length - 1);
              amountController.text = _pinCode;
            });
          }
        },
        child: const Icon(Icons.backspace_outlined, size: 18),
      ),
    );
  }



  void _showForm() {
    final localizations = AppLocalizations.of(context)!;
    
    if (!mounted) return; // Eğer widget dispose edilmişse çık
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
                         child: StatefulBuilder(
               builder: (context, setModalState) {
                 String pinCode = _pinCode;
                 return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                                     TextField(
                     controller: titleController,
                     decoration: InputDecoration(
                       labelText: localizations.title,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                   ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.categories.map((cat) {
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat['icon'], color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(cat['name'], style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          selected: selectedCategory == cat['name'],
                          selectedColor: cat['color'],
                          backgroundColor: cat['color'].withOpacity(0.5),
                          onSelected: (_) {
                            setModalState(() {
                              selectedCategory = cat['name'];
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                                     // Tutar girişi artık numpad ile yapılacak
                   // TextField gizlendi
                                     const SizedBox(height: 10),
                                                                               // Tutar Girişi
                           Column(
                             children: [
                               // Tutar göstergesi
                               Container(
                                 width: double.infinity,
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.white,
                                   borderRadius: BorderRadius.circular(8),
                                   border: Border.all(color: Colors.grey.shade300),
                                 ),
                                 child: Center(
                                   child: Text(
                                     pinCode.isEmpty ? '0.00' : pinCode,
                                     style: const TextStyle(
                                       fontSize: 24,
                                       fontWeight: FontWeight.bold,
                                       color: Colors.black87,
                                     ),
                                   ),
                                 ),
                               ),
                               const SizedBox(height: 16),
                               // Mini Numpad
                               Center(
                                 child: Container(
                                   width: 160,
                                   child: GridView.count(
                                     shrinkWrap: true,
                                     physics: const NeverScrollableScrollPhysics(),
                                     crossAxisCount: 3,
                                     childAspectRatio: 1.0,
                                     mainAxisSpacing: 6,
                                     crossAxisSpacing: 6,
                                     children: [
                                       // 1. Satır
                                       _buildNumberButton(setModalState, '1'),
                                       _buildNumberButton(setModalState, '2'),
                                       _buildNumberButton(setModalState, '3'),
                                       // 2. Satır
                                       _buildNumberButton(setModalState, '4'),
                                       _buildNumberButton(setModalState, '5'),
                                       _buildNumberButton(setModalState, '6'),
                                       // 3. Satır
                                       _buildNumberButton(setModalState, '7'),
                                       _buildNumberButton(setModalState, '8'),
                                       _buildNumberButton(setModalState, '9'),
                                       // 4. Satır: boş, 0, backspace
                                       const SizedBox(),
                                       _buildNumberButton(setModalState, '0'),
                                       _buildBackspaceButton(setModalState),
                                     ],
                                   ),
                                 ),
                               ),
                             ],
                           ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${localizations.date}: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                      TextButton(
                        child: Text(localizations.dateSelect),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                                     Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       IconButton(
                         icon: const Icon(Icons.alarm),
                         tooltip: 'Bu harcama için alarm kur',
                         onPressed: () {
                           // Title ve amount kontrolü
                           if (titleController.text.isEmpty || amountController.text.isEmpty || amountController.text == '0.00') {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Önce başlık ve tutar giriniz!'),
                                 backgroundColor: Colors.red,
                               ),
                             );
                             return;
                           }
                           _showAlarmDialog(setModalState);
                         },
                       ),
                       if (selectedAlarmTime != null)
                         Text('Alarm: ${selectedAlarmTime!.format(context)}'),
                     ],
                   ),
                                     ElevatedButton(
                     onPressed: () => _saveExpense(),
                     child: Text(widget.expense == null ? localizations.save : localizations.update),
                   ),
                 ],
               );
             },
           ),
          ),
        ),
      ),
    );
  }

  void _showAlarmDialog(StateSetter setModalState) async {
    String? selectedRepeat = 'monthly';
    List<int> selectedWeekdays = [];
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tekrar Aralığı Seç'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Tek Seferlik'),
                    value: 'once',
                    groupValue: selectedRepeat,
                    onChanged: (v) => setDialogState(() => selectedRepeat = v),
                  ),
                  RadioListTile<String>(
                    title: const Text('Her Gün'),
                    value: 'daily',
                    groupValue: selectedRepeat,
                    onChanged: (v) => setDialogState(() => selectedRepeat = v),
                  ),
                  RadioListTile<String>(
                    title: const Text('Her Hafta (gün seç)'),
                    value: 'weekly',
                    groupValue: selectedRepeat,
                    onChanged: (v) => setDialogState(() => selectedRepeat = v),
                  ),
                  if (selectedRepeat == 'weekly')
                    Wrap(
                      children: List.generate(7, (i) {
                        final weekdayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                        return FilterChip(
                          label: Text(weekdayNames[i]),
                          selected: selectedWeekdays.contains(i + 1),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                selectedWeekdays.add(i + 1);
                              } else {
                                selectedWeekdays.remove(i + 1);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  RadioListTile<String>(
                    title: const Text('Her Ay'),
                    value: 'monthly',
                    groupValue: selectedRepeat,
                    onChanged: (v) => setDialogState(() => selectedRepeat = v),
                  ),
                  RadioListTile<String>(
                    title: const Text('Her Yıl'),
                    value: 'yearly',
                    groupValue: selectedRepeat,
                    onChanged: (v) => setDialogState(() => selectedRepeat = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(selectedRepeat),
                  child: const Text('Devam'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (selectedRepeat == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedAlarmTime ?? TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    pendingAlarmRequest = {
      'repeat': selectedRepeat,
      'weekdays': List<int>.from(selectedWeekdays),
      'date': selectedDate,
      'time': pickedTime,
    };

         // Alarm banner'ını kaldır, sadece alarmı kaydet
     // _scheduleAlarm(selectedRepeat!, selectedWeekdays, selectedDate, pickedTime);
  }

     void _scheduleAlarm(String repeat, List<int> weekdays, DateTime date, TimeOfDay time) async {
     final notifIdBase = DateTime.now().millisecondsSinceEpoch % 1000000;
     final title = titleController.text;
     final amount = amountController.text;
     final notifTitle = '$title alarmı';
     final notifBody = '$amount${widget.currency} $title ödemesi';
    
    if (repeat == 'once') {
      final notifDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      await NotificationService().scheduleOneTimeNotification(
        id: notifIdBase,
        title: notifTitle,
        body: notifBody,
        dateTime: notifDate,
      );
    } else if (repeat == 'daily') {
      await NotificationService().scheduleDailyNotification(
        id: notifIdBase,
        title: notifTitle,
        body: notifBody,
        time: time,
      );
    } else if (repeat == 'weekly') {
      for (final weekday in weekdays) {
        final alarmId = notifIdBase + weekday;
        await NotificationService().scheduleWeeklyNotification(
          id: alarmId,
          title: notifTitle,
          body: notifBody,
          weekday: weekday,
          time: time,
        );
      }
    } else if (repeat == 'monthly') {
      await NotificationService().scheduleMonthlyNotification(
        id: notifIdBase,
        title: notifTitle,
        body: notifBody,
        date: date,
        time: time,
      );
    } else if (repeat == 'yearly') {
      await NotificationService().scheduleYearlyNotification(
        id: notifIdBase,
        title: notifTitle,
        body: notifBody,
        date: date,
        time: time,
      );
    }

    _showAlarmSummary(repeat, weekdays, date, time);
  }

     void _showAlarmSummary(String repeat, List<int> weekdays, DateTime date, TimeOfDay time) {
     String summary = '';
     String timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
     
     if (repeat == 'once') {
       summary = '${date.toLocal().toString().split(' ')[0]} tarihinde saat $timeStr\'da hatırlatılacak';
     } else if (repeat == 'daily') {
       summary = 'Her gün saat $timeStr\'da hatırlatılacak';
     } else if (repeat == 'weekly') {
       final weekdayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
       final selectedNames = weekdays.map((i) => weekdayNames[(i-1)%7]).join(' ve ');
       summary = '$selectedNames günleri saat $timeStr\'da hatırlatılacak';
     } else if (repeat == 'monthly') {
       summary = 'Her ayın ${date.day}. günü saat $timeStr\'da hatırlatılacak';
     } else if (repeat == 'yearly') {
       summary = 'Her yıl ${date.day}.${date.month} günü saat $timeStr\'da hatırlatılacak';
     }

     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           backgroundColor: Colors.blue.shade600,
           content: Row(
             children: [
               const Icon(Icons.alarm, color: Colors.white),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   summary,
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                 ),
               ),
             ],
           ),
           duration: const Duration(seconds: 3),
           behavior: SnackBarBehavior.floating,
         ),
       );
     }
   }

  Future<void> _saveExpense() async {
    final localizations = AppLocalizations.of(context)!;
    final title = titleController.text;
    final amount = double.tryParse(amountController.text) ?? 0.0;
    final category = selectedCategory;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.fillAllFields)),
      );
      return;
    }

    final database = Provider.of<AppDatabase>(context, listen: false);

    if (widget.expense == null) {
      // Yeni harcama ekle
      final newExpense = ExpensesCompanion(
        title: Value(title),
        amount: Value(amount),
        category: Value(category),
        date: Value(selectedDate),
      );

      final insertedId = await database.insertExpense(newExpense);

      // Alarm isteği varsa bildirimi harcama ID'siyle planla
      if (pendingAlarmRequest != null) {
                 final repeat = pendingAlarmRequest!['repeat'] as String;
         final weekdays = pendingAlarmRequest!['weekdays'] as List<int>;
         final alarmDate = pendingAlarmRequest!['date'] as DateTime;
         final alarmTime = pendingAlarmRequest!['time'] as TimeOfDay;
         final notifTitle = '$title alarmı';
         final notifBody = '$amount${widget.currency} $title ödemesi';
         final payload = insertedId.toString();
        final notifIdBase = DateTime.now().millisecondsSinceEpoch % 1000000;
        
                 if (repeat == 'once') {
           final notifDate = tz.TZDateTime(
             tz.local,
             alarmDate.year,
             alarmDate.month,
             alarmDate.day,
             alarmTime.hour,
             alarmTime.minute,
           );
           await NotificationService().scheduleOneTimeNotification(
             id: notifIdBase,
             title: notifTitle,
             body: notifBody,
             dateTime: notifDate,
             payload: payload,
           );
         } else if (repeat == 'daily') {
           await NotificationService().scheduleDailyNotification(
             id: notifIdBase,
             title: notifTitle,
             body: notifBody,
             time: alarmTime,
             payload: payload,
           );
         } else if (repeat == 'weekly') {
           for (final weekday in weekdays) {
             final alarmId = notifIdBase + weekday;
             await NotificationService().scheduleWeeklyNotification(
               id: alarmId,
               title: notifTitle,
               body: notifBody,
               weekday: weekday,
               time: alarmTime,
               payload: payload,
             );
           }
         } else if (repeat == 'monthly') {
           await NotificationService().scheduleMonthlyNotification(
             id: notifIdBase,
             title: notifTitle,
             body: notifBody,
             date: alarmDate,
             time: alarmTime,
             payload: payload,
           );
         } else if (repeat == 'yearly') {
           await NotificationService().scheduleYearlyNotification(
             id: notifIdBase,
             title: notifTitle,
             body: notifBody,
             date: alarmDate,
             time: alarmTime,
             payload: payload,
           );
         }
         
                   // Alarm'ı SharedPreferences'a da kaydet
          final prefs = await SharedPreferences.getInstance();
          final alarmList = prefs.getStringList('alarms') ?? [];
          final alarmString = "$notifIdBase:${alarmTime.hour}:${alarmTime.minute}:$title:$amount";
          if (!alarmList.contains(alarmString)) {
            alarmList.add(alarmString);
            await prefs.setStringList('alarms', alarmList);
          }
         
         // Alarm banner'ını burada göster
         final alarmRepeat = pendingAlarmRequest!['repeat'] as String;
         final alarmWeekdays = pendingAlarmRequest!['weekdays'] as List<int>;
         final alarmDateForBanner = pendingAlarmRequest!['date'] as DateTime;
         final alarmTimeForBanner = pendingAlarmRequest!['time'] as TimeOfDay;
         
         pendingAlarmRequest = null;
         
         _showAlarmSummary(alarmRepeat, alarmWeekdays, alarmDateForBanner, alarmTimeForBanner);
       }
    } else {
      // Harcama güncelle
      final updatedExpense = widget.expense!.copyWith(
        title: title,
        amount: amount,
        category: category,
        date: selectedDate,
      );

      await database.updateExpense(updatedExpense);
    }

    if (mounted) {
      await _showSuccessAnimation(context);
      Navigator.pop(context);
      // Callback ile ana sayfaya bildir
      widget.onExpenseSaved?.call();
    }
  }

  Future<void> _showSuccessAnimation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: SizedBox(
          width: 360,
          height: 360,
          child: CircularProgressIndicator(),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (context.mounted) Navigator.of(context).pop();
  }

  bool _formShown = false;

  @override
  Widget build(BuildContext context) {
    // Direkt form açılsın
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_formShown) {
        _formShown = true;
        _showForm();
      }
    });
    
    return const SizedBox.shrink(); // Boş widget döndür
  }
} 