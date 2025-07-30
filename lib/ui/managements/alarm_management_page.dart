import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expensemate2/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmManagementPage extends StatefulWidget {
  const AlarmManagementPage({super.key});

  @override
  State<AlarmManagementPage> createState() => _AlarmManagementPageState();
}

class _AlarmManagementPageState extends State<AlarmManagementPage> {
  List<Map<String, dynamic>> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = prefs.getStringList('alarms') ?? [];
    debugPrint('Yüklenen alarmlar: $alarmList'); // Debug ekle
    setState(() {
      _alarms = alarmList.map((e) {
        final parts = e.split(':');
        if (parts.length >= 4) {
          // Yeni format: id:hour:minute:title:amount
          return {
            'id': int.parse(parts[0]),
            'hour': int.parse(parts[1]),
            'minute': int.parse(parts[2]),
            'title': parts[3],
            'amount': parts.length > 4 ? parts[4] : '',
          };
        } else {
          // Eski format: id:hour:minute
          return {
            'id': int.parse(parts[0]),
            'hour': int.parse(parts[1]),
            'minute': int.parse(parts[2]),
            'title': 'Genel Alarm',
            'amount': '',
          };
        }
      }).toList();
    });
    debugPrint('Alarm listesi: $_alarms'); // Debug ekle
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmList = _alarms.map((a) {
      final title = a['title'] ?? 'Genel Alarm';
      final amount = a['amount'] ?? '';
      return "${a['id']}:${a['hour']}:${a['minute']}:$title:$amount";
    }).toList();
    await prefs.setStringList('alarms', alarmList);
  }

  Future<void> _addAlarm() async {
    try {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked != null) {
        final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
        debugPrint('Yeni alarm ekleniyor: ID=$newId, Saat=${picked.hour}:${picked.minute}');
        
        // Test için hemen bildirim gönder
        await NotificationService().showTestNotification(
          id: newId,
          title: 'Test Alarmı',
          body: 'Bu bir test alarmıdır! Saat: ${picked.hour}:${picked.minute}',
        );
        
        // 30 saniye sonra test bildirimi
        Future.delayed(const Duration(seconds: 30), () async {
          await NotificationService().showTestNotification(
            id: newId + 500,
            title: '30 Saniye Test',
            body: '30 saniye sonra gelen test bildirimi!',
          );
        });
        
        // Gerçek zamana göre alarm planla
        await NotificationService().scheduleDailyNotification(
          id: newId + 1000, // Farklı ID kullan
          title: 'Test Alarmı',
          body: 'Bu bir test alarmıdır! Saat: ${picked.hour}:${picked.minute}',
          time: picked,
        );
        
        // Önce SharedPreferences'a kaydet
        final prefs = await SharedPreferences.getInstance();
        final alarmList = prefs.getStringList('alarms') ?? [];
        final alarmString = "$newId:${picked.hour}:${picked.minute}:Test Alarmı:Test";
        alarmList.add(alarmString);
        await prefs.setStringList('alarms', alarmList);
        
        // Sonra UI'ı güncelle
        await _loadAlarms();
        
        debugPrint('Alarm başarıyla eklendi. Toplam alarm sayısı: ${_alarms.length}');
        
        // Test bildirimi göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test alarmı eklendi! 1 dakika sonra bildirim gelecek.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Alarm eklerken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm eklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlarm(int id) async {
    await NotificationService().cancelNotification(id);
    setState(() {
      _alarms.removeWhere((a) => a['id'] == id);
    });
    await _saveAlarms();
  }

  Future<void> _editAlarm(int index) async {
    final current = _alarms[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current['hour']!, minute: current['minute']!),
    );
    if (picked != null) {
      await NotificationService().cancelNotification(current['id']!);
      final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
      await NotificationService().scheduleDailyNotification(
        id: newId,
        title: 'ExpenseMate',
        body: 'Alarm zamanı geldi!',
        time: picked,
      );
      
      // SharedPreferences'ı güncelle
      final prefs = await SharedPreferences.getInstance();
      final alarmList = prefs.getStringList('alarms') ?? [];
      final title = current['title'] ?? 'Genel Alarm';
      final amount = current['amount'] ?? '';
      final newAlarmString = "$newId:${picked.hour}:${picked.minute}:$title:$amount";
      
      // Eski alarmı kaldır, yenisini ekle
      alarmList.removeAt(index);
      alarmList.add(newAlarmString);
      await prefs.setStringList('alarms', alarmList);
      
      // UI'ı güncelle
      await _loadAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarmları Yönet')),
      body: ListView.builder(
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          final timeStr = alarm['hour'].toString().padLeft(2, '0') + ':' + alarm['minute'].toString().padLeft(2, '0');
          final title = alarm['title'] ?? 'Genel Alarm';
          final amount = alarm['amount'] ?? '';
          
          return ListTile(
            leading: const Icon(Icons.alarm),
            title: Text('$title: $timeStr'),
            subtitle: amount.isNotEmpty ? Text('$amount₺ ödemesi') : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editAlarm(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAlarm(alarm['id']!),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
        tooltip: 'Alarm Ekle',
      ),
    );
  }
} 